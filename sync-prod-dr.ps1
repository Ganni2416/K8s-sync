$prodNamespace = "prod"
$drNamespace = "dr"

# Get all running deployments from the PROD namespace
$deployments = kubectl get deployments -n $prodNamespace --output=json | `
    ConvertFrom-Json | `
    Select-Object -ExpandProperty items | `
    Where-Object { $_.status.replicas -gt 0 }

foreach ($deployment in $deployments) {
    $name = $deployment.metadata.name
    $image = $deployment.spec.template.spec.containers[0].image
    Write-Host "[INFO] Found deployment: $name with image: $image"

    # Check if deployment exists in DR
    $exists = kubectl get deployment $name -n $drNamespace -o name 2>$null

    if ($exists) {
        Write-Host "[INFO] Patching $name in DR with image: $image"
        kubectl set image deployment/$name *=$image -n $drNamespace --record

        Write-Host "[INFO] Scaling $name in DR to 0 replicas"
        kubectl scale deployment/$name --replicas=0 -n $drNamespace
    } else {
        Write-Host "[WARN] Deployment $name not found in DR. Skipping."
    }
}
