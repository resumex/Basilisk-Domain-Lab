Function Set-Environment {
    $RandomUsersArr = New-Object System.Collections.ArrayList
    $Date = (Get-Date -Format (Get-Culture).DateTimeFormat.ShortDatePattern) -replace '/', '.'
    Try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    Catch [Exception] {
        Return $_.Exception.Message
    }
    
    $DomainInfo = Get-ADDomain -Current LocalComputer
    $UsersOU = $DomainInfo.UsersContainer #Creates users in the Users container by default
    $UPNSuffix = "@" + $DomainInfo.DNSRoot
} #End Set-Environment

Function Format-Passwords {
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

Function Get-UserData {
    Try {
        $RandomUsers = Invoke-RestMethod "https://www.randomuser.me/api/?results=$NumUsers&nat=$Nationalities" | Select-Object -ExpandProperty Results
    }
    Catch [Exception] {
        Return $_.Exception.Message
    }
} #End Get-Users
    
Function Remove-Task {
    try {
        Unregister-ScheduledTask -TaskName Insert-Users -Confirm:$false -ErrorAction SilentlyContinue
    }
    catch [Exception] {
        Return $_.Exception.Message
    }
    
}

Function Set-RandomUsers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]    
        [Alias("users", "num")]
        [ValidateRange(1, 1000)]
        [int]$NumUsers,
        
        [Alias("company", "co")]
        [string]$CompanyName = "Evil-Corp",
        
        [Alias("nat", "nationality")]
        [string]$Nationalities = "US"
    )
    ##########################
    ##The doing stuff phase ##
    ##########################
    . Set-Environment
    . Get-UserData
    . Remove-Task *> $null

    ForEach ($RandomUser in $RandomUsers) {
        $First = $RandomUser.Name.First.Substring(0, 1).ToUpper() + $RandomUser.Name.First.Substring(1).ToLower()
        $Last = $RandomUser.Name.Last.Substring(0, 1).ToUpper() + $RandomUser.Name.Last.Substring(1).ToLower()
        $UserProperties = @{
            "GivenName"             = $First
            "Surname"               = $Last
            "Name"                  = $First + " " + $Last
            "DisplayName"           = $First + " " + $Last
            "OfficePhone"           = $RandomUser.Phone
            "City"                  = $RandomUser.Location.City
            "State"                 = $RandomUser.Location.State
            "Country"               = $RandomUser.nat
            "Company"               = $CompanyName
            "postalCode"            = $RandomUser.Location.postcode
            "SAMAccountName"        = $First + "." + $Last
            "UserPrincipalName"     = $First + "." + $Last + $UPNSuffix
            "AccountPassword"       = . Format-Passwords
            "Enabled"               = $True
            "ChangePasswordAtLogon" = $False
            "Description"           = "Test Account Generated $Date by $env:username"
            "Path"                  = $UsersOU
        }
    
        New-ADUser @UserProperties
        $UserPropertiesObj = New-Object PSObject -Property $UserProperties
        $UserPropertiesObj | Add-Member $PlainTextPW
        $RandomUsersArr.Add($UserPropertiesObj) | Out-Null #Add the object to the array
        $RandomUsersArr | Export-CSV $PWD\Users.csv -Append -NoTypeInformation
    } #End ForEach
}
    