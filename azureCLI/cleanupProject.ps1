
param(
    [String]$filePath
)

#get input params

if (!$filePath) {
    Write-Host("`nFile input not provided so switching the script to interactive mode to ask default parameters.")
    $org = "https://dev.azure.com/CliDemo" # Read-host("`nOrganization URL ")
    $projectName = Read-host("Project Name ")
  
    Write-Host("`nThanks for providing all the required details. Now just sit back and relax, script is in action now . . . ")
}
else {
    $values = Get-Content $filePath | Out-String | ConvertFrom-StringData
    $org = $values.org
    $projectName = $values.projectName
  
    Write-Host("`nAll the required parameters are read from file at $($filePath)  Now just sit back and relax, script is in action now . . . ")
}

function deleteProject{
    param(
        [String]$org,
        [String]$projectName
    )

    $project = az devops project show  --organization $org -p $projectName -o json | ConvertFrom-Json
    if($project)
    {
        Write-Host "`nDeleting project with name $($projectName) . . . " 
        az devops project delete --org $org --id $project.id -y
        Write-Host "Deleted project with name $($project.name) and Id $($project.id)"
    }
    return $project.id
}


deleteProject $org $projectName