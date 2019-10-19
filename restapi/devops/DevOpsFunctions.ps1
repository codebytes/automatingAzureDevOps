#region Helper

function Get-Headers($username, $personalAccessToken) {
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
    $headers = @{
        "Authorization" = ("Basic {0}" -f $base64AuthInfo)
        "Accept"        = "application/json"
    }
    return $headers;
}

function Write-ErrorFile([string] $errorMessage) {
    <#
    .SYNOPSIS
    
    Write Error to local file
    
    .DESCRIPTION
    
    Takes in a message and writes it to local directory ErrorLog.txt.  Creates file if none exists
    
    .PARAMETER errorMessage
    Specifies the message to write
    
    #>
    $message = "$errormessage`r`n"
    if (!(Test-Path ".\ErrorLog.txt")) {
        New-Item  .\ErrorLog.txt -type "file" -value $message
    }
    else {
        Add-Content .\ErrorLog.txt  -value $message
    }   
}

Function Get-GitIgnore {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$list
    )
    $params = ($list | ForEach-Object { [uri]::EscapeDataString($_) }) -join ","
    Invoke-WebRequest -Uri "https://www.gitignore.io/api/$params" | Select-Object -ExpandProperty content | Out-File -FilePath $(Join-Path -path $pwd -ChildPath ".gitignore") -Encoding ascii
}
    
#endregion
    
#region Repositories

Function CreateRepo([uri]$projectUrl, $repoName, $headers) {
    $JSON = @{
        name = $repoName
    } | ConvertTo-Json  
    $resp = Invoke-RestMethod -Headers $headers -Uri ("{0}/_apis/git/repositories?api-version=1.0" -f $projectUrl) -Method Post -Body $JSON -ContentType "application/json"
    return $resp
}

Function InitAddGitIgnore([uri]$repoUrl, $headers) {
    $newHeaders = $headers
    $newHeaders["Accept"] = "application/json;api-version=5.2-preview.2;excludeUrls=true"
    $json = "{""refUpdates"":[{""name"":""refs/heads/master"",""oldObjectId"":""0000000000000000000000000000000000000000""}],""commits"":[{""comment"":""Added .gitignore (VisualStudio) file"",""changes"":[{""changeType"":1,""item"":{""path"":""/.gitignore""},""newContentTemplate"":{""name"":""VisualStudio.gitignore"",""type"":""gitignore""}}]}]}";
    $resp = Invoke-RestMethod -Headers $newHeaders -Uri ("{0}/pushes" -f $repoUrl) -Method Post -Body $json -ContentType "application/json"
    return $resp
}

Function GetRepos([uri]$projectUrl, $headers) {
    $resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/git/repositories?api-version=1.0" -f $projectUrl)
    $json = convertFrom-JSON $resp.Content
    return $json
}

#endregion

#region Pipelines

Function CreateSampleAzurePipelineYML($path) {
    $yml = @'
# Starter pipeline
# Start with a minimal pipeline that you can customize to build and deploy your code.
# Add steps that build, run tests, deploy, and more:
# https://aka.ms/yaml

trigger:
 branches:
    include:
      -  master

pool:
  name: Hosted Windows 2019 with VS2019

steps:
- script: echo Add Build Steps
  displayName: 'Sample Step'

'@;
    $yml | Out-File -FilePath $path -Force;
}

Function CreateYamlBuildDefinition([uri]$projectUrl, [guid]$repoId, $gitRepo, $headers) {
    # JSON for setting work item required policy
    $JSONBody = @"
    {
        "process": {
            "yamlFilename": "./azure-pipelines.yml",
            "type": 2
        },
        "triggers":  [
            {
                "branchFilters":  "",
                "pathFilters":  "",
                "settingsSourceType":  2,
                "batchChanges":  false,
                "maxConcurrentBuildsPerBranch":  1,
                "triggerType":  "continuousIntegration"
            }
        ],
        "repository": {
            "id": "$repoId",
            "type": "TfsGit",
            "defaultBranch": "refs/heads/master"
        },
        "queue": {
            "name":  "Hosted Windows 2019 with VS2019"
        },
        "name": "$gitRepo",
        "type": "build"
    }
"@;
    # Use URI and JSON above to apply work item required to specified branch
    $resp = Invoke-RestMethod -Uri ("{0}/_apis/build/definitions?api-version=5.0" -f $projectUrl) -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    return $resp;
}

