function Run-Debloat-Script {
    param (
        $script
    )
    $debloat_scripts_path = "C:\setup-scripts\debloat\scripts\"
    & ($debloat_scripts_path + $script + ".ps1")
}

Set-ExecutionPolicy -Force -ExecutionPolicy Bypass -Scope Process

Run-Debloat-Script remove-default-apps
Run-Debloat-Script remove-default-apps
Run-Debloat-Script block-telemetry
Run-Debloat-Script fix-privacy-settings
Run-Debloat-Script disable-services
Run-Debloat-Script optimize-user-interface


C:\ProgramData\chocolatey\bin\choco.exe install -y microsoft-windows-terminal

Remove-Item -Recurse -Force C:\Users\Public\Desktop\*
Remove-Item -Recurse -Force C:\Users\admin\Desktop\*
