@{
    Severity = @(
        'Error'
        'Warning'
    )

    ExcludeRules = @(
        # WETT is an interactive console application.
        # Write-Host is intentional for menus, headings, and colors.
        'PSAvoidUsingWriteHost'
    )
}
