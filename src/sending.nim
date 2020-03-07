import asyncdispatch, asynchttpserver, os, md5, asyncfile
import mimetypes
import logging
import strutils
import asyncfile
import asyncnet

type
  Range = tuple
    a: int
    b: int

let mime = newMimetypes()

proc redirect(req: Request, code: HttpCode, path: string, headers = newHttpHeaders()) {.async.} =
  headers["location"] = path
  await req.respond(code, "", headers)

proc redirectPerm*(req: Request, path: string, headers = newHttpHeaders()) {.async.} =
  ## redirects the browser to the given url in path
  await req.redirect(Http301, path, headers)

proc redirectTemp*(req: Request, path: string, headers = newHttpHeaders()) {.async.} =
  ## redirects the browser to the given url in path
  await req.redirect(Http302, path, headers)

proc len*(range: Range): int =
  ## returns the amount of a bytes a byte range has
  return (range.b+1) - range.a

proc computeRange*(byteCount: int, rangeSyntax: string): Range =
  if not rangeSyntax.contains("-"):
    # Invalid byte range syntax!
    return (0, byteCount-1)
  let parts = rangeSyntax.split("-")

  # the last `b` bytes
  if parts[0] == "":
    return (byteCount-(parts[1]).parseInt(), byteCount-1)

  # from `a` to end
  if parts[1] == "":
    return (parts[0].parseInt(), byteCount-1)

  return (parts[0].parseInt(), parts[1].parseInt())

proc readRange*(file: File, rng: Range): string =
  ## reads from a file with the given Range
  file.setFilePos(rng.a)
  var buf: seq[char] = @[]
  buf.setLen(rng.len)
  let byteCnt = file.readChars(buf, 0, rng.len)
  result = cast[string](buf)
  result.setLen(byteCnt)

proc readRange*(path: string, rng: Range): string =
  ## reads from a path with the given Range
  var file = open(path, fmRead)
  result = file.readRange(rng)
  file.close()

proc extractRangeFromHeader(str: string): string =
  str.replace("bytes=", "")

proc sendStaticIfExists*(req: Request, path: string): Future[bool] {.async, gcsafe.} =
  # TODO serve static files like jester
  # TODO serve byte ranges
  if fileExists(path):
    let fileSize = getFileSize(path)
    let mimetype = mime.getMimeType(splitFile(path).ext)
    var headers = newHttpHeaders([
      ("Content-Type", mimetype),
      # ("Content-Length", $fileSize),
      ("Accept-Ranges", "bytes")
      ])
    if req.headers.hasKey("range"):
      echo $(req.headers.getOrDefault("range").extractRangeFromHeader)
      let rng = computeRange(fileSize.int, $(req.headers.getOrDefault("range").extractRangeFromHeader()))
      headers["content-length"] = $(rng.len)
      headers["Content-Range"] = "bytes $#-$#/$#" % [$rng.a, $rng.b, $fileSize]
      await req.respond(Http206, $readRange(path, rng), headers = headers)
    else:
      let file = openAsync(path, fmRead)
      let cont = await readAll(file)
      if req.client.isClosed():
        return true
      await req.respond(Http200, cont, headers = headers)
      req.client.close()

    return true
  else:
    return false
