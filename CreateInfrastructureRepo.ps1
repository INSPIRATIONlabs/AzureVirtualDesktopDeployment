# This is a script for Azure Cloud shell
# It will install the github cli if it is not installed
# It will create a new github repository
# It will create a new Azure AD application and Service Principal
# It will assign the Contributor role to the Service Principal
# It will set the federatedIdentityCredentials for the Azure AD application
# It will assign the AZURE_CLIENT_ID secret to the github repository
# It will assign the AZURE_TENANT_ID secret to the github repository
# It will assign the AZURE_SUBSCRIPTION_ID secret to the github repository

Param(
    [Parameter(Mandatory=$true)]
    [string]$appname,
    [Parameter(Mandatory=$true)]
    [string]$organization,
    [Parameter(Mandatory=$true)]
    [string]$repo,
    [Parameter(Mandatory=$true)]
    [string]$branch
)

# Install github cli if not installed
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    # Install the GitHub CLI
    curl -sL https://git.io/gh | sudo tee /usr/local/bin/gh
    sudo chmod +x /usr/local/bin/gh
}

# Login to github
gh auth login

# Create new private github repository in the organization
gh repo create $organization/$repo --private

# Set the default branch
gh api -X PATCH repos/$organization/$repo -f default_branch=$branch

# Create new Azure AD application
New-AzADApplication -DisplayName $appname

# Create Service Principal
$clientId = (Get-AzADApplication -DisplayName $appname).AppId
$appObjectId = (Get-AzADApplication -DisplayName $appname).Id
New-AzADServicePrincipal -ApplicationId $clientId

# Assign the Contributor Role
# This is assigned to the current Subscription
$objectId = (Get-AzADServicePrincipal -DisplayName $appname).Id
New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName Contributor

# Get the Identifiers later use for the workflow
$clientId = (Get-AzADApplication -DisplayName $appname).AppId
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Subscription.TenantId

# set the federatedIdentityCredentials to the Azure AD application
New-AzADAppFederatedCredential -Name $repo$branch -ApplicationObjectId $appObjectId -Issuer "https://token.actions.githubusercontent.com" -Subject "repo:$organization/$repo:ref:refs/heads/$branch" -Audience "api://AzureADTokenExchange"

#Invoke-AzRestMethod -Method POST -Uri 'https://graph.microsoft.com/beta/applications/$clientId/federatedIdentityCredentials' -Payload  '{"name":"GithubAction","issuer":"https://token.actions.githubusercontent.com","subject":"repo:$organization/$repo:ref:refs/heads/$branch","description":"Production","audiences":["api://AzureADTokenExchange"]}'

# Set secrets
# AZURE_CLIENT_ID
gh api -X PUT repos/$organization/$repo/actions/secrets/AZURE_CLIENT_ID -f value=$clientId
# AZURE_TENANT_ID
gh api -X PUT repos/$organization/$repo/actions/secrets/AZURE_TENANT_ID -f value=$tenantId
# AZURE_SUBSCRIPTION_ID
gh api -X PUT repos/$organization/$repo/actions/secrets/AZURE_SUBSCRIPTION_ID -f value=$subscriptionId


