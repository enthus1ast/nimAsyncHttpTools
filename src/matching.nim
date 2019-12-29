import strutils

import uri, tables
export uri, tables

type MatchTable* = TableRef[string, string]

proc match*(path, matcher: string, matchTable: MatchTable, catchPrefix = '@'): bool =
  matchTable.clear()
  let pa = path.split("/")
  let ma = matcher.split("/")
  if pa.len != ma.len: return false
  for idx in 0..pa.len-1:
    let pi = pa[idx]
    let mi = ma[idx]
    if mi.startsWith(catchPrefix):
      matchTable[mi[1..^1]] = pi
    elif pi == mi: continue
    else: return false
  return true

proc newMatchTable*(): MatchTable =
  return newTable[string, string]()

when isMainModule:    
  var matchTable = newMatchTable()

  assert match("/page/100/detail", "/page/@id/detail", matchTable) == true
  assert matchTable["id"] == "100"
  assert match("/page/100/foo", "/page/@id/@more", matchTable) == true
  assert matchTable["id"] == "100"
  assert matchTable["more"] == "foo"

  assert match("/page/100/", "/page/@id/@more", matchTable) == true
  assert matchTable["more"] == ""

  assert match("/page/100/info", "/page/@id/detail", matchTable) == false
  assert match("///", "//@id/", matchTable) == true
  assert match("/page/100/info", "/page/@id/detail", matchTable) == false
  assert match("/page/100/detail/baa", "/page/@id/detail", matchTable) == false
