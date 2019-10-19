# GET https://dev.azure.com/{organization}/{project}/_apis/build/builds/{buildId}/workitems?api-version=5.0
$url = "https://dev.azure.com/client"
$username = "chris.ayers@newsignature.com"
$personalAccessToken = ""

# Retrieve list of all repositories
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
$headers = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept"        = "application/json"
}
# Retrieve list of all repositories
Function GetBuilds([uri]$projectUrl) {
    $resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/build/builds?api-version=5.0" -f $projectUrl )
    $json = convertFrom-JSON $resp.Content
    return $json
}


Function GetBuildById([uri]$projectUrl, [int]$buildId) {
    $resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/build/builds/{1}?api-version=5.0" -f $projectUrl, $buildId )
    $json = convertFrom-JSON $resp.Content
    return $json
}

Function GetWorkItemsByBuildId([uri]$projectUrl, [int]$buildId) {
    $resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/build/builds/{1}/workitems?api-version=5.0" -f $projectUrl, $buildId )
    $json = convertFrom-JSON $resp.Content
    return $json
}

Function GetWorkItemById([uri]$projectUrl, [int]$workItemId) {
    $resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/wit/workitems/{1}?api-version=5.0" -f $projectUrl, $workItemId )
    $json = convertFrom-JSON $resp.Content
    return $json
}

$builds = GetBuilds $url
foreach ($build in $builds.value) {
    $buildinfo = GetBuildById $url $build.id
    write-host $build
    $workItems = GetWorkItemsByBuildId $url $build.id
    if ($workItems.count -ne 0) {
        write-host $workItems.value
        foreach ($workItem in $workItems.value) {
            $workItemDetail = GetWorkItemById $url $workItem.id
            write-host $workItemDetail    
        }
    }
}

