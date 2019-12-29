import parseutils, tables, cgi, asynchttpserver

type Query = Table[string, string]

proc parseUrlQuery*(query: string, result: var Table[string, string])
    {.deprecated: "use stdlib".} =
  ## https://github.com/dom96/jester/blob/master/jester/private/utils.nim
  var i = 0
  i = query.skip("?")
  while i < query.len()-1:
    var key = ""
    var val = ""
    i += query.parseUntil(key, '=', i)
    if query[i] != '=':
      raise newException(ValueError, "Expected '=' at " & $i &
                         " but got: " & $query[i])
    inc(i) # Skip =
    i += query.parseUntil(val, '&', i)
    inc(i) # Skip &
    result[decodeUrl(key)] = decodeUrl(val)

proc parseUrlQuery*(req: Request): Query =
  result = initTable[string, string]()
  parseUrlQuery(req.url.query, result)