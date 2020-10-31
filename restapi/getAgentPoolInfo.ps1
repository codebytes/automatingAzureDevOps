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
$project = "PartsUnlimited"
$username = "chris.ayers@newsignature.com"
$PAT = ""

$headers = Get-Headers $username $PAT
$existingAgentPools = GetAgentPools $Org $headers

foreach ($agent in $existingAgentPools) { 


}

$queues = GetAgentQueues $org $project $headers
$queues