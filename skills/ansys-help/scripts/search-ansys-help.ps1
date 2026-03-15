[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$HelpPath,

    [Parameter(Mandatory = $true)]
    [string[]]$Query,

    [Parameter()]
    [ValidateRange(1, 200)]
    [int]$TopK = 10,

    [Parameter()]
    [string]$FileFilter,

    [Parameter()]
    [string]$VersionHint,

    [Parameter()]
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-Term {
    param(
        [System.Collections.Generic.HashSet[string]]$Set,
        [string]$Term
    )

    if ($null -eq $Set) {
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($Term)) {
        $null = $Set.Add($Term.Trim())
    }
}

function Split-QueryToken {
    param([string[]]$InputTokens)

    $parts = New-Object System.Collections.Generic.List[string]

    foreach ($item in $InputTokens) {
        if ([string]::IsNullOrWhiteSpace($item)) {
            continue
        }

        $split = $item -split "[\s,;|/]+"
        foreach ($s in $split) {
            if ([string]::IsNullOrWhiteSpace($s)) {
                continue
            }

            $normalized = ($s.Trim() -replace "^[\p{P}\p{S}]+", "" -replace "[\p{P}\p{S}]+$", "")
            if (-not [string]::IsNullOrWhiteSpace($normalized)) {
                $parts.Add($normalized)
            }
        }
    }

    return $parts | Sort-Object -Unique
}

function Expand-Keywords {
    param([string[]]$Tokens)

    $map = @{
        "hfss"        = @("ansys hfss", "high frequency", "wave port", "s parameter")
        "q3d"         = @("ansys q3d", "q3d extractor", "capacitance", "inductance")
        "maxwell"     = @("ansys maxwell", "eddy current", "transient", "magnetic")
        "icepak"      = @("thermal", "cooling", "heat sink")
        "siwave"      = @("signal integrity", "power integrity", "pi", "si")
        "modeling"    = @("geometry", "3d modeler", "layout", "sketch")
        "mesh"        = @("meshing", "mesh operation", "adaptive", "refinement")
        "solve"       = @("solver", "analysis setup", "solution setup", "convergence")
        "solver"      = @("solve", "analysis setup", "solution setup")
        "postprocess" = @("results", "field plot", "report", "export")
        "parallel"    = @("distributed", "hpc", "remote solve", "cluster")
        "fillet"      = @("round", "round corner", "blend")
        "material"    = @("material assignment", "permittivity", "conductivity")
        "port"        = @("wave port", "lumped port", "terminal", "excitation")
        "boundary"    = @("boundary condition", "radiation", "pec", "pmc", "impedance")
        "s-parameter" = @("s parameter", "s11", "s21", "touchstone")
        "sparameter"  = @("s parameter", "s11", "s21", "touchstone")
        "error"       = @("failed", "warning", "exception", "cannot", "troubleshooting", "workaround")
        "warning"     = @("troubleshooting", "workaround", "solution")
    }

    $all = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($token in $Tokens) {
        Add-Term -Set $all -Term $token
        Add-Term -Set $all -Term $token.ToLowerInvariant()

        $lower = $token.ToLowerInvariant()
        if ($map.ContainsKey($lower)) {
            foreach ($e in $map[$lower]) {
                Add-Term -Set $all -Term $e
            }
        }

        # CJK aliases are matched with Unicode regex escapes to keep source ASCII-safe.
        switch -Regex ($token) {
            "\u5efa\u6a21" {
                @("modeling", "geometry", "3d modeler", "layout") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u7f51\u683c" {
                @("mesh", "meshing", "mesh operation", "adaptive") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u6c42\u89e3" {
                @("solve", "solver", "analysis setup", "solution setup") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u540e\u5904\u7406" {
                @("postprocess", "results", "field plot", "report") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u5e76\u884c\u8ba1\u7b97" {
                @("parallel", "distributed", "hpc", "remote solve") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u5bfc\u5706\u89d2" {
                @("fillet", "round", "round corner", "blend") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u6750\u6599\u8bbe\u7f6e" {
                @("material", "material assignment", "permittivity", "conductivity") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u7aef\u53e3" {
                @("port", "wave port", "lumped port", "terminal") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u8fb9\u754c\u6761\u4ef6" {
                @("boundary", "boundary condition", "radiation", "pec", "pmc", "impedance") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u53c2\u6570" {
                @("s parameter", "s11", "s21", "touchstone") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u65b9\u5411\u56fe" {
                @("radiation pattern", "far field", "gain pattern") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u5fae\u5e26\u5929\u7ebf" {
                @("microstrip antenna", "patch antenna") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
            "\u8fc7\u5b54" {
                @("via", "through hole", "plated via") | ForEach-Object { Add-Term -Set $all -Term $_ }
                break
            }
        }
    }

    return @($all)
}

function Get-SoftwareAnchors {
    param([string[]]$Tokens)

    $known = @("hfss", "q3d", "maxwell", "icepak", "siwave", "mechanical", "fluent")
    $set = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($token in $Tokens) {
        $lower = $token.ToLowerInvariant()
        foreach ($k in $known) {
            if ($lower.Contains($k)) {
                $null = $set.Add($k)
            }
        }
    }

    return @($set)
}

function New-ResultItem {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Match,
        [Parameter()]
        [string[]]$OriginalTokens,
        [Parameter()]
        [string[]]$SoftwareAnchors,
        [Parameter()]
        [string]$VersionHint
    )

    $line = ($Match.Line -replace "\s+", " ").Trim()
    $path = $Match.Path
    $lineLower = $line.ToLowerInvariant()
    $pathLower = $path.ToLowerInvariant()

    $score = 0
    $reasons = New-Object System.Collections.Generic.List[string]

    foreach ($t in @($OriginalTokens)) {
        if ([string]::IsNullOrWhiteSpace($t)) {
            continue
        }

        $lt = $t.ToLowerInvariant()
        if ($lineLower.Contains($lt)) {
            $score += 8
            $reasons.Add("contains keyword '$t'")
        }

        if ($pathLower.Contains($lt)) {
            $score += 6
            $reasons.Add("path matches '$t'")
        }
    }

    foreach ($s in @($SoftwareAnchors)) {
        if ($pathLower.Contains($s)) {
            $score += 20
            $reasons.Add("same software '$s'")
        }
        elseif ($lineLower.Contains($s)) {
            $score += 12
            $reasons.Add("line mentions software '$s'")
        }
    }

    $ops = @("fillet", "wave port", "lumped port", "boundary", "mesh", "solver", "s parameter", "radiation pattern")
    foreach ($o in $ops) {
        if ($lineLower.Contains($o)) {
            $score += 5
            $reasons.Add("operation signal '$o'")
        }
    }

    $fixTokens = @("cause", "reason", "solution", "workaround", "troubleshooting")
    foreach ($ft in $fixTokens) {
        if ($lineLower.Contains($ft)) {
            $score += 6
            $reasons.Add("contains fix clue '$ft'")
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($VersionHint)) {
        $hint = $VersionHint.ToLowerInvariant()
        if ($lineLower.Contains($hint) -or $pathLower.Contains($hint)) {
            $score += 10
            $reasons.Add("matches version hint '$VersionHint'")
        }
    }

    if ($score -eq 0) {
        $score = 1
    }

    return [PSCustomObject]@{
        Key        = "{0}|{1}|{2}" -f $path, $Match.LineNumber, $line
        Score      = $score
        Path       = $path
        LineNumber = $Match.LineNumber
        Snippet    = $line
        Reasons    = @($reasons | Sort-Object -Unique)
    }
}

if (-not (Test-Path -LiteralPath $HelpPath)) {
    throw "HelpPath not found: $HelpPath"
}

$rootItem = Get-Item -LiteralPath $HelpPath

$textExt = @(".html", ".htm", ".txt", ".md", ".xml", ".log")
$extraExt = @(".pdf", ".chm")
$allExt = $textExt + $extraExt

$scanFiles = @()
if ($rootItem.PSIsContainer) {
    $scanFiles = Get-ChildItem -LiteralPath $rootItem.FullName -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $allExt -contains $_.Extension.ToLowerInvariant() }
}
else {
    if ($allExt -contains $rootItem.Extension.ToLowerInvariant()) {
        $scanFiles = @($rootItem)
    }
}

if (-not [string]::IsNullOrWhiteSpace($FileFilter)) {
    $scanFiles = $scanFiles | Where-Object { $_.FullName -like "*$FileFilter*" }
}

$scannedTypes = @($scanFiles.Extension | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object -Unique)
$textFiles = @($scanFiles | Where-Object { $textExt -contains $_.Extension.ToLowerInvariant() })
$pdfCount = @($scanFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq ".pdf" }).Count
$chmCount = @($scanFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq ".chm" }).Count