function Start-Build($projectUrl, $buildDefinitionId, $headers) {
    $JSONBody = @"
{
    "definition": {
        "id": $buildDefinitionId
    }
}
"@;
    # Use URI and JSON above to apply work item required to specified branch
    $resp = Invoke-RestMethod -Uri ("{0}/_apis/build/builds?api-version=5.1" -f $projectUrl) -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    return $resp;
}

function Get-BuildDefinitions([string] $projectUrl, $headers) {
    <#
    .SYNOPSIS
    
    Get build definitions for a project
    
    .DESCRIPTION
    
    Gets response body of Build definition get and returns 
    
    .PARAMETER projectUrl
    URL of collection/vsts account and Project to get definitions from
    
    .PARAMETER headers
    Header to send with file.  If null, uses default credentials
    #>
    
    $response = $null
    try {
        $ErrorActionPreference = "Stop"
        $Url = $projectUrl + "/_apis/build/definitions?api-version=5.1&type=build"
        if ($headers) {
            $response = Invoke-RestMethod -Uri $Url -Headers $headers -Method Get -ContentType application/json;
        }
        else {
            $response = Invoke-RestMethod -Uri $Url -Method Get -UseDefaultCredentials -ContentType application/json;
        }
            
    }
    catch {
        $currentFunction = $MyInvocation.MyCommand
        $exception = $_.Exception.Message
        $errorMessage = "$currentFunction - $projectUrl : $exception"
        Write-ErrorFile $errorMessage
    }
    finally {
        $ErrorActionPreference = "Continue"
        $response
    }
}
    
function Get-BuildDefinition([string] $projectUrl, [string] $Id, $headers) {

    <#
    .SYNOPSIS
    
    Get a specific build definition
    
    .DESCRIPTION
    
    Gets response body of Build definition get and returns 
    
    .PARAMETER BaseURL
    URL of collection/vsts account
    
    .PARAMETER Project
    Project to get definitions from
    
    .PARAMETER Project
    ID of build definition
    .PARAMETER headers
    Header to send with file.  If null, uses default credentials
    #>
    $response = $null
    try {
        $ErrorActionPreference = "Stop"
        $Url = $projectUrl + "/_apis/build/definitions/" + $Id + "?api-version=5.1"
        if ($headers) {
            $response = Invoke-RestMethod -Uri $Url -Headers $headers -Method Get -ContentType application/json
        }
        else {
            $response = Invoke-RestMethod -Uri $Url  -Method Get -UseDefaultCredentials -ContentType application/json
        }
            
    }
    catch {
        $currentFunction = $MyInvocation.MyCommand
        $exception = $_.Exception.Message
        $errorMessage = "$currentFunction - $projectUrl : $exception"
        Write-ErrorFile $errorMessage
    }
    finally {
        $ErrorActionPreference = "Continue"
        $response
    }
}
    

function Remove-BuildValues([string] $projectUrl, [string] $BuildId, [String[]] $values, [psobject] $headers) {
    <#
    .SYNOPSIS
    
    Remove specific objects from retrieved build
    
    .DESCRIPTION
    
    Gets a specific build definition and removes listed section from response body
    
    .PARAMETER BaseURL
    URL of collection/vsts account
    
    .PARAMETER Project
    Project to run against
    
    .PARAMETER BulidID
    Build to retrieve
    
    .PARAMETER values
    Array of values to remove
    
    .PARAMETER headers
    Header to send with file.  If null, uses default credentials
    
    #>
    $response = $null
    try {
        $ErrorActionPreference = "Stop"
        $BuildDefinition = Get-BuildDefinition $projectUrl $BuildId $headers 
        foreach ($value in $values) {
            $BuildDefinition.PSObject.Properties.Remove($value)    
        }
        $response = $BuildDefinition
    
    }   
    catch {
        $currentFunction = $MyInvocation.MyCommand
        $exception = $_.Exception.Message
        $errorMessage = "$currentFunction - $projectUrl : $exception"
        Write-ErrorFile $errorMessage
    }
    finally {
        $ErrorActionPreference = "Continue"
        $response
    }
}


