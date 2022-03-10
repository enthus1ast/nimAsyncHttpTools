import nimLocalIp
import net, strutils

proc formatLine(host: string, port: Port): string =
  return "-> http://${ip}:${port}" % ["ip", host, "port", $port.int]

proc genListening*(host: string, port: Port): string =
  ## Generates information about all listening addresses
  result = ""
  result.add "Listening on: \n"
  if host == "0.0.0.0":
    for ip in getLocalIps():
      result.add formatLine(ip, port) & "\n"
  else:
    result.add formatLine(host, port) & "\n"
  result.add "\n"
