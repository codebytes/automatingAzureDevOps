#=====================
param(
[string]$account,  # the name of your DevOps organization
[string]$username, # alternate credentials username
[string]$password, # password
[string]$project, #Project Queried
[string]$reportGuid, #id of ther query being output
[string]$buildVersion,
[string]$applicationName,
[string]$apiVersion = "1.0",
[string]$fileName = ".\ReleaseNotes.html"
)
#======================
#SAMPLE USAGE: ./ReleaseNotes.ps1 -account:<name>> -project:<project>> -username:Basic -password:<Personal Access Token> -reportGuid:<report guid> -buildVersion:$(Build.BuildNumber) -applicationName:slothycode -fileName:$(build.stagingDirectory)\ReleaseNotes$(Build.BuildNumber).html


Write-Host "Starting generating release notes for " + $buildVersion

$basicAuth = ("{0}:{1}" -f $username,$password)
$basicAuth = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
$basicAuth = [System.Convert]::ToBase64String($basicAuth)
$headers = @{Authorization=("Basic {0}" -f $basicAuth)}

#=== Get the list of items in this release ===
$reportUrl = "https://" + $account + ".visualstudio.com/DefaultCollection/" + $project + "/_apis/wit/wiql/" + $reportGuid + "?api-version=" + $apiVersion
Write-Host "Calling to get release items: " $reportUrl
$reportItems = Invoke-RestMethod -Uri $reportUrl -headers $headers -Method Get
 
$releaseNotes = "<html><title>" + $applicationName + " " + $buildVersion + "</title><body><h1>Release Notes for " + $applicationName + " " + $buildVersion + "</h1>"

#=== Add the details for each item ===
foreach($reportItem in $reportItems.workItems)
{
  #=== Get the work item details ===
  Write-Host " - Getting release item details: " $reportItem.Url
  $reportItemDetails = Invoke-RestMethod -Uri $reportItem.Url -headers $headers -Method Get
 
  #=== Add the work items details to the output ===
  $workItemUrl = "https://" + $account + ".visualstudio.com/DefaultCollection/" + $project + "/_workitems#_a=edit&fullScreen=true&id=" + $reportItemDetails.Id
  $releaseNotes += "<p><a href='" + $workItemUrl + "'>" + $reportItemDetails.fields.'System.WorkItemType' + " " + $reportItemDetails.Id + "</a> " + $reportItemDetails.fields.'System.Title' +"<br/>"
  $releaseNotes += "<b>Description</b><br/>" + $reportItemDetails.fields.'System.Title' + "</p>"
}

$releaseNotes += "</body></html>"

#=== Write the release notes to the output file === 
Write-Host "Starting to write release notes to: " + $fileName
$releaseNotes | out-file $fileName
Write-Host "Finished writing release notes"