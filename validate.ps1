#!/usr/bin/env pwsh
#
# validate.ps1 - Closed-loop validation for Pi-hole VPN. (PowerShell)
#
# PowerShell port of validate.sh. Runs every check the agent (or you) must pass
# before committing. Exit code 0 = all checks passed. Non-zero = first failure,
# with the reason. Runs unattended (no prompts), so an agent can call it and
# self-correct.
#
# CONFIGURE THIS FILE: uncomment or add the checks for your stack. The examples/
# directory in claude-spec-kit has full validate.ps1 scripts for Go, Python, and
# shell/Terraform you can copy from. Keep checks fast and deterministic (no
# network, no wall-clock dependence) so the loop stays unattended. List the
# checks you settle on in CLAUDE.md's "Validation: the closed loop" section so
# the description and the script agree.

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$script:ran = 0
function Step($msg) { Write-Host "==> $msg"; $script:ran++ }
function Fail($msg) { [Console]::Error.WriteLine("FAIL: $msg"); exit 1 }

# --- Checks ---------------------------------------------------------------
# Replace the block below with your project's checks. Each check calls Step with
# a label, runs a command, and calls Fail on a non-zero result.
#
# Example (format check):
#   Step "format"
#   $unformatted = your-formatter -l .
#   if ($unformatted) { Fail "not formatted: $unformatted" }
#
# Example (lint / static analysis):
#   Step "lint"; your-linter .; if ($LASTEXITCODE -ne 0) { Fail "lint reported issues" }
#
# Example (unit tests):
#   Step "tests"; your-test-runner; if ($LASTEXITCODE -ne 0) { Fail "tests failed" }
#
# Example (build):
#   Step "build"; your-build; if ($LASTEXITCODE -ne 0) { Fail "build failed" }
#
# Example (secret scan, staged files):
#   Step "no secrets staged"
#   $staged = git diff --cached --name-only
#   if ($staged | Where-Object { $_ -match '\.(pem|key|p12|env)$' }) { Fail "credential file staged" }
#
# Example (end-to-end behavior check): spin up the real thing and assert an
# observable outcome. See examples/validate/go.ps1 for a full e2e.

# TODO: remove this guard once you add real checks above.
Step "configure validate.ps1"
Fail "no checks configured yet: edit validate.ps1 and add your project's checks (see examples/ in claude-spec-kit)"

# --- Result ---------------------------------------------------------------
if ($script:ran -le 0) { Fail "no checks ran" }
Write-Host "`nALL CHECKS PASSED"