$summaryObj = [PSCustomObject]@{
    HelpPath         = $rootItem.FullName
    Query            = ($Query -join ", ")
    NormalizedTokens = @()
    ExpandedTokens   = @()
    ScannedTypes     = $scannedTypes
    TextFilesScanned = $textFiles.Count
    PdfFilesDetected = $pdfCount
    ChmFilesDetected = $chmCount
    Hits             = 0
    Note             = ""
}

if ($textFiles.Count -eq 0) {
    $summaryObj.Note = "No text-based files found for direct search. Extract CHM or convert PDF to text/HTML first."

    if ($AsJson) {
        [PSCustomObject]@{ Summary = $summaryObj; Results = @() } | ConvertTo-Json -Depth 6
    }
    else {
        Write-Output "Search Summary"
        Write-Output "- Path: $($summaryObj.HelpPath)"
        Write-Output "- Query: $($summaryObj.Query)"
        Write-Output "- Scanned file types: $($summaryObj.ScannedTypes -join ', ')"
        Write-Output "- Text files scanned: $($summaryObj.TextFilesScanned)"
        Write-Output "- PDF detected: $($summaryObj.PdfFilesDetected), CHM detected: $($summaryObj.ChmFilesDetected)"
        Write-Output "- Hits: 0"
        Write-Output "- Note: $($summaryObj.Note)"
    }

    exit 0
}

