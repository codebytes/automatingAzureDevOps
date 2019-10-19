# region Include required files
#
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    . ("$ScriptDirectory\DevOpsFunctions.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}
#endregion

$baseDir = "c:\git\incomm"
$devOpsOrg = "incommas"
$username = "chris.ayers@newsignature.com"
$personalAccessToken = ""

$projectName = "IAS"
$branch = "master"
$projectUrl = ("https://dev.azure.com/{0}/{1}" -f $devOpsOrg, $projectName)
[uri] $policyUri = ("{0}/_apis/policy/configurations?api-version=5.1" -f $projectUrl) 

$originalDir = Get-Location

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $personalAccessToken)))
$headers = @{
    "Authorization" = ("Basic {0}" -f $base64AuthInfo)
    "Accept"        = "application/json"
}

$path = "$ScriptDirectory\naming.csv";
$csv = Import-Csv -path $path -Header TFSPath, GitRepo

foreach ($line in $csv) { 
    $tfsPath = $line.TFSPath;
    $gitRepo = $line.GitRepo;
    
    Set-Location -Path "$baseDir" -PassThru

    #clone TFS
    git tfs clone https://dev.azure.com/$devOpsOrg $tfsPath $gitRepo
        
    Set-Location -Path "$baseDir/$gitRepo" -PassThru
        
    #add .gitignore
    Get-GitIgnore visualstudio
        
    #remove files already in git that shouldbe ignored
    git rm -r --cached .
    git add -A
    git commit -am 'Removing ignored files'
        
    #create pipeline file
    CreateSampleAzurePipelineYML 'azure-pipelines.yml'
    git add 'azure-pipelines.yml'
    git commit -m "Added Azure Pipeline build"
        
    #create git repo and push
    $newRepo = CreateRepo $projectUrl $gitRepo $headers
    git remove rm origin
    git remote add origin $newRepo.remoteUrl
    git push -u origin --all
        
    #create build definition and queue a build
    $buildDef = CreateYamlBuildDefinition $projectUrl $newRepo.id $gitRepo $headers
    Start-Build $projectUrl $buildDef.id $headers
        
    #set Policies
    ApplyBuildPolicy $policyUri $newRepo.id $branch $buildDef.id $headers
    ApplyMinimumApproverPolicy $policyUri $newRepo.id $branch 1 $headers
        
    Set-Location $originalDir -PassThru
        
    
} 

