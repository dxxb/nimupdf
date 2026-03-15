## Extract text from a PDF file and print it to stdout.
##
## Usage: extract_text <file.pdf>

import std/os
import nimupdf

proc main() =
  if paramCount() < 1:
    stderr.writeLine "Usage: extract_text <file.pdf>"
    quit(1)

  let path = paramStr(1)
  if not fileExists(path):
    stderr.writeLine "File not found: " & path
    quit(1)

  let ctx = newMuPdfContext()
  let doc = ctx.open(path)

  echo "Format:  ", doc.metadata("format")
  echo "Title:   ", doc.metadata("info:Title")
  echo "Author:  ", doc.metadata("info:Author")
  echo "Pages:   ", doc.pageCount
  echo "---"

  for page in doc.pages:
    let r = page.bounds
    echo "Page ", page.number, " (", r.x1 - r.x0, " x ", r.y1 - r.y0, ")"
    echo page.extractText()

  doc.close()
  ctx.close()

when isMainModule:
  main()
