<#
.SYNOPSIS
Create a fresh DC and fill it with realistic user objects for testing
Written by Adam Rice
Version 0.1
Last Updated Mar 24 2024

.LINK
https://randomuser.me/
https://github.com/resumex/Make-A-DC/

.DESCRIPTION
Installs server roles and performs a DC promo, then queries randomuser.me to generate user information and creates an Active Directory user based on each of those results.

.PARAMETER DomainName
Specify the name of the domain to create

.PARAMETER NumUsers
Specify the number of users to create

.PARAMETER CompanyName
Specify the company name to be used in the AD users' profile

.PARAMETER Nationalities
Specify the nationality of the users you are creating. randomuser.me relies on this for correct address formatting.

.INPUTS
System.String, System.Int32

.OUTPUTS
CSV with the creation results; Active Directory user account; temporary scheduled task (Insert-Users)

.EXAMPLE
PS C:\>: Make-A-DC.ps1 -domain test.local
Installs the required AD roles on the local machine, creating a DC for the domain test.local

.EXAMPLE
PS C:\>: Make-A-DC.ps1 -NumUsers 22
Created 22 random users and inserts them into the domain of localhost.

.EXAMPLE
PS C:\>: Make-A-DC.ps1 -NumUsers 18 -CompanyName "Apple Computer" -domain "Test.local"
Creates the test.local domain, then creates 18 random user accounts with Apple Computer as the Company Name under the Organization user attribute.

#>

[CmdletBinding()]
    param(

    [Parameter(HelpMessage="Specify the Domain Name to create, leave blank if domain already exists.")]
    [Alias("domain")]
    [AllowEmptyString()]
    [String]$DomainName,

    [Parameter(HelpMessage="Specify the number of users to create")]
    [Alias("users")]
    [ValidateRange(1,1000)]
    [int]$NumUsers,
    
    [Parameter(HelpMessage="Specify the company name")]
    [Alias("co")]
    [string]$CompanyName = "Evil-Corp",
    
    [Parameter(HelpMessage="Specify the users' nationalities")]
    [Alias("nat")]
    [string]$Nationalities = "US"
    )
Function script:Set-Domain {
    if (-not ([string]::IsNullOrEmpty($DomainName)))
{
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
        -NoRebootOnCompletion:$True

    # Create a scheduled task for the next user logon
    # The script will re-run at logon without the domain parameter, while retaining the other parameter values specified during the initial run.
    $action = New-ScheduledTaskAction -Execute 'Powershell' -WorkingDirectory "$PWD" -Argument "-File Make-A-DC.ps1 -users $NumUsers -co $CompanyName -nat $Nationalities"
    $trigger = New-ScheduledTaskTrigger -AtLogon 
    $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName Insert-Users -Trigger $trigger -Action $action -Principal $principal
    Restart-Computer -Force
}
else {
    Write-Host "Domain Name not specified, assuming domain already exists..."
 }
    } #End Set-Domain


Function script:Set-Environment {
$RandomUsersArr = New-Object System.Collections.ArrayList
$Date = (Get-Date -Format (Get-Culture).DateTimeFormat.ShortDatePattern) -replace '/','.'
#$DesktopPath = [Environment]::GetFolderPath("Desktop")
  Try {
    Import-Module ActiveDirectory -ErrorAction Stop
  }
  Catch [Exception] {
    Return $_.Exception.Message
  }

  $DomainInfo = Get-ADDomain -Current LocalComputer
  $UsersOU=$DomainInfo.UsersContainer #Creates users in the Users container by default
  $UPNSuffix = "@" + $DomainInfo.DNSRoot
} #End Set-Environment



Function script:Get-UserData {
  Try {
    $RandomUsers = Invoke-RestMethod "https://www.randomuser.me/api/?results=$NumUsers&nat=$Nationalities" | Select-Object -ExpandProperty Results
  }
  Catch [Exception] {
    Return $_.Exception.Message
  }
} #End Get-Users



Function script:Format-Passwords {
# Use Membership.GeneratePassword to create an ugly password that meets default complexity requirements for modern Windows Server OS's. 
# Variables can be modified as desired to increase/decrease complexity
Add-Type -AssemblyName 'System.Web'
$minLength = 16 ## characters
$maxLength = 24 ## characters
$length = Get-Random -Minimum $minLength -Maximum $maxLength ## Generates a random password length between $minLength and $maxLength
$nonAlphaChars = 5 ## number of non-alphanumeric characters to include. This could just as easily be randomized, but ¯\_(ツ)_/¯
$Password = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
$script:PlainTextPW = @{ #Snag the plaintext password for later use
    "PlainTextPW" = $Password
  }
  Return $Password | ConvertTo-SecureString -AsPlainText -Force #Convert $Password to SecureString for passing to New-ADUser
} #End Format-Passwords


##########################
##The doing stuff phase ##
##########################
. Set-Domain
. Set-Environment
. Get-UserData

ForEach ($RandomUser in $RandomUsers) {
  $First = $RandomUser.Name.First.Substring(0,1).ToUpper()+$RandomUser.Name.First.Substring(1).ToLower()
  $Last = $RandomUser.Name.Last.Substring(0,1).ToUpper()+$RandomUser.Name.Last.Substring(1).ToLower()
  $UserProperties = @{
  "GivenName" = $First
  "Surname" = $Last
  "Name" = $First + " " + $Last
  "DisplayName" = $First + " " + $Last
  "OfficePhone" = $RandomUser.Phone
  "City" = $RandomUser.Location.City
  "State" = $RandomUser.Location.State
  "Country" = $RandomUser.nat
  "Company" = $CompanyName
  "postalCode" = $RandomUser.Location.postcode
  "SAMAccountName" = $First[0] + $Last
  "UserPrincipalName" = $First[0] + $Last + $UPNSuffix
  "AccountPassword" = . Format-Passwords
  "Enabled" = $True
  "ChangePasswordAtLogon" = $False
  "Description" = "Test Account Generated $Date by $env:username"
  "Path" = $UsersOU
  }

  New-ADUser @UserProperties
  $UserPropertiesObj = New-Object PSObject -Property $UserProperties
  $UserPropertiesObj | Add-Member $PlainTextPW
  $RandomUsersArr.Add($UserPropertiesObj) | Out-Null #Add the object to the array

} #End ForEach

Unregister-ScheduledTask -TaskName Insert-Users -Confirm:$false
$RandomUsersArr | Export-CSV $PWD\Users.csv -Append -NoTypeInformation
