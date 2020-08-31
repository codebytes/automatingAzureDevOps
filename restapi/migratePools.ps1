$sourceOrg = "https://dev.azure.com/chrisNewSig/"
$sourceUsername = "chris.ayers@newsignature.com"
$sourcePersonalAccessToken = ""

$targetOrg = "https://dev.azure.com/chrisNewSig/"
$targetUsername = "chris.ayers@newsignature.com"
$targetPersonalAccessToken = ""

$cOrg = "https://dev.azure.com/chrisNewSig"
$cProj = "PartsUnlimited"
$cUname = "chris.ayers@newsignature.com"
$cPat = ""

# Retrieve list of all repositories
Function Get-Headers($username, $personalAccessToken) {
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
    $headers = @{
        "Authorization" = ("Basic {0}" -f $base64AuthInfo)
        "Accept"        = "application/json"
    }
    return $headers;
}

$sourceHeaders = Get-Headers $sourceUsername $sourcePersonalAccessToken
$targetHeaders = Get-Headers $targetUsername $targetPersonalAccessToken
$cHeaders = Get-Headers $cUname $cPat

Function GetAgentPools($org, $headers) {
    $agentsResponse = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/distributedtask/pools?api-version=5.1" -f $sourceOrg)
    $agents = convertFrom-JSON $agentsResponse.Content
    return $agents.value
}

Function GetBuildDef($org, $project, $headers, $definitionId) {
    $URI = ("{0}/{1}/_apis/build/definitions/{2}?api-version=6.0" -f $org, $project, $definitionId)
    $agentsResponse = Invoke-WebRequest -Headers $headers -Uri $URI -Method Get
    $agents = convertFrom-JSON $agentsResponse.Content
    return $agents
}

Function UpdateBuildDef($org, $project, $headers, $definitionId, $body) {
    $URI = ("{0}/{1}/_apis/build/definitions/{2}?api-version=6.0" -f $org, $project, $definitionId)
    $agentsResponse = Invoke-WebRequest -Headers $headers -Uri $URI -Method Put -body $body  -ContentType "application/json"
    $agents = convertFrom-JSON $agentsResponse.value
    return $agents.value
}

# $cPat | az devops login --org $cOrg
$buildDef = az pipelines build definition show --org $cOrg --proj $cProj --id 59 -o json | convertfrom-json
$buildDef.queue = @{
    "id"=770
    "name"="pool2"
}
$buildDef.revision++
$buildDef.PSObject.Properties.Remove('triggers')
UpdateBuildDef $cOrg $cProj $cHeaders 59 ($buildDef | convertTo-json)


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
