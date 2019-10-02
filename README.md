# usp_DeleteDuplicates

SQL Server Stored Procedure to remove duplicate rows from a table.

This procedure removes EXACT duplicate values from a table. The table 
must not have any enforced unique constraints, as this makes removing 
duplicates unnecessary. If enforced unique constraint(s) exist on the
table you can remove duplicate rows using @WithUniques = 1. I would 
be really careful with @WithUniques = 1.
		
For instance, let's say we have the following table:

MyDb.dbo.ExampleTable

|LastName|FirstName|
|--------|---------|
|Doe     |John     |
|Doe     |John     |
|Doe     |Jane     |
|Doe     |Jane     |

Now let's run our procedure:

<pre>
EXECUTE dbo.usp_DeleteDuplicates @DatabaseName = N'MyDb',
				 @SchemaName = N'dbo',
				 @TableName = N'ExampleTable';
</pre>

We are now left with:

MyDb.dbo.ExampleTable

|LastName|FirstName|
|--------|---------|
|Doe     |John     |
|Doe     |Jane     |

<pre>
Parameter explanations:

@ObjectName     This requires the name of the object, allows for object
                pieces. (DatabaseName.SchemaName.TableName)
				
@WhatIf         0 = This is the default. This will remove the duplicates.
                1 = Hypothetically removes the duplicate rows. Does not
                    actually perform the delete, but displays the rows
                    that would be affected.
					
@WithUniques    0 = This is the default. This will check for enforced uniqueness.
                1 = This will remove all duplicates excluding the unique columns.
				
@DatabaseName   Which database is this table stored in? 
                If NULL, this will use the current database context 
                from where the procedure is being called.
				
@SchemaName     Which schema does this database belong?
                IF NULL, this will use the default schema of the caller.
				
@TableName      The table in which you are attempting to remove duplicate 
                rows.
</pre>
