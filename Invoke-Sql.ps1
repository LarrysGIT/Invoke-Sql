
function Invoke-Sql(){
    PARAM(
        [string]$Query,
        [string]$ServerInstance,
        [string]$Database = $null,
        [string]$Username = $null,
        [string]$Password = $null,
        [string]$ConnectionString = $null,
        [int]$ConnectionTimeout = 10,
        [int]$QueryTimeout = 30,
        [switch]$TrimGOKeyword = $true
    )
    if($ConnectionString)
    {
        $sqlConnectionString = $ConnectionString
    }
    else
    {
        $sqlConnectionString = "Server=$ServerInstance"
        if($Database){$sqlConnectionString += ";Database=$Database"}
        if($Username){$sqlConnectionString += ";User Id=$Database; Password=$Password"}
                 else{$sqlConnectionString += ";Trusted_Connection=True"}
        if($ConnectionTimeout){$sqlConnectionString += ";Connect Timeout=$ConnectionTimeout"}
    }
    if($TrimGOKeyword)
    {
        $Query = $Query -ireplace "(^|\r|\n)[ \t]*\bGO\b[ \t]*(\r|\n|$)", '$1$2'
    }
    $sql_Conn = New-Object System.Data.SqlClient.SQLConnection
    $sql_Conn.ConnectionString = $sqlConnectionString
    $sql_Conn.Open()
    $sql_cmd = New-Object system.Data.SqlClient.SqlCommand($Query, $sql_Conn)
    $sql_cmd.CommandTimeout = $QueryTimeout
    $sql_ds = New-Object system.Data.DataSet
    $sql_da = New-Object system.Data.SqlClient.SqlDataAdapter($sql_cmd)
    [void]$sql_da.fill($sql_ds)
    $sql_Conn.Close()
    return $sql_ds
}

function Get-TableDefinition
{
    PARAM(
        [string]$ServerInstance,
        [string]$Database,
        [string]$UserName,
        [string]$Password,
        [string]$ConnectionString,
        [string]$TableNamePattern,
        [switch]$SimpleTable
    )

    if(!$ConnectionString)
    {
        $ConnectionString = "Server=$ServerInstance;Database=$Database;"
        if($UserName)
        {
            $ConnectionString += ";User Id=$UserName; Password=$Password"
        }
        else
        {
            $ConnectionString += ";Trusted_Connection=True"
        }
    }

    class objTable {
        [string]$TableName
        [string]$TableCreationScript
    }

    [Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null

    $options = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ScriptingOptions
    $options.DriAll = !$SimpleTable
    $options.SchemaQualify = $true

    $connection = New-Object -TypeName Microsoft.SqlServer.Management.Common.ServerConnection
    $connection.ConnectionString = $ConnectionString
    $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $connection
    $server.Databases.Item($Database).Tables | ?{$_.Name -imatch $TableNamePattern} | %{
        New-Object objTable -Property @{TableName = $_.Name; TableCreationScript = $_.Script($options)}
    }
    $connection.Disconnect()
    $connection = $null
    $server = $null
}

function Invoke-DTSWizard
{
    PARAM(
        [string]$SourceInstance,
        [string]$SourceDatabase,
        [string]$SourceUserName,
        [string]$SourcePassword,
        [string]$SourceConnectionString,
        [string]$TableNamePattern,
        [string]$DestinationInstance,
        [string]$DestinationDatabase,
        [string]$DestinationUserName,
        [string]$DestinationPassword,
        [string]$DestinationConnectionString,
        [switch]$DisableKeyConstraintCheck
    )

    # Build source connection string
    if(!$SourceConnectionString)
    {
        $SourceConnectionString = "Server=$SourceInstance;Database=$SourceDatabase;"
        if($SourceUserName)
        {
            $SourceConnectionString += ";User Id=$SourceUserName; Password=$SourcePassword"
        }
        else
        {
            $SourceConnectionString += ";Trusted_Connection=True"
        }
    }

    # Build destination connection string
    if(!$DestinationConnectionString)
    {
        $DestinationConnectionString = "Server=$DestinationInstance;Database=$DestinationDatabase;"
        if($DestinationUserName)
        {
            $DestinationConnectionString += ";User Id=$DestinationUserName; Password=$DestinationPassword"
        }
        else
        {
            $DestinationConnectionString += ";Trusted_Connection=True"
        }
    }

    function private:BulkCopyTable()
    {
        PARAM(
            [string]$SourceConnectionString,
            [string]$DestinationConnectionString,
            [string]$TableName
        )
        $SourceConnection = New-Object System.Data.SqlClient.SQLConnection($SourceConnectionString)
        $SourceSqlCommand = New-Object system.Data.SqlClient.SqlCommand("Select * From [$TableName];", $SourceConnection)
        $SourceConnection.Open()
        [System.Data.SqlClient.SqlDataReader]$SourceSqlReader = $SourceSqlCommand.ExecuteReader()

        $DestinationBulkCopy = New-Object Data.SqlClient.SqlBulkCopy($DestinationConnectionString, [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity)
        $DestinationBulkCopy.DestinationTableName = "[$TableName]"
        $DestinationBulkCopy.WriteToServer($SourceSqlReader)
        
        $SourceSqlReader.Close()
        $SourceConnection.Close()
        $SourceConnection.Dispose()
        $DestinationBulkCopy.Close()
    }

    $Tables = Get-TableDefinition -ServerInstance $SourceInstance -Database $SourceDatabase -TableNamePattern $TableNamePattern -ConnectionString $SourceConnectionString -SimpleTable
    if($DisableKeyConstraintCheck)
    {
        foreach($Table in $Tables)
        {
            Invoke-Sql -Query "ALTER TABLE [$($Table.TableName)] NOCHECK CONSTRAINT ALL;" -Database $DestinationDatabase -ServerInstance $DestinationInstance | Out-Null
        }
    }
    foreach($Table in $Tables)
    {
        Write-Host "Copying [$($Table.TableName)]"
        # drop destination table
        Invoke-Sql -Query "Drop table if exists [$($Table.TableName)];" -Database $DestinationDatabase -ServerInstance $DestinationInstance
        # create destination table
        Invoke-Sql -Query $Table.TableCreationScript -Database $DestinationDatabase -ServerInstance $DestinationInstance
        # CopyTable
        BulkCopyTable -SourceConnectionString $SourceConnectionString -DestinationConnectionString $DestinationConnectionString -TableName $Table.TableName
    }
}
