# Basilisk Domain Lab
Create a domain controller and fill it with realistic user objects based on https://randomuser.me/

The module's functions will build a DC and continue running after the required reboot to fill the domain with users. Each component can be run separately to build a DC with no users or add users to an existing domain ad hoc.

## Instructions:

1. Clone repository
2. `Import-Module C:\path\to\BasiliskLab.psd1`

## Commands

### `Set-Domain`

Install and configure the Active Directory Domain Services roles, and make the current local machine a domain controller.

#### Parameters - Required*

`domain`* - Specifies the name of the domain

`users` - Specifies the number of users to add to the domain

`company` - Specify the company name to be used in the AD users' profile

`nat` - Specify the nationality of the users you are creating. https://randomuser.me relies on this for correct address formatting. Default value is US

---

### `Set-RandomUsers`

Insert a specified number of users into the domain. The names and some metadata of the users are randomly generated based on https://randomuser.me.

A CSV export of all users created will be placed in the current working directory.

#### Parameters - Required*

`users`* - Specifies the number of users to add to the domain

`company` - Specify the company name to be used in the AD users' profile

`nat` - Specify the nationality of the users you are creating. https://randomuser.me relies on this for correct address formatting. Default value is US

## Examples:

`PS C:\>: Import-Module .\BasiliskLab.psd1`

Imports the module into the current PowerShell session.

`PS C:\>: Set-RandomUsers -users 22`

Creates 22 random user accounts and inserts them into the domain of the localhost the script is running on.

`PS C:\>: Set-Domain -domain "Test.local" -users 18 -co "Apple Computer"`

Creates the `test.local` domain, then creates 18 random user accounts with `Apple Computer` as the Company Name under the `Organization` user attribute.

`PS C:\>: Set-Domain -domain test.local`

Installs the required AD roles on the local machine, creating a DC for the domain `test.local`, but will not create any users.
