$baseUrl = "https://extmgmt.dev.azure.com"
$sourceOrg = "client"
$sourceUsername = "chris.ayers@newsignature.com"
$sourcePersonalAccessToken = ""

$targetOrg = "chrisnebbia"
$targetUsername = "chris@nebbiatech.com"
$targetPersonalAccessToken = ""

# Retrieve list of all repositories
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $sourceUsername, $sourcePersonalAccessToken)))
$sourceHeaders = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept"        = "application/json"
}

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $targetUsername, $targetPersonalAccessToken)))
$targetHeaders = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept"        = "application/json"
}

Function GetExtensions($org, $headers) {
    $extensionsResponse = Invoke-WebRequest -Headers $headers -Uri ("{0}/{1}/_apis/extensionmanagement/installedextensions?api-version=5.0-preview.1" -f $baseUrl, $sourceOrg)
    $extensions = convertFrom-JSON $extensionsResponse.Content
    return $extensions.value
}

Function InstallExtensions($org, $headers, $extension) {
    # POST https://extmgmt.dev.azure.com/{organization}/_apis/extensionmanagement/installedextensionsbyname/{publisherName}/{extensionName}/{version}?api-version=5.0-preview.1
    $url = ("{0}/{1}/_apis/extensionmanagement/installedextensionsbyname/{2}/{3}/{4}?api-version=5.0-preview.1" -f $baseUrl, $org, $ext.publisherId, $ext.extensionId, $ext.version)
    $extensionsResponse = Invoke-WebRequest -Method Post -Headers $headers -Uri $url -ContentType "application/json"
    $extensions = convertFrom-JSON $extensionsResponse.Content    
    return $extesions
}

$extensions = GetExtensions $sourceOrg $sourceHeaders
foreach ($ext in $extensions) {
    Write-Host $ext
    try{
    InstallExtensions $targetOrg $targetHeaders $ext
    }
    Catch{
        Write-Host $_
    }
}


