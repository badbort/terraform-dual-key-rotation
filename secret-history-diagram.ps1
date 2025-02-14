param (
    [string]$KeyVaultName,
    [string[]]$SecretNames,
    [string]$OutputMarkdownFile = "SecretRotationHistory.md"
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

    foreach ($version in $versions) {
        $secretValue = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -Version $version.Version -AsPlainText

        $history += [PSCustomObject]@{
            SecretName = $SecretName
            Version    = $version.Version
            Timestamp  = $version.Created
            Expires    = $version.Expires
            Value      = $secretValue
        }
    }

    return ,$history
}

# Generate Markdown content
$mermaidDiagram = @"
# Azure Key Vault Secret Rotation History

``````mermaid
gantt
    title Secret Rotation Timeline
    dateFormat  YYYY-MM-DD HH:mm:ss
    axisFormat  %H:%M:%S
    
"@

# Collect history for all provided secrets
$allHistories = @()
foreach ($secret in $SecretNames) {
    $allHistories += Get-SecretHistory -KeyVaultName $KeyVaultName -SecretName $secret
}

# Sort all history records by timestamp (newest first)
$allHistorySorted = $allHistories | Sort-Object Timestamp

$mermaidDiagram += "  section Secrets`n"

foreach ( $item in $allHistorySorted ) {
    $secretLabel = "$($item.SecretName) "
    $startTime = $item.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
    $endTime = $item.Expires.ToString("yyyy-MM-dd HH:mm:ss")
    
    $mermaidDiagram += "    $secretLabel  : $startTime, $endTime`n"
}

# Close Mermaid block
$mermaidDiagram += "`n``````"

# Write to Markdown file
Set-Content -Path $OutputMarkdownFile -Value $mermaidDiagram

Write-Host "Mermaid Gantt chart written to $OutputMarkdownFile"