function New-BuildDefinition([string] $projectUrl, [string] $body, [psobject] $headers) {
    <#
   .SYNOPSIS
   
   Create a new build definition
   
   .DESCRIPTION
   
   Sends in provided body to create new build definion
   
   .PARAMETER BaseURL
   URL of collection/vsts account
   
   .PARAMETER Project
   Project to run against
   
   .PARAMETER body
   Body to send in.  Assumed to be correct format for a build request
   
   .PARAMETER headers
   Header to send with file.  If null, uses default credentials
   #>
       $response = $null
       try {
           $ErrorActionPreference = "Stop"
           $Url = "$projectUrl/_apis/build/definitions?api-version=2.0"
           if($headers){
               $responseBody = Invoke-RestMethod -Uri $Url -Headers $headers -Body $body -Method Post -ContentType application/json;
           }
           else {
               $responseBody = Invoke-RestMethod -Uri $Url -Body $body -Method Post -UseDefaultCredentials -ContentType application/json;
           }
           $response = $responseBody.ID
       }
       catch{
           $currentFunction = $MyInvocation.MyCommand
           $exception = $_.Exception.Message
           $errorMessage = "$currentFunction - $projectUrl : $exception"
           Write-ErrorFile $errorMessage
       }
       finally{
           $ErrorActionPreference = "Continue"
           $response
       }
   }
   
   function Get-BuildDefinitionIDs([string]$projectUrl, [psobject] $headers) {
    <#
   .SYNOPSIS
   
   Get Build Definition IDs for a project
   .DESCRIPTION
   
   Retrieves just ID values for all builds
   
   .PARAMETER BaseURL
   URL of collection/vsts account
   
   .PARAMETER Project
   Project to run against
   
   .PARAMETER headers
   Header to send with file.  If null, uses default credentials
   #>
   
       $response = $null
       try {
           $ErrorActionPreference = "Stop"
           $Url = "$projectUrl/_apis/build/definitions?api-version=2.0&type=build"
           if($headers){
               $response = Invoke-RestMethod -Uri $Url -Headers $headers -Body $body -Method Get -ContentType application/json;
           }
           else {
               $response = Invoke-RestMethod -Uri $Url -Body $body -Method Get -UseDefaultCredentials -ContentType application/json;
           }
           $outItems = New-Object System.Collections.Generic.List[System.Object]
           foreach ($id in $response.value.id) {
               $outItems.Add($id)
           }
   
           $response = $outItems
           }
       catch{
           $currentFunction = $MyInvocation.MyCommand
           $exception = $_.Exception.Message
           $errorMessage = "$currentFunction : $exception"
           Write-ErrorFile $errorMessage
       }
       finally{
           $ErrorActionPreference = "Continue"
           $response
       }
   }
   
#endregion

#region Policies

Function GetPolicies([uri]$policyUrl, $headers) {
    $resp = Invoke-RestMethod -Uri $policyUrl -Method Get -Headers $headers 
    return $resp.value
}

Function DeleteConfiguration([uri]$projectUrl, [int]$configurationId, $headers) {
    [uri] $deleteUrl = ("{0}/_apis/policy/configurations/{1}?api-version=5.0" -f $projectUrl, $configurationId) 
    Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers 
    Write-Host "Policy Deleted: " $configurationId
}

Function DeleteAllPolicies([uri]$policyUrl, [uri]$projectUrl, $headers) {
    $policies = GetPolicies($policyUrl)
    foreach ($policy in $policies) {
        DeleteConfiguration $projectUrl $policy.id $headers
    }
}

#Policy Documentation: https://docs.microsoft.com/en-us/rest/api/azure/devops/policy/configurations/create?view=azure-devops-rest-5.1

