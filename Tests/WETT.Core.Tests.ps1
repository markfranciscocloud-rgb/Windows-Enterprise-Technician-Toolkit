BeforeAll {
    $root = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $root 'Modules/WETT.Core.psm1') -Force
    Initialize-WETTEnvironment -RootPath $root
}

Describe 'WETT repository foundation' {
    It 'contains the main launcher' {
        Test-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'WETT.ps1') | Should -BeTrue
    }

    It 'contains required module files' {
        $root = Split-Path -Parent $PSScriptRoot
        @(
            'WETT.Core.psm1',
            'WETT.System.psm1',
            'WETT.Network.psm1',
            'WETT.Security.psm1',
            'WETT.Reporting.psm1'
        ) | ForEach-Object {
            Test-Path (Join-Path $root "Modules/$_") | Should -BeTrue
        }
    }

    It 'creates Logs and Reports directories' {
        $root = Split-Path -Parent $PSScriptRoot
        Test-Path (Join-Path $root 'Logs') | Should -BeTrue
        Test-Path (Join-Path $root 'Reports') | Should -BeTrue
    }

    It 'returns a toolkit context object' {
        $context = Get-WETTContext
        $context.Version | Should -Be '0.1.0'
        $context.SafeMode | Should -BeTrue
    }
}
