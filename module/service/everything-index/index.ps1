#!@powershell@/bin/pwsh

if ($args.Length -ne 0) {
  Set-Location $args[0]
}

$files = Get-ChildItem -File -Recurse
$entries = @($files | % {
  New-Object PsObject -Property (
    [ordered] @{
      Filename = Resolve-Path -Relative $_.FullName;
      Size = $_.Size;
      "Date Modified" = $_.LastWriteTime.ToFileTime();
      "Date Created" = $_.CreationTime.ToFileTime();
      Attributes = $_.Attributes.value__;
    }
  )
})

$entries | Export-Csv -Path ./.index.efu.new
Move-Item -Force -Path ./.index.efu.new -Destination ./.index.efu
