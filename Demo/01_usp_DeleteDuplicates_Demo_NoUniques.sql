/*
	This demo will build out a table (heap) without any unique columns.
	Once we've inserted some sample data, we can try out the procedure.
	It should go without saying, but don't run this in production, or in the master database.
	/*
		I would recommend running this in the database in which you have created the usp_DeleteDuplicates stored procedure.
	*/
*/

--Let's drop the table if it exists in case the table was previously created from demo scripts.
IF OBJECT_ID(N'dbo.DemoNoUniques', N'U') IS NOT NULL
	DROP TABLE dbo.DemoNoUniques;
GO

--We need to create the table. This will be a heap for the time being.
CREATE TABLE dbo.DemoNoUniques
(
	LastName nvarchar(32) NOT NULL,
	FirstName nvarchar(32) NOT NULL
);
GO

--Insert initial data.
INSERT INTO dbo.DemoNoUniques (LastName, FirstName)
VALUES (N'Doe', N'John'),
       (N'Doe', N'Jane');

--Duplicate this data with a CROSS JOIN.
INSERT INTO dbo.DemoNoUniques (LastName, FirstName)
SELECT TOP (25) D.LastName, D.FirstName
FROM dbo.DemoNoUniques AS D
CROSS JOIN sys.objects
WHERE D.LastName = N'Doe'
	AND D.FirstName = N'John';

INSERT INTO dbo.DemoNoUniques (LastName, FirstName)
SELECT TOP (25) D.LastName, D.FirstName
FROM dbo.DemoNoUniques AS D
CROSS JOIN sys.objects
WHERE D.LastName = N'Doe'
	AND D.FirstName = N'Jane';

--Let's take a look at what is in the table.
SELECT LastName,
       FirstName
FROM dbo.DemoNoUniques;

--Let's try our procedure with the @WhatIf parameter.
EXEC dbo.usp_DeleteDuplicates @ObjectName = N'dbo.DemoNoUniques', @WhatIf = 1;

--This should have displayed 50 rows, as our table has a total of 52 rows, with only 2 being unique.
--These would be the rows that are removed.

--Let's try our procedure without the @WhatIf parameter.
EXEC dbo.usp_DeleteDuplicates @ObjectName = N'dbo.DemoNoUniques';

--Now let's look at our table.
SELECT LastName,
       FirstName
FROM dbo.DemoNoUniques;

--Now let's drop the table we have been using, because we don't really want to keep it.
IF OBJECT_ID(N'dbo.DemoNoUniques', N'U') IS NOT NULL
	DROP TABLE dbo.DemoNoUniques;
GO