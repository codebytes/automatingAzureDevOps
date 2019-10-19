$url = "https://dev.azure.com/client"
$project = "SmallSampleProject"
$username = "chris.ayers@newsignature.com"
$personalAccessToken = ""

$repos = @(
    "test",
    "vs",
    "SmallSampleProject"
)

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
$headers = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept"        = "application/json"
}

Function GetAllRepos([uri]$projectUrl) {
    $resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/git/repositories?api-version=1.0" -f $projectUrl)
    $json = convertFrom-JSON $resp.Content
    return $json
}


Function GetRepoInfo([uri]$repoUrl) {
    $resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/refs?api-version=5.0" -f $repoUrl)
    $json = convertFrom-JSON $resp.Content
    return $json
}

Function CreateRepo([uri]$projectUrl, $repo) {
    $JSON = @{
        name = $repo
    } | ConvertTo-Json  
    $resp = Invoke-RestMethod -Headers $headers -Uri ("{0}/{1}/_apis/git/repositories?api-version=1.0" -f $url, $project) -Method Post -Body $JSON -ContentType "application/json"
    return $resp
}

Function InitAddGitIgnore([uri]$repoUrl) {
    $newHeaders = $headers
    $newHeaders["Accept"] = "application/json;api-version=5.2-preview.2;excludeUrls=true"
    $json = "{""refUpdates"":[{""name"":""refs/heads/master"",""oldObjectId"":""0000000000000000000000000000000000000000""}],""commits"":[{""comment"":""Added .gitignore (VisualStudio) file"",""changes"":[{""changeType"":1,""item"":{""path"":""/.gitignore""},""newContentTemplate"":{""name"":""VisualStudio.gitignore"",""type"":""gitignore""}}]}]}";
    $resp = Invoke-RestMethod -Headers $newHeaders -Uri ("{0}/pushes" -f $repoUrl) -Method Post -Body $json -ContentType "application/json"
    return $resp
}

[uri] $projectUrl = ("{0}/{1}" -f $url, $project)
$projectRepos = GetAllRepos $projectUrl
 
foreach ($repo in $repos) {
    $repoUrl = "";
    $foundRepo = $projectRepos.value | Where-Object { $_.name -eq $repo }
    if ($foundRepo) {
        $commits = GetRepoInfo $foundRepo.url
        $needsInit = $commits.count -eq 0
        $repoUrl = $foundRepo.url
    }
    else {
        $newRepo = CreateRepo $project $repo
        $repoUrl = $newRepo.url
        $needsInit = true
    }
    if ($needsInit) {
        InitAddGitIgnore $repoUrl
    }
}
