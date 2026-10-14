param (
    [string]$User = 'root',
    [string]$Password = 'root',
    [string]$DbHost = 'localhost',
    [int]$DbPort = 3306,
    [switch]$Reset
)

$mysqlPath = 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
if (-not (Test-Path $mysqlPath)) {
    $found = Get-Command mysql -ErrorAction SilentlyContinue
    if ($found) {
        $mysqlPath = $found.Source
    } else {
        Write-Error "mysql.exe not found at standard path '$mysqlPath'."
        exit 1
    }
}

$scriptDir = $PSScriptRoot

Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  MuleSoft Regulatory Compliance Reporting -- Database Setup  ' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host "Target Host: $DbHost`:$DbPort"
Write-Host "Target User: $User"

if ($Reset) {
    Write-Host 'Mode: FULL RESET (Destructive recreate and reseed)' -ForegroundColor Yellow
    $sqlFiles = @(
        '01_create_database.sql',
        '02_create_tables.sql',
        '03_create_indexes.sql',
        '04_seed_sample_data.sql'
    )

    foreach ($file in $sqlFiles) {
        $filePath = Join-Path $scriptDir $file
        Write-Host "Executing [$file]..." -NoNewline
        if ($file -eq '01_create_database.sql') {
            cmd /c "`"$mysqlPath`" -h $DbHost -P $DbPort -u $User -p$Password --default-character-set=utf8mb4 < `"$filePath`" 2>nul"
        } else {
            cmd /c "`"$mysqlPath`" -h $DbHost -P $DbPort -u $User -p$Password --default-character-set=utf8mb4 compliance_db < `"$filePath`" 2>nul"
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Host ' [FAILED]' -ForegroundColor Red
            exit $LASTEXITCODE
        } else {
            Write-Host ' [OK]' -ForegroundColor Green
        }
    }
} else {
    Write-Host 'Mode: SAFE / REPEATABLE (CREATE IF NOT EXISTS, non-destructive)' -ForegroundColor Green
    $filePath = Join-Path $scriptDir 'init_compliance_db_repeatable.sql'
    Write-Host 'Executing [init_compliance_db_repeatable.sql]...' -NoNewline
    cmd /c "`"$mysqlPath`" -h $DbHost -P $DbPort -u $User -p$Password --default-character-set=utf8mb4 < `"$filePath`" 2>nul"
    if ($LASTEXITCODE -ne 0) {
        Write-Host ' [FAILED]' -ForegroundColor Red
        exit $LASTEXITCODE
    } else {
        Write-Host ' [OK]' -ForegroundColor Green
    }
}

Write-Host ''
Write-Host 'Database compliance_db is ready!' -ForegroundColor Green
