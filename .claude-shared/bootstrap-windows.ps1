# Windows 첫 셋업 — %USERPROFILE%\.claude\CLAUDE.md + memory 폴더를 .claude-shared 로 연결
#
# 안전: 기존 파일은 항상 .bak.<timestamp> 로 백업.
# 재실행 OK (idempotent).
#
# 실행 전 한 번:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#
# 심볼릭 링크 권한:
#   - Windows 10/11 Developer Mode 켜면 일반 사용자도 가능
#   - 또는 PowerShell 을 "관리자 권한으로 실행"
#   - 둘 다 안 되면 스크립트가 mklink /J (디렉토리 정션) 로 fallback

$ErrorActionPreference = "Stop"

$SharedDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Ts = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "==> .claude-shared = $SharedDir"

# --- 1. 글로벌 CLAUDE.md 를 @import 두 줄로 치환 ----------------------------
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$GlobalMd = Join-Path $ClaudeDir "CLAUDE.md"
New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null

if ((Test-Path $GlobalMd) -and -not ((Get-Item $GlobalMd).Attributes -match "ReparsePoint")) {
    Copy-Item $GlobalMd "$GlobalMd.bak.$Ts"
    Write-Host "==> 기존 ~/.claude/CLAUDE.md 백업: $GlobalMd.bak.$Ts"
}

$globalContent = @"
# Auto-loaded from $SharedDir
# 이 파일은 bootstrap-windows.ps1 가 관리합니다. 직접 수정하지 마세요.
# 운영 룰 변경은 .claude-shared/global.md (또는 global-windows.md) 에서.

@$SharedDir\global.md
@$SharedDir\global-windows.md
"@
Set-Content -Path $GlobalMd -Value $globalContent -Encoding UTF8
Write-Host "==> ~/.claude/CLAUDE.md = @import 두 줄로 치환 완료"

# --- 2. 메모리 폴더 심볼릭 링크 (또는 정션) ----------------------------------
# Claude Code 의 프로젝트 경로 인코딩: drive letter + `:\` 를 `--`, `\` 를 `-` 로 변환
$repoPath = (Get-Item (Join-Path $SharedDir "..")).FullName  # 상위 = seephone repo
$encoded = $repoPath -replace ":\\", "--" -replace "\\", "-"
$MemTarget = Join-Path $ClaudeDir "projects\$encoded\memory"
$MemSrc = Join-Path $SharedDir "memory"

$memProjectDir = Split-Path -Parent $MemTarget
New-Item -ItemType Directory -Path $memProjectDir -Force | Out-Null

if (Test-Path $MemTarget) {
    $item = Get-Item $MemTarget -Force
    if ($item.Attributes -match "ReparsePoint") {
        # 기존 링크 — 제거
        (Get-Item $MemTarget).Delete()
    } else {
        # 실제 디렉토리 — 머지 후 백업
        Write-Host "==> 기존 메모리 폴더 발견. .claude-shared/memory 와 머지 후 백업"
        Get-ChildItem $MemTarget -Filter "*.md" | ForEach-Object {
            $dest = Join-Path $MemSrc $_.Name
            if (-not (Test-Path $dest)) {
                Write-Host "    + $($_.Name) 가 .claude-shared 에 없음 — 가져옴"
                Copy-Item $_.FullName $dest
            }
        }
        Move-Item $MemTarget "$MemTarget.bak.$Ts"
        Write-Host "==> 기존 메모리 백업: $MemTarget.bak.$Ts"
    }
}

# 심볼릭 링크 시도, 실패 시 정션으로 fallback
try {
    New-Item -ItemType SymbolicLink -Path $MemTarget -Target $MemSrc | Out-Null
    Write-Host "==> 메모리 심볼릭 링크 생성: $MemTarget → $MemSrc"
} catch {
    Write-Host "==> 심볼릭 링크 실패 (권한). mklink /J (정션) 으로 fallback"
    cmd /c mklink /J "`"$MemTarget`"" "`"$MemSrc`"" | Out-Null
    Write-Host "==> 메모리 정션 생성: $MemTarget → $MemSrc"
}

# --- 3. 검증 -----------------------------------------------------------
Write-Host ""
Write-Host "==> 검증"
Write-Host "    ~/.claude/CLAUDE.md:"
Get-Content $GlobalMd | ForEach-Object { Write-Host "      $_" }
Write-Host ""
Write-Host "    메모리 링크:"
Get-Item $MemTarget | Format-List FullName, Target, Attributes | Out-String | Write-Host
Write-Host ""
Write-Host "==> 완료. Claude Code 재시작 후 새 세션에서 적용됩니다."
Write-Host ""
Write-Host "    seephone repo 가 다른 경로에 있다면:"
Write-Host "    - 현재 인코딩 가정: $encoded"
Write-Host "    - 실제 repo 경로: $repoPath"
Write-Host "    - 인코딩이 어긋나면 메모리가 안 읽힘. 필요시 스크립트 \$encoded 로직 조정."
