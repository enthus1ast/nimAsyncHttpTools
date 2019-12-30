import asyncdispatch, asynchttpserver, os, md5, asyncfile
import mimetypes
import logging
import strutils

type 
  Range = tuple
    a: int
    b: int

let mime = newMimetypes() 

proc redirect(req: Request, code: HttpCode, path: string) {.async.} =
  let headers = newHttpHeaders([("location", path)])
  await req.respond(code, "", headers)

proc redirectPerm*(req: Request, path: string) {.async.} = 
  ## redirects the browser to the given url in path
  await req.redirect(Http301, path)

proc redirectTemp*(req: Request, path: string) {.async.} = 
  ## redirects the browser to the given url in path
  await req.redirect(Http302, path)

proc len(range: Range): int =
  return (range.b+1) - range.a

proc computeRange(byteCount: int, rangeSyntax: string): Range =
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

proc readRange(file: File, rng: Range): string =
  # var buf = alloc(rng.len)
  file.setFilePos(rng.a)
  var buf: seq[char] = @[]
  buf.setLen(rng.len)
  let byteCnt = file.readChars(buf, 0, rng.len)
  result = cast[string](buf)
  result.setLen(byteCnt)
  # let byteCnt = file.readBuffer(buf, rng.len)
  # result = (cast[string](buf))
  # echo result

  # result.setLen(byteCnt)
  # dealloc(buf)

proc readRange(path: string, rng: Range): string =
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
    # echo "serving static file: '${path}'" % ["path", path]

    if req.headers.hasKey("range"):
      echo $(req.headers.getOrDefault("range").extractRangeFromHeader)
      let rng = computeRange(fileSize.int, $(req.headers.getOrDefault("range").extractRangeFromHeader()))
      headers["content-length"] = $(rng.len)
      headers["Content-Range"] = "bytes $#-$#/$#" % [$rng.a, $rng.b, $fileSize] 
      # # await req.respond(Http200, $readFile(path), headers = headers) 
      # echo $rng
      # echo $(rng.len)
      await req.respond(Http206, $readRange(path, rng), headers = headers)  
    else:
      await req.respond(Http200, $readFile(path), headers = headers) 
    # await req.respond(Http200, $readRange(path, rng), headers = headers)  
    return true
  else:
    return false

###################################################
# TESTS
###################################################
when isMainModule:

  import unittest
  test "content length":
    check computeRange(2000, "0-1023").len == 1024
    check computeRange(2000, "0-50").len == 51
    check computeRange(2000, "1-50").len == 50
    check computeRange(2000, "-50").len == 50
    check computeRange(1256, "50-").len == 1206

  suite "reading":
    setup:
      let testpath = "tests/data1.txt" 
      let data1size = getFileSize(testpath).int
    test "test read":
      let testRange = computeRange(data1size, "0-4")
      check readRange(testpath, testRange).len() == testRange.len()
      check readRange(testpath, testRange) == "AAAAA"
    test "test read not a == 0":
      let testRange = computeRange(data1size, "1-5")
      check readRange(testpath, testRange).len() == testRange.len()
      check readRange(testpath, testRange) == "AAAAB"
    test "test read last 5 bytes":
      let testRange = computeRange(data1size, "-5")
      check testRange.len == 5
      check readRange(testpath, testRange).len() == testRange.len()
      check readRange(testpath, testRange) == "CCCCC"  
    test "test read last 1 byte":
      let testRange = computeRange(data1size, "-1")
      check testRange.len == 1
      check readRange(testpath, testRange).len() == testRange.len()
      check readRange(testpath, testRange) == "C"  
    # test "test read last 1 byte":
    #   let testRange = computeRange(data1size, "-1")
    #   check testRange.len == 1
    #   check readRange(testpath, testRange).len() == testRange.len()
    #   check readRange(testpath, testRange) == "C"  


  ###################################################
  # INFOS
  ###################################################

  # TODO byteranges!
  # https://www.phpgangsta.de/http-range-request-header-in-php-parsen
  # Range: bytes=0-500                 // Die ersten 500 Bytes
  # Range: bytes=-500                  // Die letzten 500 Bytes (nicht 0-500!)
  # Range: bytes=500-                  // Ab Byte 500 bis zum Ende
  # Range: bytes=0-500,1000-1499,-200  // Die ersten 500 Bytes, von Byte 1000 bis 1499, und die letzten 200 Bytes

  # if (isset($_SERVER['HTTP_RANGE'])) {
  #     if (!preg_match('^bytes=\d*-\d*(,\d*-\d*)*$', $_SERVER['HTTP_RANGE'])) {
  #         header('HTTP/1.1 416 Requested Range Not Satisfiable');
  #         header('Content-Range: bytes */' . filelength); // Required in 416.
  #         exit;
  #     }
  
  #     $ranges = explode(',', substr($_SERVER['HTTP_RANGE'], 6));
  #     foreach ($ranges as $range) {
  #         $parts = explode('-', $range);
  #         $start = $parts[0]; // If this is empty, this should be 0.
  #         $end = $parts[1]; // If this is empty or greater than than filelength - 1, this should be filelength - 1.
  
  #         if ($start > $end) {
  #             header('HTTP/1.1 416 Requested Range Not Satisfiable');
  #             header('Content-Range: bytes */' . filelength); // Required in 416.
  #             exit;
  #         }
  
  #         // ...
  #     }
  # }



  # proc sendStaticIfExists(
  #   req: Request, paths: seq[string]
  # ): Future[HttpCode] {.async.} =
  #   result = Http200

    # for p in paths:
    #   if existsFile(p):

    #     var fp = getFilePermissions(p)
    #     if not fp.contains(fpOthersRead):
    #       return Http403

    #     let fileSize = getFileSize(p)
    #     # let mimetype = req.settings.mimes.getMimetype(p.splitFile.ext[1 .. ^1])
    #     let mimetype = "application/text"
    #     if fileSize < 10_000_000: # 10 mb
    #       var file = readFile(p)

    #       var hashed = getMD5(file)

    #       # # If the user has a cached version of this file and it matches our
    #       # # version, let them use it
    #       # if req.headers.hasKey("If-None-Match") and req.headers["If-None-Match"] == hashed:
    #       #   req.statusContent(Http304, "", none[RawHeaders]())
    #       # else:
    #       #   req.statusContent(Http200, file, some(@({
    #       #                       "Content-Type": mimetype,
    #       #                       "ETag": hashed
    #       #                     })))
    #     else:
    #       let headers = @({
    #         "Content-Type": mimetype,
    #         "Content-Length": $fileSize
    #       })
    #       # req.statusContent(Http200, "", some(headers))

    #       var fileStream = newFutureStream[string]("sendStaticIfExists")
    #       var file = openAsync(p, fmRead)
    #       # Let `readToStream` write file data into fileStream in the
    #       # background.
    #       asyncCheck file.readToStream(fileStream)
    #       # The `writeFromStream` proc will complete once all the data in the
    #       # `bodyStream` has been written to the file.
    #       while true:
    #         let (hasValue, value) = await fileStream.read()
    #         if hasValue:
    #           req.unsafeSend(value)
    #         else:
    #           break
    #       file.close()

    #     return

    # # If we get to here then no match could be found.
    # return Http404