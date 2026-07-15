#!/usr/bin/env pwsh
<#
.SYNOPSIS
    YAHLP Release Script - Automates version update and git release process

.DESCRIPTION
    Updates VERSION file, commits, creates git tag, pushes to remote, and creates GitHub release

.PARAMETER Version
    The version number (e.g., b.2.0.22)

.PARAMETER Description
    Release description/notes (optional)

.EXAMPLE
    .\release.ps1 b.2.0.22 "Fix: Display version in proxy startup"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string]$Description = "Release $Version"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Releasing YAHLP $Version" -ForegroundColor Green
Write-Host "📝 Description: $Description"
Write-Host ""

# Check if git is clean
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "❌ Git working directory is not clean. Commit or stash changes first." -ForegroundColor Red
    git status
    exit 1
}

# Update VERSION file
Write-Host "📄 Updating VERSION file to $Version" -ForegroundColor Cyan
$Version | Set-Content -Path VERSION -NoNewline

# Commit VERSION change
Write-Host "💾 Committing VERSION change" -ForegroundColor Cyan
git add VERSION
git commit -m "bump: version $Version" -ErrorAction SilentlyContinue | Out-Null

# Push to origin/main
Write-Host "⬆️  Pushing to origin/main" -ForegroundColor Cyan
git push origin main

# Create git tag
Write-Host "🏷️  Creating git tag $Version" -ForegroundColor Cyan
git tag -a $Version -m "Release $Version`: $Description"

# Push tag to origin
Write-Host "⬆️  Pushing tag to origin" -ForegroundColor Cyan
git push origin $Version

# Create GitHub release
Write-Host "📦 Creating GitHub release" -ForegroundColor Cyan
gh release create $Version `
    --title "Release $Version" `
    --notes $Description

Write-Host ""
Write-Host "✅ Release $Version complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Release details:" -ForegroundColor Cyan
Write-Host "  - Version: $Version"
Write-Host "  - Tag: https://github.com/auskento/YAHLP/releases/tag/$Version"
$commit = git rev-parse --short HEAD
Write-Host "  - Commit: $commit"
