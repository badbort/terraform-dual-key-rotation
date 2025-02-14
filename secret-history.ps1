param (
    [string]$KeyVaultName,
    [string[]]$SecretNames
)

# Ensure Az module is installed
if (!(Get-Module -ListAvailable -Name Az.KeyVault)) {
    Write-Host "Installing Az.KeyVault module..."
    Install-Module -Name Az.KeyVault -Scope CurrentUser -Force
}

# Login if necessary
if (!(Get-AzContext)) {
    Connect-AzAccount
}

# Function to get secret versions
function Get-SecretHistory {
    param (
        [string]$KeyVaultName,
        [string]$SecretName
    )
    
    $history = @()
    # Get all secret versions
    $versions = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -IncludeVersions
    #Write-Host "Versions: $($versions | ConvertTo-Json)"

    foreach($version in $versions) {
        #Write-Host "Version: $($version | ConvertTo-Json)"
        
        $secretValue = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -Version $version.Version -AsPlainText
        #Write-Host "Secret:  $(Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -Version $version.Version | ConvertTo-Json)"
        
        $history += [PSCustomObject]@{
            SecretName = $version.Name
            Timestamp  = $version.Created
            Expires    = $version.Expires
            Value      = $secretValue
        }
    }

    # Believe it or not, the comma is necessary to prevent powershell converting arrays of one item into just the single item
    # Needed if people are running script when secret has only been updated once
    return ,$history
}

# Collect history for all provided secrets
$allHistories = @()
foreach ($secret in $SecretNames) {
    $allHistories += Get-SecretHistory -KeyVaultName $KeyVaultName -SecretName $secret
}

# Sort all history records by timestamp (newest first)
$allHistorySorted = $allHistories | Sort-Object Timestamp -Descending

# Print history
Write-Host "----------------------------------------------------"
Write-Host " Azure Key Vault Secret Rotation History"
Write-Host "----------------------------------------------------"
$allHistorySorted | Format-Table -AutoSize Timestamp, SecretName, Expires, Value
