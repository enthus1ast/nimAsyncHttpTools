import asyncdispatch, asynchttpserver, os, md5, asyncfile
import dbg

proc sendStaticIfExists*(req: Request, path: string): Future[bool] {.async.} = 
  # TODO serve static files like jester
  # TODO serve byte ranges
  if fileExists(path):
    dbg "serving static file: ", path
    await req.respond(Http200, await readAll(path))  
    return true
  else:
    return false

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