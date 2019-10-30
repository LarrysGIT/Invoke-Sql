# Invoke-Sql
A replacement when invoke-sqlcmd cmdlet is not available

## Invoke-Sql
    * Is able to handle the key separator `GO` (by regular expression replacing, maybe there is an unknown bug)
    * Is able to handle duplicate columns
    * Fully support multiple result sets
    * Unable to handle 'Create or alter' key words
    * Unable to handle special characters like '194 160' (non-breaking space) in SQL script (edited by some document edit tool, MS word for example)

## Invoke-SqlCmd
    * Is able to handle the key separator 'GO'
    * Is able to handle special characters like 'non-breaking space'
    * Unable to handle duplicate columns
    * Unable to fully handle multiple result sets (when first set is empty, nothing will be returned)

## sqlcmd.exe
    * Is able to handle all things
    * The returned result sets are plain text, hard to parse

## `Microsoft.SqlServer.SMO`
    * Brief tested. 
    * Seems not able to handle 'GO'.
    * The ability to handle special characters like 'non-breaking space' needs to be tested

# DTSWizard.exe
The SQL Server data import/export tools is usefully sometimes. Unfortunately, there is no straight way to automate it

So, some new commands introduced here to emulate DTSWizard.exe

# Get-TableDefinition
Generate a table and its Definition,

 - Require SQL management studio installed because script uses API https://docs.microsoft.com/en-us/sql/powershell/load-the-smo-assemblies-in-windows-powershell?view=sql-server-ver15
 - Same activity in SQL management studio, right click on table -> script table as -> create to

```
# The following example, get tables matched regular expression "^Table\d"
Get-TableDefinition -ServerInstance SQL01\Instance01 -Database DB01 -TableNamePattern "^Table\d"
```

# Invoke-DTSWizard
A replacement to automate DTSWizard.exe, uses the .NET API `Data.SqlClient.SqlBulkCopy`

 - The command will `drop` any existing tables in destination
 - The parameter `TableNamePattern` is regular expression, use with caution

```
# The following example, copy any tables (source instance) matched regular expression "^Table\d", e.g. "Table0" and "Table99", to destination instance, the copy will drop tables with the same table name in destination
Invoke-DTSWizard -SourceInstance "SQL01\Instance01" -SourceDatabase DB01 -TableNamePattern "^Table\d" -DestinationInstance SQL02\Instance02 -DestinationDatabase DB02
```
