/*
	This demo will build out a table (clustered) with unique columns.
	Once we've inserted some sample data, we can try out the procedure.
	It should go without saying, but don't run this in production or in the master database.
	/*
		I would recommend running this in the database in which you have created the usp_DeleteDuplicates stored procedure.
	*/
*/

--Let's drop the table if it exists in case the table was previously created from demo scripts.
IF OBJECT_ID(N'dbo.DemoUniques', N'U') IS NOT NULL
	DROP TABLE dbo.DemoUniques;
GO

--We need to create the table. This will be a heap for the time being.
CREATE TABLE dbo.DemoUniques
(
	DemoUniquesID int NOT NULL IDENTITY (1, 1)
		CONSTRAINT PK_DemoUniques_DemoUniquesID PRIMARY KEY CLUSTERED,
	LastName nvarchar(32) NOT NULL,
	FirstName nvarchar(32) NOT NULL,
	ReallyUnique uniqueidentifier NOT NULL
		CONSTRAINT AK_DemoUniques_ReallyUnique UNIQUE
);
GO

--Insert initial data.
INSERT INTO dbo.DemoUniques (LastName, FirstName, ReallyUnique)
VALUES (N'Doe', N'John', NEWID()),
       (N'Doe', N'Jane', NEWID());

--Duplicate this data with a CROSS JOIN.
INSERT INTO dbo.DemoUniques (LastName, FirstName, ReallyUnique)
SELECT TOP (25) D.LastName, D.FirstName, NEWID()
FROM dbo.DemoUniques AS D
CROSS JOIN sys.objects
WHERE D.LastName = N'Doe'
	AND D.FirstName = N'John';

INSERT INTO dbo.DemoUniques (LastName, FirstName, ReallyUnique)
SELECT TOP (25) D.LastName, D.FirstName, NEWID()
FROM dbo.DemoUniques AS D
CROSS JOIN sys.objects
WHERE D.LastName = N'Doe'
	AND D.FirstName = N'Jane';

--Let's take a look at what is in the table.
SELECT LastName,
       FirstName,
	   ReallyUnique
FROM dbo.DemoUniques;

--Let's try our procedure with the @WhatIf parameter. This will fail because we have enforced uniqueness on our target table.
EXEC dbo.usp_DeleteDuplicates @ObjectName = N'dbo.DemoUniques', @WhatIf = 1;

--Let's do the same thing, but with the @WithUniques parameter.
EXEC dbo.usp_DeleteDuplicates @ObjectName = N'dbo.DemoUniques', @WithUniques = 1, @WhatIf = 1;

--That should have displayed 50 rows, as our table has a total of 52 rows, with only 2 being unique.
--These would be the rows that are removed.

--Let's try our procedure without the @WhatIf parameter, while still using the @WithUniques parameter.
EXEC dbo.usp_DeleteDuplicates @ObjectName = N'dbo.DemoUniques', @WithUniques = 1;

--Now let's look at our table.
SELECT LastName,
       FirstName,
	   ReallyUnique
FROM dbo.DemoUniques;

--Now let's drop the table we have been using, because we don't really want to keep it.
IF OBJECT_ID(N'dbo.DemoUniques', N'U') IS NOT NULL
	DROP TABLE dbo.DemoUniques;
GO