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

$Org = "chrisNewSig"
$OrgUrl = "https://dev.azure.com/$($Org)"
$username = "chris.ayers@newsignature.com"
$PAT = ""
$rootFolder = "c:\agents"
$mycredu = "testaccount"
$mycredp = ConvertTo-SecureString "testaccount" -AsPlainText -Force

$headers = Get-Headers $username $PAT
$existingAgentPools = Get-AgentPools $Org $headers

#region prepare agent files
$AgentVersion = '2.174.1'
$AgentBase = 'c:\temp' 
$AgentFile = "vsts-agent-win-x64-$($AgentVersion).zip" 
$AgentFilePath = "$($AgentBase)\$AgentFile" 
$URI = "https://vstsagentpackage.azureedge.net/agent/$($AgentVersion)/$AgentFile" 
if (-not (Test-Path -Path $AgentFilePath)) { 
    mkdir -Path $AgentBase -Force -EA ignore 
    Invoke-WebRequest -uri $URI -OutFile $AgentFilePath -verbose 
} 
#endregion


$path = "$ScriptDirectory\buildAgents.csv";
$csv = Import-Csv -path $path
foreach ($line in $csv) { 
    $poolName = $line.PoolName;
    $agentName = $line.AgentName;

    if ($existingAgentPools  | Where-Object { $_.name -eq $poolName } ) {
        Write-Host $poolName "Exists"

        $AgentPath = "$($AgentBase)\$($agentName)" 
        Set-Location -Path $AgentBase 
        push-location
        mkdir -Path $AgentPath -EA ignore 
        Set-Location -Path $AgentPath 

        if (-not (Test-Path -Path .\config.cmd)) { 
            Add-Type -AssemblyName System.IO.Compression.FileSystem 
            #[System.IO.Compression.ZipFile]::ExtractToDirectory($using:AgentFilePath, $PWD) 
            [System.IO.Compression.ZipFile]::ExtractToDirectory($AgentFilePath, $PWD) 
            Write-Verbose -Message "Installing service [$ServiceName] setting as [$($agent.Ensure)]" -Verbose  
            .\config.cmd --pool $poolName --agent $agentName --auth pat --token $PAT --url $OrgUrl --acceptTeeEula `
                --unattended --runAsService  --windowsLogonAccount $mycredu --windowsLogonPassword $mycredp 
            Pop-Location 
        }
        else {
            Write-Verbose -Message "Removing service [$ServiceName] setting as [$($agent.Ensure)]" -Verbose  
            .\config.cmd remove --unattended --auth pat --token $PAT 
            Pop-Location 
            Remove-Item -path $AgentPath -force -recurse 
                                     
            New-LocalUser $mycredu -Password $mycredp -FullName $mycredu -Description "Description of the account" -UserMayNotChangePassword
            Add-LocalGroupMember -Group "Administrators" -Member $mycredu

            mkdir -Path $AgentPath -EA ignore 
            Set-Location -Path $AgentPath 
            Add-Type -AssemblyName System.IO.Compression.FileSystem 
            #[System.IO.Compression.ZipFile]::ExtractToDirectory($using:AgentFilePath, $PWD) 
            [System.IO.Compression.ZipFile]::ExtractToDirectory($AgentFilePath, $PWD) 
            Write-Verbose -Message "Installing service [$ServiceName] setting as [$($agent.Ensure)]" -Verbose  
            .\config.cmd --pool $poolName --agent $agentName --auth pat --token $PAT --url $OrgUrl --acceptTeeEula `
                --unattended --runAsService  --windowsLogonAccount $mycredu --windowsLogonPassword $mycredp 
            Pop-Location 
        }
    } 
}
