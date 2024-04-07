Function Set-Domain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias("domain")]
        [string]$DomainName,
 
        [Alias("users", "num")]
        [ValidateRange(1, 1000)]
        [int]$NumUsers,
        
        [Alias("company", "co")]
        [string]$CompanyName = "Evil-Corp",
        
        [Alias("nat", "nationality")]
        [string]$Nationalities = "US"
    )
    Add-Type -AssemblyName 'System.Web'
    $ErrorActionPreference = "Stop"
    $NetBios = $DomainName.Substring(0, $DomainName.IndexOf("."))
    $SafeModePass = [System.Web.Security.Membership]::GeneratePassword(24, 5)
    Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools;
    Import-Module ADDSDeployment;
    Install-ADDSForest `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainMode "Default" `
        -DomainName "$DomainName" `
        -DomainNetbiosName "$NetBios" `
        -ForestMode "Default" `
        -NoDnsOnNetwork `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -SafeModeAdministratorPassword (ConvertTo-SecureString "$SafeModePass" -AsPlainText -Force) `
        -SysVolPath "C:\Windows\SysVol" `
        -NoRebootOnCompletion:$True `
        -Force `
        -Verbose *> $null

    if ($Numusers -ne $null -and $variable -ne '') {
        # Create a scheduled task for the next user logon
        # The script will re-run at logon without the domain parameter, while retaining the other parameter values specified during the initial run.
        $action = New-ScheduledTaskAction -Execute 'Powershell' -WorkingDirectory "$PWD" -Argument "Import-Module $PWD\BasiliskLab.psd1; Set-RandomUsers -users $NumUsers -co $CompanyName -nat $Nationalities"
        $trigger = New-ScheduledTaskTrigger -AtLogon 
        $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Register-ScheduledTask -TaskName Insert-Users -Trigger $trigger -Action $action -Principal $principal
        Restart-Computer -Force
    }
    else {
        Restart-Computer -Force
    }
} #End Set-Domain
