# Invoke-Sql
A replacement when invoke-sqlcmd cmdlet is not available

## Invoke-Sql
    * Is able to handle the key separator `GO` (by replacing, maybe there is unknown bug)
    * Is able to handle duplicate columns
    * Fully support multiple result sets
    * Unable to handle `Create or alter` key words if there are contents ahead
    * Unable to handle special characters like `194 160` (non-breaking space) in SQL script (edited by some document edit tool, MS word for example)

## Invoke-SqlCmd
    * Is able to handle the key separator `GO`
    * Is able to handle special characters like `non-breaking space`
    * Unable to handle duplicate columns
    * Unable to fully handle multiple result sets (when first table is empty)

## sqlcmd.exe
    * Is able to handle all things
    * The returned result sets are plain text, hard to parse

## `Microsoft.SqlServer.SMO`
    * The API of SQL server management studio
    * Theoratically should be able to handle all cases
    * Need dig more
