
# Return human readable size of file object
Function Human-FileSize() {
  Param ($file)
  if(!$file.PSIsContainer) {
    switch($file.length) {
      { $_ -gt 1tb }
      { "{0:n1} T" -f ($_ / 1TB) }
      { $_ -gt 1gb }
      { "{0:n1} G" -f ($_ / 1GB) }
      { $_ -gt 1mb }
      { "{0:n1} M " -f ($_ / 1MB) }
      { $_ -gt 1kb }
      { "{0:n1} K " -f ($_ / 1KB) }
      default
      { "{0:n1} B " -f $_}
    }
  } elseif ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { #links
    "<SYMLINK> "
  } else { #directory
    "<DIR> "
  }
}
