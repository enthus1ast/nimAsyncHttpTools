import psutil, net, strutils

proc formatLine(host: string, port: Port): string =
  return "-> http://${ip}:${port}" % ["ip", host, "port", $port.int]

proc genListening*(host: string, port: Port): string = 
  ## Generates information about all listening addresses
  result = ""
  result.add "Listening on: \n"
  if host == "0.0.0.0":
    for ifname, addresses in net_if_addrs():
      result.add "\n"
      result.add ifname & ":\n"
      for address in addresses:
        result.add formatLine(address.address, port) & "\n"
  else:
    result.add formatLine(host, port) & "\n"
  result.add "\n"