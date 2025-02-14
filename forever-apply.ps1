# Define the log file
$logFile = "terraform-apply-log.txt"

# Infinite loop to run Terraform apply every minute
while ($true) {
    Write-Host "=========================================="
    Write-Host " Running Terraform Apply - Auto Approve "
    Write-Host "=========================================="

    # Get the timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] Running terraform apply..."

    # Run Terraform apply, stream output to console and log file
    terraform apply -auto-approve 2>&1 | Tee-Object -FilePath $logFile -Append

    Write-Host "Waiting 30 seconds before next apply..."
    Start-Sleep -Seconds 30
}
