function createProject {
    param(
        [String]$org,
        [String]$projectName,
        [String]$process,
        [String]$sourceControl,
        [String]$visibility
    )


    Write-Host "`nCreating project with name $($projectName) . . . " 
    $project = az devops project create --org $org --name $projectName --process $process --source-control $sourceControl --visibility $visibility -o json | ConvertFrom-Json
    Write-Host "Created project with name $($project.name) and Id $($project.id)"
    return $project.id
}

function createRepo {
    param(
        [String]$org,
        [String]$projectID,
        [String]$repoName
    )

    Write-Host "`nCreating repository with name $($repoName) . . . " 
    $repo = az repos create --org $org -p $projectID --name $repoName -o json | ConvertFrom-Json
    Write-Host "Created repository with name $($repo.name) and Id $($repo.id)"
    return $repo
}
   
function templateRepo {
    param(
        [String]$repoUrl,
        [String]$repoPath,
        [String]$name
    )
    
    $originalDir = Get-Location

    git clone $repo.remoteUrl $repoPath
    Set-Location $repoPath
    New-Item -ItemType Directory -Force -Path src
    New-Item -ItemType Directory -Force -Path tests
    dotnet new globaljson 
    dotnet new gitignore
    dotnet new webapi -n "$name" -o "src\$name"
    dotnet new mstest -n "$name.Tests" -o "tests\$name.Tests"
    dotnet add "tests\$name.Tests" package coverlet.collector
    dotnet new sln -n $name
    dotnet sln $name.sln add "src\$name"
    dotnet sln $name.sln add "tests\$name.Tests"
    git add .
    git commit -m "initial import"
    git push
    New-Item -ItemType Directory -Force -Path pipelines
    Copy-Item (Join-Path $PSScriptRoot ..\Pipelines\sample-dotnet-pipelines.yml) (Join-Path pipelines azure-pipeslines.yml)
    git add .
    git commit -m "Standard Pipeline"
    git push

    Set-Location $originalDir
}

function createBuild {
    param(
        [String]$repoName,
        [String]$org,
        [String]$projectID
    )
    $build = az pipelines create --org $org -p $projectID --repository $repoName --name "$repoName Build" --repository-type tfsgit --yml-path "/pipelines/azure-pipeslines.yml" -o json | ConvertFrom-Json
    return $build
}

function importRepo {
    param(
        [String]$org,
        [String]$projectID,
        [String]$repoID,
        [String]$repoToImport,
        [String]$repoType
    )
    if ($repoToImport -and ($repoType -eq 'Public')) {
        Write-Host "`nImporting repository from url $($repoToImport)" 
        $importRepo = az repos import create --org $org -p $projectID -r $repoID --git-url $repoToImport -o json | ConvertFrom-Json
        Write-Host "Repo imported with Status $($importRepo.status)"
    }
    else {
        Write-Host "Private repo import failed!"
    }
}

function publishCodeWiki {
    param(
        [String]$org,
        [String]$projectID,
        [String]$repo,
        [String]$wikiName,
        [String]$path,
        [String]$wikiType,
        [String]$branch
    )
    if ($wikiType -eq 'codewiki' -and $path -and $branch) {
        $createCodeWiki = az devops wiki create --name $wikiName --type codewiki --version $branch --mapped-path $path -r $repo --org $org -p $projectID -o json | ConvertFrom-Json
        Write-Host "New code wiki published with ID : $($createCodeWiki.id)"
    }
    else {
        $createProjectWiki = az devops wiki create --name $wikiName --type projectwiki -org $org -p $projectID -o json | ConvertFrom-Json
        Write-Host "New project wiki created with ID : $($createProjectWiki.id)"
    }
}
