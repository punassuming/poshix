
# Return human readable size of file object
Function hfs() {
  Param ($file)
  if(!$file.PSIsContainer) {
    switch($file.length) {
      {$_ -gt 1tb}
      { "{0:n1} T " -f ($_ / 1TB); continue }
      {$_ -gt 1gb}
      { "{0:n1} G " -f ($_ / 1GB); continue }
      {$_ -gt 1mb}
      { "{0:n1} M " -f ($_ / 1MB); continue }
      {$_ -gt 1kb}
      { "{0:n1} K " -f ($_ / 1KB); continue }
      default
      { "{0:n1} B " -f $_ }
    }
  } elseif ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { #links
    "<SYMLINK> "
  } else { #directory
    "<DIR> "
  }
}

function dbg ($Message, [Diagnostics.Stopwatch]$Stopwatch) {
  if($Stopwatch) {
    Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose # -ForegroundColor Yellow
  }
}
