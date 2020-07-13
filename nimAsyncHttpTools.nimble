# Package

version       = "0.1.7"
author        = "David Krause"
description   = "Small tools for stdlib asynchttpserver"
license       = "MIT"
srcDir        = "src"
installExt = @["nim"]
bin = @["simplehttpserver"]


# Dependencies

requires "nim >= 1.0.4"
requires "psutil >= 0.6.0"
requires "https://github.com/onionhammer/nim-templates.git"
