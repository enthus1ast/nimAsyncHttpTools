# Package

version       = "0.1.3"
author        = "David Krause"
description   = "Small tools for stdlib asynchttpserver"
license       = "MIT"
srcDir        = "src"
installExt = @["nim"]
bin = @["simplehttpserver"]


# Dependencies

requires "nim >= 1.0.9"
requires "https://github.com/johnscillieri/psutil-nim.git"
requires "https://github.com/onionhammer/nim-templates.git"

