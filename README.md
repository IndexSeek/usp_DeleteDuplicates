# usp_DeleteDuplicates
SQL Server Stored Procedure to remove duplicate rows from a table.

This procedure removes EXACT duplicate values from a table. The table 
must not have any enforced unique constraints, as this makes removing 
duplicates unnecessary. If enforced unique constraint(s) exist on the
table you can remove duplicate rows using @WithUniques = 1. I would
be really careful with @WithUniques = 1.
		
For instance, let's say we have the following table:

MyDb.dbo.ExampleTable

|LastName |FirstName|
|---------|---------|
|Doe      |John     |
|Doe      |John     |
|Doe      |Jane     |
|Doe      |Jane     |

Now let's run our procedure:

EXECUTE dbo.usp_DeleteDuplicates @DatabaseName = N'MyDb',<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;@SchemaName = N'dbo',<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;@TableName = N'ExampleTable';<br>

We are now left with:

MyDb.dbo.ExampleTable

|LastName |FirstName|
|---------|---------|
|Doe      |John     |
|Doe      |Jane     |
