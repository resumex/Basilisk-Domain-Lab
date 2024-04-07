# Rice Domain Lab
Create a domain controller and fill it with realistic user objects based on https://randomuser.me/

The script will build a DC and continue running after the required reboot to fill the domain with users. Each component can be run separately.

## Instructions:

1. Clone repository
2. `Import-Module C:\path\to\RiceLab.psd1`

## Commands

### `Set-Domain`

#### Parameters - Required*

`domain`* - Specifies the name of the domain

`users` - Specifies the number of users to add to the domain

`company` - Specify the company name to be used in the AD users' profile

`nat` - Specify the nationality of the users you are creating. https://randomuser.me relies on this for correct address formatting. Default value is US

---

### `Set-RandomUsers`

#### Parameters - Required*

`users`* - Specifies the name of the domain

`company` - Specify the company name to be used in the AD users' profile

`nat` - Specify the nationality of the users you are creating. https://randomuser.me relies on this for correct address formatting. Default value is US

## Examples:

`PS C:\>: Import-Module .\RiceLab.psd1`

Imports the module into the current PowerShell session.

`PS C:\>: Set-RandomUsers -users 22`

Creates 22 random user accounts and inserts them into the domain of the localhost the script is running on.

`PS C:\>: Set-Domain -domain "Test.local" -users 18 -co "Apple Computer"`

Creates the `test.local` domain, then creates 18 random user accounts with `Apple Computer` as the Company Name under the `Organization` user attribute.

`PS C:\>: Set-Domain -domain test.local`

Installs the required AD roles on the local machine, creating a DC for the domain `test.local`, but will not create any users.
