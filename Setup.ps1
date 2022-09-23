# Setup AzureAttackKit
# Authors: Andy Gill (@ZephrFish)

# Setup Modules
Install-Module Az -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module AzureAD -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module Microsoft.Graph -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module MSOnline -Force -Confirm -AllowClobber -Scope CurrentUser       
Install-Module AzureADPreview -Force -Confirm -AllowClobber -Scope CurrentUser 
Install-Module AADInternals -Force -Confirm -AllowClobber -Scope CurrentUser   

Import-Module Az
Import-Module AzureAD

# Connect Accounts
Function Connect-ADandAZ {
    <# 
      .SYNOPSIS
        Connects Both AzureAD and Azure but checks if you're in a cloudshell first!
      .DESCRIPTION
        Invokes Connect-AzAccount to authenticate current session to the Azure Portal via provided Access Token or credentials.
        Skips the burden of providing Tenant ID and Account ID by automatically extracting those from provided Token.
        Invokes Connect-AzureAD (and Connect.MgGraph if module is installed) to authenticate current session to the Azure AD via provided Access Token or credentials.
        Skips the burden of providing Tenant ID and Account ID by automatically extracting those from provided Token.
    #>

    Connect-ART
    Connect-ARTAD
}

# Modules stolen from AzureRT
Function Connect-ART {
    <#
    .SYNOPSIS
        Connects to the Azure.
    .DESCRIPTION
        Invokes Connect-AzAccount to authenticate current session to the Azure Portal via provided Access Token or credentials.
        Skips the burden of providing Tenant ID and Account ID by automatically extracting those from provided Token.
    .PARAMETER AccessToken
        Specifies JWT Access Token for the https://management.azure.com resource.
    .PARAMETER GraphAccessToken
        Optional access token for Azure AD service (https://graph.microsoft.com).
    .PARAMETER KeyVaultAccessToken 
        Optional access token for Key Vault service (https://vault.azure.net).
    .PARAMETER SubscriptionId
        Optional parameter that specifies to which subscription should access token be acquired.
    .PARAMETER TokenFromAzCli
        Use az cli to acquire fresh access token.
    .PARAMETER Username
        Specifies Azure portal Account name, Account ID or Application ID.
    .PARAMETER Password
        Specifies Azure portal password.
    .PARAMETER TenantId
        When authenticating as a Service Principal, the Tenant ID must be specifed.
    .PARAMETER Credential
        PS Credential object containing principal credentials to connect with.
    .EXAMPLE
        Example 1: Authentication as a user to the Azure via Access Token:
        PS> Connect-Things -AccessToken 'eyJ0eXA...'
        
        Example 2: Authentication as a user to the Azure via Credential:
        PS> Connect-Things -Username test@test.onmicrosoft.com -Password Foobar123%
        Example 3: Authentication as a user to the Azure via Credential object:
        PS> Connect-Things -Credential $creds
        Example 4: Authentication as a Service Principal using added Application Secret:
        PS> Connect-Things -ServicePrincipal -Username f072c4a6-e696-11eb-b57b-00155d01ef0d -Password 'agq7Q~UZX5SYwxq2O7FNW~C_S1QNJcJrlLu.E' -TenantId b423726f-108d-4049-8c11-d52d5d388768
    #>

    [CmdletBinding(DefaultParameterSetName = 'Token')]
    Param(
        [Parameter(Mandatory=$False, ParameterSetName = 'Token')]
        [String]
        $AccessToken = $null,

        [Parameter(Mandatory=$False, ParameterSetName = 'Token')]
        [String]
        $GraphAccessToken = $null,

        [Parameter(Mandatory=$False, ParameterSetName = 'Token')]
        [String]
        $KeyVaultAccessToken = $null,

        [Parameter(Mandatory=$False, ParameterSetName = 'Token')]
        [String]
        $SubscriptionId = $null,

        [Parameter(Mandatory=$False, ParameterSetName = 'Token')]
        [Switch]
        $TokenFromAzCli,

        [Parameter(Mandatory=$True, ParameterSetName = 'Credentials')]
        [String]
        $Username = $null,

        [Parameter(Mandatory=$True, ParameterSetName = 'Credentials')]
        [String]
        $Password = $null,

        [Parameter(Mandatory=$False, ParameterSetName = 'Credentials')]
        [Switch]
        $ServicePrincipal,

        [Parameter(Mandatory=$False, ParameterSetName = 'Credentials')]
        [String]
        $TenantId,

        [Parameter(Mandatory=$True, ParameterSetName = 'Credentials2')]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    try {
        $EA = $ErrorActionPreference
        $ErrorActionPreference = 'silentlycontinue'

        if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
            Write-Verbose "Az Powershell module not installed or not loaded. Installing it..."
            Install-Module -Name Az -Force -Confirm -Scope CurrentUser -AllowClobber
        }

        if($PsCmdlet.ParameterSetName -eq "Token" -and ($AccessToken -eq $null -or $AccessToken -eq "")) {
            if($TokenFromAzCli) {
                Write-Verbose "Acquiring Azure access token from az cli..."
                $AccessToken = Get-ARTAccessTokenAzCli -Resource https://management.azure.com
                $KeyVaultAccessToken = Get-ARTAccessTokenAzCli -Resource https://vault.azure.net
            }
            else {
                Write-Verbose "Acquiring Azure access token from Connect-AzAccount..."
                $AccessToken = Get-ARTAccessTokenAz -Resource https://management.azure.com
                $KeyVaultAccessToken = Get-ARTAccessTokenAz -Resource https://vault.azure.net
            }
        }

        if($AccessToken -ne $null -and $AccessToken.Length -gt 0) {
            Write-Verbose "Azure authentication via provided access token..."
            $parsed = Parse-JWTtokenRT $AccessToken
            $tenant = $parsed.tid

            if(-not ($parsed.aud -like 'https://management.*')) {
                Write-Warning "Provided JWT Access Token is not scoped to https://management.azure.com or https://management.core.windows.net! Instead its scope is: $($parsed.aud)"
            }

            if ([bool]($parsed.PSobject.Properties.name -match "upn")) {
                Write-Verbose "Token belongs to a User Principal."
                $account = $parsed.upn
            }
            elseif ([bool]($parsed.PSobject.Properties.name -match "unique_name")) {
                Write-Verbose "Token belongs to a User Principal."
                $account = $parsed.unique_name
            }
            else {
                Write-Verbose "Token belongs to a Service Principal."
                $account = $parsed.appId
            }

            $headers = @{
                'Authorization' = "Bearer $AccessToken"
            }

            $params = @{
                'AccessToken' = $AccessToken
                'Tenant' = $tenant
                'AccountId' = $account
            }

            if($SubscriptionId -eq $null -or $SubscriptionId.Length -eq 0) {

                $SubscriptionId = Get-ARTSubscriptionId -AccessToken $AccessToken
                
                if(-not ($SubscriptionId -eq $null -or $SubscriptionId.Length -eq 0)) {
                    $params["SubscriptionId"] = $SubscriptionId
                }
                else {
                    Write-Warning "Could not acquire Subscription ID! Resulting access token may be corrupted!"
                }
            }
            else {
                $params["SubscriptionId"] = $SubscriptionId
            }

            if ($KeyVaultAccessToken -ne $null -and $KeyVaultAccessToken.Length -gt 0) {
                $parsedvault = Parse-JWTtokenRT $KeyVaultAccessToken

                if(-not ($parsedvault.aud -eq 'https://vault.azure.net')) {
                    Write-Warning "Provided JWT Key Vault Access Token is not scoped to `"https://vault.azure.net`"! Instead its scope is: `"$($parsedvault.aud)`" . That will not work!"
                }

                $params["KeyVaultAccessToken"] = $KeyVaultAccessToken
            }

            if ($GraphAccessToken -ne $null -and $GraphAccessToken.Length -gt 0) {
                $parsedgraph = Parse-JWTtokenRT $GraphAccessToken

                if(-not ($parsedgraph.aud -match 'https://graph.*')) {
                    Write-Warning "Provided JWT Graph Access Token is not scoped to `"https://graph.*`"! Instead its scope is: `"$($parsedgraph.aud)`" . That will not work!"
                }

                $params["GraphAccessToken"] = $GraphAccessToken
            }

            $command = "Connect-AzAccount"

            foreach ($h in $params.GetEnumerator()) {
                $command += " -$($h.Name) '$($h.Value)'"
            }

            Write-Verbose "Command:`n$command`n"
            iex $command

            if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
                Parse-JWTtokenRT $AccessToken
            }
        }
        elseif (($PsCmdlet.ParameterSetName -eq "Credentials2") -and ($Credentials -ne $null)) {
            if($ServicePrincipal) {

                $Username = $Credentials.UserName

                if(-not ($Username -match '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')) {
                    throw "Service Principal Username must follow a GUID scheme!"
                }

                Write-Verbose "Azure authentication via provided Service Principal PSCredential object..."

                if($TenantId -eq $null -or $TenantId.Length -eq 0) {
                    throw "Tenant ID not provided! Pass it in -TenantId parameter."
                }

                Connect-AzAccount -Credential $Credentials -ServicePrincipal -Tenant $TenantId

            } Else {
                Write-Verbose "Azure authentication via provided PSCredential object..."
                Connect-AzAccount -Credential $Credentials
            }
        }
        else {
            $passwd = ConvertTo-SecureString $Password -AsPlainText -Force
            $creds = New-Object System.Management.Automation.PSCredential ($Username, $passwd)

            if($ServicePrincipal) {

                if(-not ($Username -match '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')) {
                    throw "Service Principal Username must follow a GUID scheme!"
                }

                Write-Verbose "Azure authentication via provided Service Principal creds..."

                if($TenantId -eq $null -or $TenantId.Length -eq 0) {
                    throw "Tenant ID not provided! Pass it in -TenantId parameter."
                }

                Connect-AzAccount -Credential $creds -ServicePrincipal -Tenant $TenantId

            } Else {
                Write-Verbose "Azure authentication via provided User creds..."
                Connect-AzAccount -Credential $creds
            }
        }
    }
    catch {
        Write-Host "[!] Function failed!" -ForegroundColor Red
        Throw
        Return
    }
    finally {
        $ErrorActionPreference = $EA
    }
}

Function Connect-ARTAD {
    <#
    .SYNOPSIS
        Connects to the Azure AD and Microsoft.Graph
    .DESCRIPTION
        Invokes Connect-AzureAD (and Connect.MgGraph if module is installed) to authenticate current session to the Azure AD via provided Access Token or credentials.
        Skips the burden of providing Tenant ID and Account ID by automatically extracting those from provided Token.
    .PARAMETER AccessToken
        Specifies JWT Access Token for the https://graph.microsoft.com or https://graph.windows.net resource.
    .PARAMETER TokenFromAzCli
        Use az cli to acquire fresh access token.
    .PARAMETER Username
        Specifies Azure AD username.
    .PARAMETER Password
        Specifies Azure AD password.
    .PARAMETER Credential
        PS Credential object containing principal credentials to connect with.
    .EXAMPLE
        PS> Connect-ARTAD -AccessToken 'eyJ0eXA...'
        PS> Connect-ARTAD -Credential $creds
        PS> Connect-ARTAD -Username test@test.onmicrosoft.com -Password Foobar123%
    #>

    [CmdletBinding(DefaultParameterSetName = 'Token')]
    Param(
        [Parameter(Mandatory=$False, ParameterSetName = 'Token')]
        [String]
        $AccessToken = $null,

        [Parameter(Mandatory=$False, ParameterSetName = 'Token')]
        [Switch]
        $TokenFromAzCli,

        [Parameter(Mandatory=$True, ParameterSetName = 'Credentials')]
        [String]
        $Username = $null,

        [Parameter(Mandatory=$True, ParameterSetName = 'Credentials')]
        [String]
        $Password = $null,

        [Parameter(Mandatory=$True, ParameterSetName = 'Credentials2')]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    try {
        $EA = $ErrorActionPreference
        $ErrorActionPreference = 'silentlycontinue'

        if (-not (Get-Module -ListAvailable -Name AzureAD)) {
            Write-Verbose "AzureAD Powershell module not installed or not loaded. Installing it..."
            Install-Module -Name AzureAD -Force -Confirm -Scope CurrentUser -AllowClobber
        }

        if($PsCmdlet.ParameterSetName -eq "Token" -and ($AccessToken -eq $null -or $AccessToken -eq "")) {
            Write-Verbose "Acquiring Azure access token from Connect-AzureAD..."
            if($TokenFromAzCli) {
                Write-Verbose "Acquiring Azure access token from az cli..."
                $AccessToken = Get-ARTAccessTokenAzCli -Resource https://graph.microsoft.com
            }
            else {
                Write-Verbose "Acquiring Azure access token from Connect-AzAccount..."
                $AccessToken = Get-ARTAccessTokenAz -Resource https://graph.microsoft.com
            }
        }

        if($AccessToken -ne $null -and $AccessToken.Length -gt 0) {
            Write-Verbose "Azure AD authentication via provided access token..."
            $parsed = Parse-JWTtokenRT $AccessToken
            $tenant = $parsed.tid

            if(-not $parsed.aud -like 'https://graph.*') {
                Write-Warning "Provided JWT Access Token is not scoped to https://graph.microsoft.com or https://graph.windows.net! Instead its scope is: $($parsed.aud)"
            }

            if ([bool]($parsed.PSobject.Properties.name -match "upn")) {
                Write-Verbose "Token belongs to a User Principal."
                $account = $parsed.upn
            }
            elseif ([bool]($parsed.PSobject.Properties.name -match "unique_name")) {
                Write-Verbose "Token belongs to a User Principal."
                $account = $parsed.unique_name
            }
            else {
                Write-Verbose "Token belongs to a Service Principal."
                $account = $parsed.appId
            }

            Connect-AzureAD -AadAccessToken $AccessToken -TenantId $tenant -AccountId $account

            if(Get-Command Connect-MgGraph) {
                Connect-MgGraph -AccessToken $AccessToken
            }

            if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
                Parse-JWTtokenRT $AccessToken
            }
        }
        elseif (($PsCmdlet.ParameterSetName -eq "Credentials2") -and ($Credentials -ne $null)) {
            Write-Verbose "Azure AD authentication via provided PSCredential object..."
            Connect-AzureAD -Credential $Credentials
        }
        else {
            $passwd = ConvertTo-SecureString $Password -AsPlainText -Force
            $creds = New-Object System.Management.Automation.PSCredential ($Username, $passwd)
            
            Write-Verbose "Azure AD authentication via provided creds..."
            Connect-AzureAD -Credential $creds
        }
    }
    catch {
        Write-Host "[!] Function failed!" -ForegroundColor Red
        Throw
        Return
    }
    finally {
        $ErrorActionPreference = $EA
    }
}

Connect-ADandAZ