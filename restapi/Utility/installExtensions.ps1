$Org = "https://chrisNewSig.visualstudio.com/"
$PAT = ""


$PAT | az devops login --org $Org

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$path = "$ScriptDirectory\extensions.csv";
$csv = Import-Csv -path $path
foreach ($line in $csv) { 
    $publisherName = $line.PublisherName;
    $extensionName = $line.ExtensionName;

    az devops extension install --org $Org --publisher-id $publisherName --extension-id $extensionName
}
