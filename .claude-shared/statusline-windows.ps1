# Claude Code statusline (Windows PowerShell)
# Reads JSON from stdin, prints: folder | branch | model | ctx [bar] %

$ErrorActionPreference = "SilentlyContinue"

try {
    $raw = [Console]::In.ReadToEnd()
    if (-not $raw) { Write-Output "claude"; exit 0 }
    $j = $raw | ConvertFrom-Json

    # Folder name
    $folder = if ($j.cwd) { Split-Path -Leaf $j.cwd } else { "?" }

    # Model display name
    $model = if ($j.model -and $j.model.display_name) { $j.model.display_name } else { "?" }

    # Git branch
    $branch = "-"
    if ($j.cwd -and (Test-Path $j.cwd)) {
        Push-Location $j.cwd
        $b = git branch --show-current 2>$null
        if ($b) { $branch = $b.Trim() }
        Pop-Location
    }

    # Context estimation from transcript size
    # Rough: 1 token ≈ 4 chars, Claude max context ≈ 200K tokens (1M with extended)
    $pct = 0
    $bar = "----------"
    if ($j.transcript_path -and (Test-Path $j.transcript_path)) {
        $size = (Get-Item $j.transcript_path).Length
        # Use 1M tokens (4M chars) as the max for Opus 4.7 1M context
        $maxChars = 4000000
        $pct = [Math]::Min(100, [Math]::Floor($size * 100 / $maxChars))
        $filled = [Math]::Floor($pct / 10)
        if ($filled -gt 10) { $filled = 10 }
        $empty = 10 - $filled
        $bar = ("#" * $filled) + ("-" * $empty)
    }

    # Color codes (ANSI) - dim for labels, gold for values
    $reset = "$([char]27)[0m"
    $dim = "$([char]27)[2m"
    $gold = "$([char]27)[33m"
    $cyan = "$([char]27)[36m"
    $red = "$([char]27)[31m"

    # Color the context bar based on usage
    $ctxColor = $cyan
    if ($pct -ge 80) { $ctxColor = $red }
    elseif ($pct -ge 60) { $ctxColor = $gold }

    Write-Output "${dim}📁${reset} ${gold}$folder${reset} ${dim}|${reset} ${dim}🌿${reset} $branch ${dim}|${reset} ${dim}🤖${reset} $model ${dim}|${reset} ${dim}📊${reset} ${ctxColor}[$bar]${reset} ${ctxColor}$pct%${reset}"
} catch {
    Write-Output "claude (statusline error)"
}
