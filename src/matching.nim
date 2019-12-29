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
