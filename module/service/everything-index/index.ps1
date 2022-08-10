#!@powershell@/bin/pwsh

if ($args.Length -ne 0) {
  Set-Location $args[0]
}

$index = "./.index.efu"
$newindex = "./.index.~efu"

Get-ChildItem -File -Recurse | % {
  New-Object PsObject -Property (
    [ordered] @{
      Filename = Resolve-Path -Relative -LiteralPath $_.FullName;
      Size = $_.Size;
      "Date Modified" = $_.LastWriteTime.ToFileTime();
      "Date Created" = $_.CreationTime.ToFileTime();
      Attributes = $_.Attributes.value__;
    }
  )
} | Export-Csv -Path $newindex

Move-Item -Force -Path $newindex -Destination $index
