$url = "https://dev.azure.com/client"
$username = "chris.ayers@newsignature.com"
$personalAccessToken = ""

# Retrieve list of all repositories
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
$headers = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept"        = "application/json"
}

$projectsResponse = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/projects?api-version=1.0" -f $url)
$projects = convertFrom-JSON $projectsResponse.Content

$initpath = get-location

foreach ($project in $projects.value) {
    $resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/{1}/_apis/git/repositories?api-version=1.0" -f $url, $project.name)
    $json = convertFrom-JSON $resp.Content

    set-location $initpath
    $teamPath = $project.name
    New-Item -ItemType Directory -Force -Path $teamPath

    set-location $teamPath
    # Clone or pull all repositories
    foreach ($entry in $json.value) { 
        $name = $entry.name 
        Write-Host $project.name - $name
        if (!(Test-Path -Path $name)) {
            git clone $entry.remoteUrl
        }
        else {
            set-location $name
            git pull
            set-location $initpath
        }
    }

}
set-location $initpath
  