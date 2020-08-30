$baseUrl = "https://extmgmt.dev.azure.com"
$Org = "https://chrisNewSig.visualstudio.com/"
$Proj = "newProj"
$Username = "chris.ayers@newsignature.com"
$PAT = ""


$PAT | az devops login --org $Org

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$path = "$ScriptDirectory\extensions.csv";
$csv = Import-Csv -path $path
foreach ($line in $csv) { 
    $publisherName = $line.PublisherName;
    $extensionName = $line.ExtensionName;

    az devops extension install --org $Org --publisher-name $publisherName --extension-name $extensionName
}
