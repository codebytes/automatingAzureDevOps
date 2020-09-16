# region Include required files
#
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    . ("$ScriptDirectory\DevOpsFunctions.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}
#endregion

$org = "https://dev.azure.com/chrisNewSig"
$username = "chris.ayers@newsignature.com"
$PAT = "nvzdqrk4qafewkizyhllzjxopdhsajrqhqfumokbarzchqmdjm2q"

$headers = Get-Headers $username $PAT
$existingAgentPools = GetAgentPools $Org $headers

$path = "$ScriptDirectory\agentpools.csv";
$listedPools = Import-Csv -path $path
foreach ($pool in $existingAgentPools) { 
    if($listedPools | Where-Object { $_.PoolName -eq $pool.name } ){
        Write-Host $pool.name "Exists"
        Remove-AgentPool $Org $headers $pool.id
    }
}

