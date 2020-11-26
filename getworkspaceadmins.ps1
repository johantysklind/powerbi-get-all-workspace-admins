$SecPasswd = ConvertTo-SecureString "xxx" -AsPlainText -Force
$myCred = New-Object System.Management.Automation.PSCredential("user@email.net",$SecPasswd)
$PBIGroupsFile = "PBIGroupsExpanded.json"
$PBIGroupsFileCSV =  "WorkspaceUsers.csv"
$PBIGroupsNr = 500
Connect-PowerBIServiceAccount -Credential $myCred

$ActiveGroupsURLExPersonal = '/admin/groups?$top=' + $PBIGroupsNr + '&' + '$filter=type ne' + " 'PersonalGroup'" + ' and state eq' + " 'Active'" + '&$expand=users'

Invoke-PowerBIRestMethod -Url $ActiveGroupsURLExPersonal -Method Get | Out-File $PBIGroupsFile

$JSON = Get-Content -Raw -Path $PBIGroupsFile  | ConvertFrom-Json

$OutArray = @()
$JSON.value | Select-Object -Property id,name,users| ForEach-Object {
    $WS_NAME = $_.name
    $WS_ID =   $_.id
    $_.users | Select-Object -Property emailAddress,groupUserAccessRight| ForEach-Object {
        If ( $_.groupUserAccessRight -eq "Admin") {
            $wsobj = "" | Select "WS_ID", "WS_NAME", "USER", "USER_ACCESS"
            $wsobj.WS_NAME = $WS_NAME
            $wsobj.WS_ID =    $WS_ID
            $wsobj.USER = $_.emailAddress
            $wsobj.USER_ACCESS =  $_.groupUserAccessRight
            $outarray += $wsobj 
            $wsobj = $null
        }
    }
}
$outarray| export-csv  $PBIGroupsFileCSV