$originalTokens = Split-QueryToken -InputTokens $Query
$expanded = Expand-Keywords -Tokens $originalTokens
$softwareAnchors = Get-SoftwareAnchors -Tokens ($originalTokens + $expanded)

$summaryObj.NormalizedTokens = @($originalTokens)
$summaryObj.ExpandedTokens = @($expanded | Sort-Object -Unique)

$escapedPattern = ($summaryObj.ExpandedTokens | ForEach-Object { [Regex]::Escape($_) }) -join "|"
if ([string]::IsNullOrWhiteSpace($escapedPattern)) {
    throw "Query is empty after normalization."
}

$rawMatches = Select-String -Path ($textFiles.FullName) -Pattern $escapedPattern -AllMatches -Encoding UTF8 -ErrorAction SilentlyContinue

$resultObjects = foreach ($m in $rawMatches) {
    New-ResultItem -Match $m -OriginalTokens $originalTokens -SoftwareAnchors $softwareAnchors -VersionHint $VersionHint
}

$deduped = @(
    $resultObjects |
        Group-Object -Property Key |
        ForEach-Object { $_.Group | Sort-Object -Property Score -Descending | Select-Object -First 1 }
)

$summaryObj.Hits = $deduped.Count

$top = @(
    $deduped |
    Sort-Object -Property @{ Expression = "Score"; Descending = $true }, @{ Expression = "Path"; Descending = $false }, @{ Expression = "LineNumber"; Descending = $false } |
        Select-Object -First $TopK
)

if ($AsJson) {
    [PSCustomObject]@{
        Summary = $summaryObj
        Results = $top
    } | ConvertTo-Json -Depth 8
    exit 0
}

Write-Output "Search Summary"
Write-Output "- Path: $($summaryObj.HelpPath)"
Write-Output "- Query: $($summaryObj.Query)"
Write-Output "- Normalized keywords: $($summaryObj.NormalizedTokens -join ', ')"
Write-Output "- Scanned file types: $($summaryObj.ScannedTypes -join ', ')"
Write-Output "- Text files scanned: $($summaryObj.TextFilesScanned)"
Write-Output "- PDF detected: $($summaryObj.PdfFilesDetected), CHM detected: $($summaryObj.ChmFilesDetected)"
Write-Output "- Unique hits: $($summaryObj.Hits)"

if ($top.Count -eq 0) {
    Write-Output ""
    Write-Output "Top Matches"
    Write-Output "- No hits found. Try adding software name (HFSS/Q3D/Maxwell) or exact error text."
    exit 0
}

Write-Output ""
Write-Output "Top Matches"

$idx = 1
foreach ($item in $top) {
    Write-Output ("[{0}] score={1}" -f $idx, $item.Score)
    Write-Output ("source: {0}:{1}" -f $item.Path, $item.LineNumber)
    Write-Output ("snippet: {0}" -f $item.Snippet)

    if ($item.Reasons.Count -gt 0) {
        Write-Output ("why relevant: {0}" -f (($item.Reasons | Select-Object -First 4) -join "; "))
    }
    else {
        Write-Output "why relevant: keyword hit"
    }

    Write-Output ""
    $idx++
}

Write-Output "Next-Step Tip"
Write-Output "- Add module constraints (mesh/solver/postprocess) or exact error code to narrow results."
