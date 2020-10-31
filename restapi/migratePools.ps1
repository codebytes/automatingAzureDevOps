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

$sourceOrg = ""
$sourceUsername = "chris.ayers@newsignature.com"
$sourcePersonalAccessToken = ""

$targetOrg = ""
$targetProj = "Touchstone"
$targetUsername = ""
$targetPersonalAccessToken = ""

$cOrg = "https://dev.azure.com/chrisNewSig"
$cProj = "PartsUnlimited"
$cUname = "chris.ayers@newsignature.com"
$cPat = ""

# $sourceHeaders = Get-Headers $sourceUsername $sourcePersonalAccessToken
# $targetHeaders = Get-Headers $targetUsername $targetPersonalAccessToken
$cHeaders = Get-Headers $cUname $cPat

Function ReplaceBuildDefinitionPool($buildDefinition, $pool){
    $buildDefinition.queue = @{
        "name"="$pool"
    }
    return $buildDefinition
}

Function ReplaceBuildStagePools($buildDefinition, $pool){
    foreach($phase in $buildDefinition.process.phases){
        if($phase.target.queue -ne $NULL){
            $phase.target.queue = @{id=791}
        }
    }
    
    return $buildDefinition
}

Function ReplaceBuildPools($buildDefinition){
    $buildDefinition = ReplaceBuildDefinitionPool $buildDefinition $buildDefinition.queue.name
    # $buildDefinition = ReplaceBuildDefinitionPool $buildDefinition "pool2"
    $buildDefinition = ReplaceBuildStagePools $buildDefinition

    # $buildDefJson = $buildDefinition | ConvertTo-Json -Depth 100 -Compress
    # $def = [System.Text.Encoding]::UTF8.GetBytes($buildDefJson)
    $buildDefJson = $buildDefinition | ConvertTo-Json -Depth 100
    # $def = [System.Text.Encoding]::UTF8.GetBytes($buildDefJson)
    return $buildDefJson
}

$cPat | az devops login --org $cOrg
$buildPipelines = az pipelines build definition list --org $cOrg --proj $cProj -o json | convertfrom-json
foreach($buildPipeline in $buildPipelines)
{
    $buildDef = az pipelines build definition show --org $cOrg --proj $cProj --id $buildPipeline.id -o json | convertfrom-json
    $def = ReplaceBuildPools $buildDef
 #   UpdateBuildDef $cOrg $cProj $cHeaders $buildPipeline.id $def
}

# $buildDefs = az pipelines build definition list --project "Touchstone" -o json | convertfrom-json

# $builds = @()
# foreach ($buildDef in $buildDefs) {
#     $id = $buildDef.id

#     $def = az pipelines build definition show --id $id --project "Touchstone" -o json | convertfrom-json
#     $builds += @{
#         id=$def.id
#         name=$def.name
#         queueid=$def.queue.id
#         poolName=$def.queue.pool
#     }
# }
