# To run these tests, simply execute `nimble test`.
import unittest
import asyncHttpTools
import os

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

suite "range":
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