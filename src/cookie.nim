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
  ## Parses a cookie transmitted by the browser to the server
  if request.headers.hasKey("Cookie"):
    return parseCookies(request.headers["Cookie"])
  else:
    return newStringTable()

# proc makeCookie*(cookie: Cookie): string = 
#   ## Makes a cookie to send to the browser

# type
#   SameSite* = enum
#     None, Lax, Strict

# proc makeCookie*(key, value, expires: string, domain = "", path = "",
#                  secure = false, httpOnly = false,
#                  sameSite = Lax): string =
#   ## Creates 
#   # https://github.com/dom96/jester/blob/master/jester/private/utils.nim
#   result = ""
#   result.add key & "=" & value
#   if domain != "": result.add("; Domain=" & domain)
#   if path != "": result.add("; Path=" & path)
#   if expires != "": result.add("; Expires=" & expires)
#   if secure: result.add("; Secure")
#   if httpOnly: result.add("; HttpOnly")
#   if sameSite != None:
#     result.add("; SameSite=" & $sameSite)

# TODO
proc addCookie*(headers: var HttpHeaders, data: StringTableRef) = 
  ## adds cookies to the HttpHeaders.
  # format(expires.utc, "ddd',' dd MMM yyyy HH:mm:ss 'GMT'")
  headers["Set-Cookie"] = @[] # @[line
  var lines: seq[string] = @[]
  for key, val in data:
    lines.add key & "=" & val.encodeUrl & ";"
  headers["Set-Cookie"] = lines
# var headers = newHttpHeaders()
# headers.addCookie({"name": "John", "city": "Monaco"}.newStringTable)
# echo headers["set-cookie"]
# echo headers

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


