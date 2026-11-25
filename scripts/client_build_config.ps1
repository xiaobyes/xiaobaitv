function Get-PackageClientConfig([string]$Path) {
    $keys = @('XIAOBAI_TMDB_API_KEY', 'XIAOBAI_DANMAKU_URL', 'XIAOBAI_DANMAKU_TOKEN', 'XIAOBAI_SEGMENTS_URL', 'XIAOBAI_SEGMENTS_TOKEN')
    $optionalKeys = @('XIAOBAI_DANMAKU_SECONDARY_URL')
    if (!(Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Missing client build configuration file.' }
    $values = @{}
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -notmatch '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') { continue }
        $key, $raw = $Matches[1], $Matches[2]
        if ($key -cnotin $keys -and $key -cnotin $optionalKeys) { continue }
        if ($values.ContainsKey($key)) { throw "Duplicate client configuration: $key" }
        if ($raw -match '^(["''])(.*?)\1\s*(?:#.*)?$') { $values[$key] = $Matches[2] }
        elseif ($raw -match '^["'']') { throw "Invalid client configuration: $key" }
        else { $values[$key] = $raw.Split('#')[0].Trim() }
    }
    foreach ($key in $keys) {
        if ([string]::IsNullOrWhiteSpace($values[$key])) { throw "Missing client configuration: $key" }
    }
    if ($values.XIAOBAI_TMDB_API_KEY -notmatch '^[0-9a-f]{32}$') { throw 'Invalid client configuration: XIAOBAI_TMDB_API_KEY' }
    foreach ($key in $optionalKeys) {
        if ([string]::IsNullOrWhiteSpace($values[$key])) { $values.Remove($key) }
    }
    return $values
}

function Assert-PackageClientConfig([hashtable]$Config, [string]$AotPath) {
    $latin = [Text.Encoding]::GetEncoding(28591)
    $binary = $latin.GetString([IO.File]::ReadAllBytes($AotPath))
    foreach ($key in $Config.Keys) {
        $found = $false
        foreach ($encoding in @([Text.Encoding]::UTF8, [Text.Encoding]::Unicode)) {
            $needle = $latin.GetString($encoding.GetBytes($Config[$key]))
            if ($binary.IndexOf($needle, [StringComparison]::Ordinal) -ge 0) { $found = $true; break }
        }
        if (!$found) { throw "Compiled client configuration missing or stale: $key" }
    }
}
