function New-Project-Base {
    param([String]$name)
    New-Item -ItemType Directory -Force -Path src
    New-Item -ItemType Directory -Force -Path tests
    dotnet new globaljson 
    dotnet new gitignore
    dotnet new sln -n $name
}

function New-DotNet-WebApi-Application {
    param(
        [String]$name,
        [String]$slnName
    )
    dotnet new webapi -n "$name" -o "src\$name"
    dotnet new mstest -n "$name.Tests" -o "tests\$name.Tests"
    dotnet add "tests\$name.Tests" package coverlet.collector
    dotnet sln $slnName add "src\$name"
    dotnet sln $slnName add "tests\$name.Tests"
}

function New-DotNet-Console-Application {
    param(
        [String]$name,
        [String]$slnName
    )
    dotnet new console -n "$name" -o "src\$name"
    dotnet new mstest -n "$name.Tests" -o "tests\$name.Tests"
    dotnet add "tests\$name.Tests" package coverlet.collector
    dotnet sln $slnName add "src\$name"
    dotnet sln $slnName add "tests\$name.Tests"
}

$name = "testProj"
New-Item -ItemType Directory -Force -Path $name
Push-Location $name
New-Project-Base $name
New-DotNet-WebApi-Application "$name.Api"
Pop-Location
