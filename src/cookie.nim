import cookies
export cookies

import strtabs
export strtabs

import cgi # for decodeData
import uri # for encodeQuery 

import asynchttpserver

type 
  Cookie* = StringTableRef

proc parseCookies*(request: Request): Cookie = 
  if request.headers.hasKey("Cookie"):
    return parseCookies(request.headers["Cookie"])
  else:
    return newStringTable()
    
proc decodeData*(data: string): StringTableRef = 
  ## Decodes form data into a StringTable
  ## TODO dublicated keys are not supported
  result = newStringTable()
  for key, val in decodeData(data):
    result[$key] = $val

proc encodeData*(tab: StringTableRef, usePlus = false; omitEq = true): string =
  ## Encodes a StringTable into a form data string
  var dat: seq[(string, string)] = @[]
  for key, val in tab:
    dat.add( (key, val) )
  return encodeQuery(dat)
  