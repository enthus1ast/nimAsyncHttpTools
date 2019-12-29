# To run these tests, simply execute `nimble test`.

import unittest

import asyncHttpTools
suite "matcher":
  setup:
    var matchTable = newMatchTable()
  test "one match":
    check match("/page/100/detail", "/page/@id/detail", matchTable) == true
    check matchTable["id"] == "100"
  test "two matches":
    check match("/page/100/foo", "/page/@id/@more", matchTable) == true
    check matchTable["id"] == "100"
    check matchTable["more"] == "foo"
  test "missing match":
    check match("/page/100/", "/page/@id/@more", matchTable) == true
    check matchTable["more"] == ""
  test "no match":
      check match("/page/100/info", "/page/@id/detail", matchTable) == false
      check match("/page/100/detail/baa", "/page/@id/detail", matchTable) == false
      check match("/page/100/detai", "/page/@id/detail", matchTable) == false
  test "///":
    check match("///", "//@id/", matchTable) == true
  test "other prefix":
    check match("/page/100/detail", "/page/$id/detail", matchTable, catchPrefix = '$') == true
    check matchTable["id"] == "100"
