$url = "https://dev.azure.com/client"
$username = "chris.ayers@newsignature.com"
$personalAccessToken = ""
$branch = "master"
$requiredReviewers = [guid]"";

# Retrieve list of all repositories
Function GetRepos([uri]$projectUrl) {
    $resp = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/git/repositories?api-version=1.0" -f $projectUrl)
    $json = convertFrom-JSON $resp.Content
    return $json
}

Function GetPolicies([uri]$policyUrl) {
    $resp = Invoke-RestMethod -Uri $policyUrl -Method Get -Headers $headers 
    return $resp.value
}

Function DeleteConfiguration([uri]$projectUrl, [int]$configurationId) {
    [uri] $deleteUrl = ("{0}/_apis/policy/configurations/{1}?api-version=5.0" -f $projectUrl, $configurationId) 
    $resp = Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers 
    Write-Host "Policy Deleted: " $configurationId
}

Function DeleteAllPolicies([uri]$policyUrl, [uri]$projectUrl) {
    $policies = GetPolicies($policyUrl)
    foreach ($policy in $policies) {
        DeleteConfiguration $projectUrl $policy.id
    }
}

Function ApplyRequiredReviewerPolicy([uri]$policyUrl, [guid]$repoId) {       
        
    # JSON for setting appovers
    $JSONBody = @"
{
    "isEnabled": true,
    "isBlocking": true,
    "type": {
    "id": "fd2167ab-b0be-447a-8ec8-39368250530e"
    },
    "settings": {
    "requiredReviewerIds": [
        "$requiredReviewers"
    ],
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
    $resp = Invoke-RestMethod -Uri $policyUrl -Headers $headers -Method Post -ContentType application/json -Body $JSONBody 
    write-host "Required Reviewer Policy set on branch: $branch"
}

Function ApplyMinimumApproverPolicy([uri]$policyUrl, [guid]$repoId) {
    # JSON for setting minimum approval count policy
    $JSONBody = @"
{
  "isEnabled": true,
  "isBlocking": false,
  "type": {
    "id": "fa4e907d-c16b-4a4c-9dfa-4906e5d171dd"
  },
  "settings": {
    "minimumApproverCount": 2,
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
    $resp = Invoke-RestMethod -Uri $policyUrl -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    write-host "Minimum Approver Policy set on branch: $branch"
}

Function ApplyBuildPolicy([uri]$policyUrl, [guid]$repoId) {
    # JSON for setting required build policy
    $JSONBody = @"
{
    "isEnabled": true,
    "isBlocking": true,
    "type": {
    "id": ""
    },
    "settings": {
    "buildDefinitionId": buildID,
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
    $resp = Invoke-RestMethod -Uri $policyUrl -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    write-host "Build Policy set on branch: $branch"
}

Function ApplyWorkItemPolicy([uri]$policyUrl, [guid]$repoId) {
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
    $resp = Invoke-RestMethod -Uri $policyUrl -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    write-host "Required Work Item Policy set on branch: $branch"
}

Function ApplyCommentPolicy([uri]$policyUrl, [guid]$repoId) {
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
    $resp = Invoke-RestMethod -Uri $policyUrl -Method Post -ContentType application/json -Body $JSONBody -Headers $headers 
    write-host "Resolved Comment Policy set on branch: $branch"
}

# Retrieve list of all repositories
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
$headers = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept"        = "application/json"
}

$projectsResponse = Invoke-WebRequest -Headers $headers -Uri ("{0}/_apis/projects?api-version=1.0" -f $url)
$projects = convertFrom-JSON $projectsResponse.Content
foreach ($project in $projects.value) {
    [uri] $projectUrl = ("{0}/{1}" -f $url, $project.name)
    [uri] $policyUri = ("{0}/_apis/policy/configurations?api-version=5.0" -f $projectUrl) 

    $policies = GetPolicies $policyUri
    Try {
        #DeleteAllPolicies $policyUri $projectUrl
        $repos = GetRepos($projectUrl)
        foreach ($repo in $repos.value) {
            ApplyMinimumApproverPolicy $policyUri $repo.id
            #ApplyRequiredReviewerPolicy $policyUri $repo.id
            #ApplyBuildPolicy $policyUri $repo.id
            ApplyWorkItemPolicy $policyUri $repo.id
            ApplyCommentPolicy $policyUri  $repo.id
        }
    }
    Catch {
        $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        write-host $responseBody
    }
    Finally {
        # Clear global variable to cleanup 
    }

}
