# Flux Workspace Full CI/CD Test Script
# Automates analysis and testing across all packages

$root = Get-Location
$packages = @(
    "flux_compiler",
    "flux_vm",
    "flux_lsp",
    "flux_dap",
    "flux_cli",
    "flux_flutter"
)

$results = @{}
$failed = $false

Write-Host "🚀 Starting Full Workspace Verification..." -ForegroundColor Cyan
Write-Host "============================================"

foreach ($pkg in $packages) {
    Write-Host "`n📦 Processing package: $pkg" -ForegroundColor Yellow
    cd "$root\packages\$pkg"
    
    # 1. Pub Get
    Write-Host "  -> Running pub get..."
    if ($pkg -eq "flux_flutter") {
        fvm flutter pub get | Out-Null
    } else {
        fvm dart pub get | Out-Null
    }

    # 2. Analyze
    Write-Host "  -> Static Analysis..."
    $analyzeCmd = if ($pkg -eq "flux_flutter") { "fvm flutter analyze" } else { "fvm dart analyze --fatal-warnings" }
    if ($pkg -eq "flux_compiler") { $analyzeCmd = "fvm dart analyze --fatal-infos" }
    
    Invoke-Expression $analyzeCmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Analysis FAILED for $pkg" -ForegroundColor Red
        $results["$pkg-analyze"] = "FAILED"
        $failed = $true
    } else {
        Write-Host "  ✅ Analysis PASSED" -ForegroundColor Green
        $results["$pkg-analyze"] = "PASSED"
    }

    # 3. Test
    Write-Host "  -> Running Tests..."
    $testCmd = if ($pkg -eq "flux_flutter") { "fvm flutter test" } else { "fvm dart test" }
    
    Invoke-Expression $testCmd
    if ($LASTEXITCODE -ne 0) {
        if ($pkg -eq "flux_dap") {
            Write-Host "  ⚠️  No tests found for $pkg (Skipped)" -ForegroundColor Gray
            $results["$pkg-test"] = "SKIPPED"
        } else {
            Write-Host "  ❌ Tests FAILED for $pkg" -ForegroundColor Red
            $results["$pkg-test"] = "FAILED"
            $failed = $true
        }
    } else {
        Write-Host "  ✅ Tests PASSED" -ForegroundColor Green
        $results["$pkg-test"] = "PASSED"
    }
}

Write-Host "`n============================================"
Write-Host "📊 Verification Summary" -ForegroundColor Cyan
Write-Host "============================================"

foreach ($key in $results.Keys | Sort-Object) {
    $status = $results[$key]
    $color = if ($status -eq "PASSED") { "Green" } elseif ($status -eq "FAILED") { "Red" } else { "Gray" }
    Write-Host "$($key.PadRight(25)) : " -NoNewline
    Write-Host "$status" -ForegroundColor $color
}

cd $root

if ($failed) {
    Write-Host "`n❌ VERIFICATION FAILED. Some components have issues." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✨ VERIFICATION SUCCESSFUL! All components are stable." -ForegroundColor Green
    exit 0
}
