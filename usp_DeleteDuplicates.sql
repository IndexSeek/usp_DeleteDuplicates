IF OBJECT_ID(N'dbo.usp_DeleteDuplicates', N'P') IS NOT NULL
	DROP PROCEDURE dbo.usp_DeleteDuplicates;

/****** Object:  StoredProcedure [dbo].[usp_DeleteDuplicates] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================
-- Author:                   Tyler White
-- Create Date:              2019-09-11
-- Description:              Used to remove EXACT duplicate rows in a table.
-- Modification Date:        2019-09-26
-- Modification Description: Allowed for duplicates outside uniqueness
--                           to be removed. (@WithUniques parameter)
-- =========================================================================
CREATE PROCEDURE [dbo].[usp_DeleteDuplicates]
	@ObjectName nvarchar (386) = NULL,
	@Help bit = 0,
	@WhatIf bit = 0,
	@WithUniques bit = 0,
	@DatabaseName sysname = NULL,
	@SchemaName sysname = NULL,
	@TableName sysname = NULL
AS
    BEGIN

        SET NOCOUNT ON;

		IF @Help = 1 

			BEGIN

				PRINT N'
------------------------------------------------------------------------
                          usp_DeleteDuplicates
------------------------------------------------------------------------

This procedure removes EXACT duplicate values from a table. The table 
must not have any enforced unique constraints, as this makes removing 
duplicates unnecessary. If enforced unique constraint(s) exist on the
table you can remove duplicate rows using @WithUnique = 1. 
		
For instance, let''s say we have the following table:

MyDb.dbo.ExampleTable

|LastName|FirstName|
|--------|---------|
|Doe     |John     |
|Doe     |John     |
|Doe     |Jane     |
|Doe     |Jane     |

Now let''s run our procedure:

EXECUTE dbo.usp_DeleteDuplicates @DatabaseName = N''MyDb'',
				 @SchemaName = N''dbo'',
				 @TableName = N''ExampleTable'';

We are now left with:

MyDb.dbo.ExampleTable

|LastName|FirstName|
|--------|---------|
|Doe     |John     |
|Doe     |Jane     |

Minimum Requirements:
	- Requires at least SQL Server 2005. 

Parameter explanations:

@ObjectName   This requires the name of the object, allows for object
              pieces. (DatabaseName.SchemaName.TableName)
@WhatIf       0 = This is the default. This will remove the duplicates.
              1 = Hypothetically removes the duplicate rows. Does not
                  actually perform the delete, but displays the rows
                  that would be affected.
@WithUniques  0 = This is the default. This will check for enforced uniqueness.
              1 = This will remove all duplicates excluding the unique columns.
@DatabaseName Which database is this table stored in? 
              If NULL, this will use the current database context 
              from where the procedure is being called.
@SchemaName   Which schema does this database belong?
              IF NULL, this will use the default schema of the caller.
@TableName    The table in which you are attempting to remove duplicate 
              rows. This is not required if using @ObjectName.
        
MIT License

Copyright (c) 2019 B. Tyler White

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.'
;
				RETURN -1;

			END

        DECLARE @ErrorMsg nvarchar (MAX);
        DECLARE @Exists bit;
        DECLARE @Sql nvarchar (MAX);
	
	IF @ObjectName IS NULL
           AND @TableName IS NULL
            BEGIN;
                RAISERROR(N'It looks like you forgot to pass the @ObjectName or @TableName parameter.', 16, 1);
		RETURN -1;
            END;

        IF @ObjectName IS NOT NULL
            BEGIN;
                SELECT @TableName = PARSENAME(@ObjectName, 1),
                       @SchemaName = PARSENAME(@ObjectName, 2),
                       @DatabaseName = PARSENAME(@ObjectName, 3);
            END;

	IF DB_ID(@DatabaseName) IS NULL AND @DatabaseName IS NOT NULL
		BEGIN
			RAISERROR(15010, -1, -1, @DatabaseName)
			RETURN -1;
		END;

        IF @DatabaseName IS NULL
            BEGIN
                SELECT TOP (1) @DatabaseName = DB_NAME(resource_database_id)
                FROM sys.dm_tran_locks
                WHERE request_session_id = @@SPID
                      AND resource_type = 'DATABASE'
                      AND request_owner_type = 'SHARED_TRANSACTION_WORKSPACE'
                ORDER BY CASE WHEN resource_database_id = DB_ID() THEN 1 ELSE 0 END;
            END;

        IF @SchemaName IS NULL
            BEGIN
                SET @SchemaName = SCHEMA_NAME();
            END;

        IF OBJECT_ID(CONCAT(@DatabaseName, N'.', @SchemaName, N'.', @TableName), N'U') IS NULL
            BEGIN
                RAISERROR(15009, -1, -1, @ObjectName, @DatabaseName);
                RETURN -1;
            END;

		IF @WithUniques = 0

		    BEGIN

			    SET @Sql = CONCAT(N'
SELECT TOP (1) @Exists = 1
FROM ', @DatabaseName, '.sys.tables AS T
INNER JOIN ', @DatabaseName, '.sys.schemas AS S
    ON T.schema_id = S.schema_id
INNER JOIN ', @DatabaseName, '.sys.indexes AS I
    ON T.object_id = I.object_id
WHERE S.name = ', QUOTENAME(@SchemaName, ''''), '
        AND T.name = ',QUOTENAME(@TableName, ''''), '
        AND I.index_id > 0
        AND I.is_disabled = 0
        AND I.is_hypothetical = 0
        AND I.is_unique = 1'
                         );

                EXECUTE sp_executesql @Stmt = @Sql,
                                      @params = N'@Exists bit OUTPUT',
                                      @Exists = @Exists OUTPUT;

                IF @Exists = 1

                    BEGIN

                        DECLARE @Msg nvarchar (256) = CONCAT(N'The object ''', @SchemaName, N'.', @TableName, N''' has enforced uniqueness. No need to remove duplicates. 
To remove duplicate rows outside of the unique columns, use @WithUniques = 1. Be careful with that one.');
                        RAISERROR(@Msg, 16, 1);
                        RETURN -1;

                    END;

		    END;

        DECLARE @Columns nvarchar (MAX);

		IF @WithUniques = 0

			BEGIN

				SET @Sql = CONCAT(N'

SELECT @Columns = STUFF((
SELECT '', '' + C.name
FROM ', @DatabaseName, '.sys.tables AS T
INNER JOIN ', @DatabaseName, '.sys.schemas AS S
    ON T.schema_id = S.schema_id
INNER JOIN  ', @DatabaseName, '.sys.indexes AS I
    ON T.object_id = I.object_id
INNER JOIN ', @DatabaseName, '.sys.columns AS C
ON T.object_id = C.object_id
WHERE S.name = ', QUOTENAME(@SchemaName, ''''), '
    AND T.name = ', QUOTENAME(@TableName, ''''), '
ORDER BY C.column_id
FOR XML PATH('''')), 1, 2, '''');')

			END;

		IF @WithUniques = 1
			
			BEGIN;

				SET @Sql =CONCAT(N'

SELECT @Columns = STUFF(
    (
        SELECT '', '' + C.name
        FROM ', @DatabaseName, '.sys.tables AS T
        INNER JOIN ', @DatabaseName, '.sys.schemas AS S
            ON T.schema_id = S.schema_id
        INNER JOIN ', @DatabaseName, '.sys.indexes AS I
            ON T.object_id = I.object_id
        INNER JOIN ', @DatabaseName, '.sys.columns AS C
        ON T.object_id = C.object_id
        WHERE S.name = ', QUOTENAME(@SchemaName, ''''), '
            AND T.name = ', QUOTENAME(@TableName, ''''), '
            AND NOT EXISTS
        (
            SELECT C2.column_id
            FROM ', @DatabaseName, '.sys.tables AS T2
            INNER JOIN ', @DatabaseName, '.sys.schemas AS S2
                ON T2.schema_id = S2.schema_id
            INNER JOIN ', @DatabaseName, '.sys.indexes AS I2
                ON T2.object_id = I2.object_id
            INNER JOIN ', @DatabaseName, '.sys.index_columns AS IC2
                ON I2.object_id = IC2.object_id
            INNER JOIN  ', @DatabaseName, '.sys.columns AS C2
                ON I2.object_id = C2.object_id
                    AND IC2.column_id = C2.column_id
            WHERE S2.name = ', QUOTENAME(@SchemaName, ''''), '
                    AND T2.name = ', QUOTENAME(@TableName, ''''), '
                    AND I2.index_id > 0
                    AND I2.is_disabled = 0
                    AND I2.is_hypothetical = 0
                    AND I2.is_unique = 1
                    AND C.column_id = C2.column_id
        )
		GROUP BY C.column_id, C.name
        ORDER BY C.column_id
        FOR XML PATH('''')), 1, 2, '''');');

			END;

		EXECUTE sp_executesql @Stmt = @Sql,
		@params = N'@Columns nvarchar (MAX) OUTPUT',
		@Columns = @Columns OUTPUT;

		IF @WhatIf = 0

			BEGIN

				SET @Sql = CONCAT(N'

WITH CTE
AS
(
	SELECT ROW_NUMBER() OVER (PARTITION BY ' + @Columns + N' ORDER BY (SELECT NULL)) AS RowNum
	FROM ', @DatabaseName, N'.', @SchemaName,  N'.',  @TableName, N'
)
DELETE FROM CTE
WHERE RowNum > 1;');

			END

		IF @WhatIf = 1

			BEGIN

				SET @Sql = CONCAT(N'

WITH CTE
AS
(
	SELECT ', @Columns, ', ROW_NUMBER() OVER (PARTITION BY ' + @Columns + N' ORDER BY (SELECT NULL)) AS RowNum
	FROM ', @DatabaseName, N'.', @SchemaName,  N'.',  @TableName, N'
)
SELECT ', @Columns , ' FROM CTE
WHERE RowNum > 1;');

			END

        EXEC sp_executesql @Stmt = @Sql;

		DECLARE @Rows bigint;
		SELECT @Rows = @@ROWCOUNT;
		
		IF @Rows = 1
			PRINT CONCAT(CAST(@Rows AS nvarchar (19)), N' row has been removed from ''', @DatabaseName, N'.', @SchemaName,  N'.',  @TableName, N'''.')
		ELSE
			PRINT CONCAT(CAST(@Rows AS nvarchar (19)), N' rows have been removed from ''', @DatabaseName, N'.', @SchemaName,  N'.',  @TableName, N'''.')

    END;
GO