Function ApplyReviewerPolicy([uri]$policyUrl, [guid]$repoId, $branch, [bool] $required, [guid[]]$reviewers, $headers) {       
        
    # JSON for setting appovers
    $reviewerJson = ConvertTo-Json $reviewers;
    $requiredString = $required.ToString().ToLower();
    $JSONBody = @"
{
    "isEnabled": true,
    "isBlocking": $requiredString,
    "type": {
        "id": "fd2167ab-b0be-447a-8ec8-39368250530e"
    },
    "settings": {
        "requiredReviewerIds": $reviewerJson,
        "addedFilesOnly": false,
        "scope": [
            {
            "repositoryId": "$repoId",
            "refName": "refs/heads/$branch",
            "matchKind": "exact"
            }
        ]
    }
}
"@

    # Use URI and JSON above to apply approver policy to specified branch
    Invoke-RestMethod -Uri $policyUrl -Headers $headers -Method Post -ContentType application/json -Body $JSONBody 
    write-host "Required Reviewer Policy set on branch: $branch"
}

Function ApplyMinimumApproverPolicy([uri]$policyUrl, [guid]$repoId, $branch, $reviewerCount, $headers) {
    # JSON for setting minimum approval count policy
    $JSONBody = @"
{
  "isEnabled": true,
  "isBlocking": false,
  "type": {
    "id": "fa4e907d-c16b-4a4c-9dfa-4906e5d171dd"
  },
  "settings": {
    "minimumApproverCount": $reviewerCount,
    "creatorVoteCounts": false,
    "resetOnSourcePush": true,
    "scope": [
      {
        "repositoryId": "$repoId",
        "refName": "refs/heads/$branch",
        "matchKind": "exact"
      }
    ]
  }
}
"@
    # Use URI and JSON above to apply minimum approver policy to specified branch
    Invoke-RestMethod -Uri $policyUrl -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    write-host "Minimum Approver Policy set on branch: $branch"
}

Function ApplyBuildPolicy([uri]$policyUrl, [guid]$repoId, $branch, $buildDefId, $headers) {
    # JSON for setting required build policy
    $JSONBody = @"
{
    "isEnabled": true,
    "isBlocking": true,
    "type": {
        "id": "0609b952-1397-4640-95ec-e00a01b2c241",
        "displayName": "Build"
    },
    "settings": {
    "buildDefinitionId": $buildDefId,
    "scope": [
        {
        "repositoryId": "$repoId",
        "refName": "refs/heads/$branch",
        "matchKind": "exact"
        }
        ]
    }
}
"@

    # Use URI and JSON above to apply build policy to specified branch
    Invoke-RestMethod -Uri $policyUrl -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    write-host "Build Policy set on branch: $branch"
}

Function ApplyWorkItemPolicy([uri]$policyUrl, [guid]$repoId, $branch, $headers) {
    # JSON for setting work item required policy
    $JSONBody = @"
{
    "isEnabled": true,
    "isBlocking": true,
    "type": {
    "id": "40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e"
    },
    "settings": {
    "scope": [
        {
        "repositoryId": "$repoId",
        "refName": "refs/heads/$branch",
        "matchKind": "exact"
        }
        ]
    }
}
"@

    # Use URI and JSON above to apply work item required to specified branch
    Invoke-RestMethod -Uri $policyUrl -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    write-host "Required Work Item Policy set on branch: $branch"
}

Function ApplyCommentPolicy([uri]$policyUrl, [guid]$repoId, $branch, $headers) {
    # JSON for setting work item required policy
    $JSONBody = @"
{
    "isEnabled": true,
    "isBlocking": true,
    "type": {
        "id": "c6a1889d-b943-4856-b76f-9e46bb6b0df2"
    },
    "settings": {
        "scope": [
            {
                "repositoryId": "$repoId",
                "refName": "refs/heads/$branch",
                "matchKind": "exact"
            }
        ]
    }
}
"@

    # Use URI and JSON above to apply work item required to specified branch
    Invoke-RestMethod -Uri $policyUrl -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    write-host "Resolved Comment Policy set on branch: $branch"
}

#endregion