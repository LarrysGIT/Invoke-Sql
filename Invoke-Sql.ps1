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
