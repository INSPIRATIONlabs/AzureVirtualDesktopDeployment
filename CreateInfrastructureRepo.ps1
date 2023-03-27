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
gh repo create $organization/$repo --private --confirm --template inspirationlabs/bicepdeploy-template

# check if there is already an app with the same name
$application = (Get-AzADApplication -DisplayName $appname)

# create application if it does not exist
if (!$application) {
    # Create new Azure AD application
    $application = New-AzADApplication -DisplayName $appname
}

# if application exist and is array, take the first one
if ($application -is [array]) {
    $application = $application[0]
}

# Create Service Principal
$clientId = $application.AppId
$appObjectId = $application.Id

# check if there is already a service principal with the same name
$servicePrincipal = Get-AzADServicePrincipal -ApplicationId $clientId

# create service principal if it does not exist
if (!$servicePrincipal) {
    # Create new Service Principal
    $servicePrincipal = New-AzADServicePrincipal -ApplicationId $clientId
}

$objectId = $servicePrincipal.Id

# check if there is already the Contributor role assigned to the service principal
$roleAssignment = Get-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName Contributor
if (!$roleAssignment) {
    # Assign the Contributor Role
    # This is assigned to the current Subscription
    New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName Contributor
}

# Get the Identifiers later use for the workflow
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Subscription.TenantId

$subject = "repo:$organization/$repo" + ":ref:refs/heads/$branch"


$fedcred = New-AzADAppFederatedCredential -Name $repo$branch -ApplicationObjectId $appObjectId -Issuer "https://token.actions.githubusercontent.com" -Subject $subject -Audience "api://AzureADTokenExchange"

# only create the secrets if fedcred is created
if ($fedcred) {
    # set the secrets
    gh secret set AZURE_CLIENT_ID -b $clientId -R $organization/$repo
    gh secret set AZURE_TENANT_ID -b $tenantId -R $organization/$repo
    gh secret set AZURE_SUBSCRIPTION_ID -b $subscriptionId -R $organization/$repo
}