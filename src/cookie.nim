import cookies
export cookies

import strtabs
export strtabs

import asynchttpserver

type 
  Cookie* = StringTableRef

proc parseCookies*(request: Request): Cookie = 
  if request.headers.hasKey("Cookie"):
    return parseCookies(request.headers["Cookie"])
  else:
    return newStringTable()
    