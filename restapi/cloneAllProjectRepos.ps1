$url = "https://dev.azure.com/client"
$username = "chris.ayers@newsignature.com"
$personalAccessToken = ""

# Retrieve list of all repositories
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
$headers = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept"        = "application/json"
}

$resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/git/repositories?api-version=1.0" -f $url)
$json = convertFrom-JSON $resp.Content

# Clone or pull all repositories
$initpath = get-location
foreach ($entry in $json.value) { 
    $name = $entry.name 
    Write-Host $name
    if (!(Test-Path -Path $name)) {
        git clone $entry.remoteUrl
    }
    else {
        set-location $name
        git pull
        set-location $initpath
    }
}
