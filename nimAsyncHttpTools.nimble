# Package

version       = "0.2.0"
author        = "David Krause"
description   = "Small tools for stdlib asynchttpserver"
license       = "MIT"
srcDir        = "src"
installExt = @["nim"]
# bin = @["simplehttpserver"] # Causes file already exists error when using as dependency in other projects

# Dependencies
requires "nim >= 1.4.8"
requires "https://github.com/enthus1ast/nimLocalIp.git"
requires "nimja"
