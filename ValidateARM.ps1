param (
    [Parameter(Mandatory = $true)]
    [string]$TemplatePath,
    [Parameter(Mandatory = $false)]
    [string]$TemplateParametersPath
)

$templateARM = Get-Content $TemplatePath -Raw -ErrorAction SilentlyContinue
$templateParameterARM = Get-Content $TemplateParametersPath -Raw -ErrorAction SilentlyContinue
$template = ConvertFrom-Json -InputObject $templateARM -ErrorAction SilentlyContinue
$templateParameters = ConvertFrom-Json -InputObject $templateParameterARM -ErrorAction SilentlyContinue
$templateElements = $template.psobject.Properties.name.tolower()

Describe 'ARM Template Validation' {
    Context 'ARM File Validation' {
        It 'Template ARM File Exists' {
            Test-Path $TemplatePath -Include '*.json' | Should Be $true
        }

        It 'Is a valid JSON file' {
            $templateARM | ConvertFrom-Json -ErrorAction SilentlyContinue | Should Not Be $Null
        }
    }
    Context 'Parameter File Validation' {
        if ($TemplateParametersPath -ne $null) {
            It 'Template ARM File Exists' {
                Test-Path $TemplateParametersPath -Include '*.json' | Should Be $true
            }

            It 'Is a valid JSON file' {
                $templateParameterARM | ConvertFrom-Json -ErrorAction SilentlyContinue | Should Not Be $Null
            }
        }
    }
    
    Context 'Template Content Validation' {
        It "Contains all required elements" {
            $Elements = '$schema',
            'contentVersion',
            'outputs',
            'parameters',
            'resources'                                
            $templateProperties = $template | Get-Member -MemberType NoteProperty | % Name
            $templateProperties | Should Be $Elements
        }
    }
}