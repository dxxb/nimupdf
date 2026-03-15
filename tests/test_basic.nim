## Basic tests for nimupdf bindings.

import std/[os, strutils, unittest]
import nimupdf
import nimupdf/fitz

const testDir = currentSourcePath().parentDir.parentDir.parentDir /
    "Boarding Passes 2025"

proc findTestPdf(): string =
  if dirExists(testDir):
    for f in walkDir(testDir):
      if f.path.endsWith(".pdf"):
        return f.path

suite "MuPDF context":
  test "create and close context":
    let ctx = newMuPdfContext()
    check ctx.raw != nil
    ctx.close()
    check ctx.raw == nil

  test "create context with custom store size":
    let ctx = newMuPdfContext(FZ_STORE_UNLIMITED)
    check ctx.raw != nil
    ctx.close()

  test "double close is safe":
    let ctx = newMuPdfContext()
    ctx.close()
    ctx.close()

suite "MuPDF document":
  test "open non-existent file raises":
    let ctx = newMuPdfContext()
    var raised = false
    try:
      discard ctx.open("/tmp/nonexistent_12345.pdf")
    except MuPdfError:
      raised = true
    check raised
    ctx.close()

suite "PDF text extraction":
  let testPdf = findTestPdf()
  let havePdf = testPdf.len > 0

  test "extract text from boarding pass":
    if havePdf:
      let ctx = newMuPdfContext()
      let doc = ctx.open(testPdf)
      check doc.pageCount >= 1
      let text = doc.extractText()
      check text.len > 0
      doc.close()
      ctx.close()
    else:
      skip()

  test "page iteration":
    if havePdf:
      let ctx = newMuPdfContext()
      let doc = ctx.open(testPdf)
      var count = 0
      for page in doc.pages:
        inc count
        let r = page.bounds
        check r.x1 > r.x0
        check r.y1 > r.y0
      check count == doc.pageCount
    else:
      skip()

  test "metadata query":
    if havePdf:
      let ctx = newMuPdfContext()
      let doc = ctx.open(testPdf)
      let fmt = doc.metadata("format")
      check fmt.len > 0
      doc.close()
      ctx.close()
    else:
      skip()

  test "convenience extractText":
    if havePdf:
      let text = extractText(testPdf)
      check text.len > 0
    else:
      skip()
