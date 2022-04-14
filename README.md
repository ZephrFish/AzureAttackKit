# AzureAttackKit
Collection of Azure Tools to Pull down for Attacking an Env from a windows machine or Cloudshell. 

## Pre-Requisites
Git for Windows if you want to auto pull down the latest versions of everything via powershell.

## Setup
Setup.ps1 contains the following lines to install the required modules to access azure and the various assocated modules. 
```
Install-Module Az -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module AzureAD -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module Microsoft.Graph -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module MSOnline -Force -Confirm -AllowClobber -Scope CurrentUser       
Install-Module AzureADPreview -Force -Confirm -AllowClobber -Scope CurrentUser 
Install-Module AADInternals -Force -Confirm -AllowClobber -Scope CurrentUser   

Import-Module Az
Import-Module AzureAD
```

Once the modules are installed you will need to connect an Azure account using the following three commands (if you're on Cloudshell use Connect-AzAccount -UseDeviceAuthentication): 
## Setup:
`. .\Setup.ps1`
`Connect-ADandAZ`

If the above fails run the following:
``` 
Connect-AzAccount
Connect-AzureAD
Connect-MSolService
```

## Included Tools
- PowerZure + Cloudshell
- AzureHound
- AzureRT
- MicroBurst
- AADInternals

