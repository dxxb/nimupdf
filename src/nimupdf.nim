## nimupdf — Idiomatic Nim wrapper around MuPDF (libmupdf).
##
## Provides safe, RAII-style access to PDF documents for text extraction,
## metadata queries, and page inspection.
##
## .. code-block:: nim
##   import nimupdf
##   echo extractText("document.pdf")

import nimupdf/fitz
export fitz.FzRect, fitz.FzMatrix, fitz.FzPoint, fitz.FzQuad,
       fitz.FZ_STEXT_PRESERVE_LIGATURES, fitz.FZ_STEXT_PRESERVE_WHITESPACE,
       fitz.FZ_STEXT_PRESERVE_IMAGES, fitz.FZ_STEXT_INHIBIT_SPACES,
       fitz.FZ_STEXT_DEHYPHENATE, fitz.FZ_STEXT_PRESERVE_SPANS

# ---------------------------------------------------------------------------
# Error handling helpers
# ---------------------------------------------------------------------------

type
  MuPdfError* = object of CatchableError

const ErrBufLen = 512

proc checkMuPdf(rc: cint; errbuf: array[ErrBufLen, char]) =
  if rc != 0:
    raise newException(MuPdfError, $cast[cstring](unsafeAddr errbuf[0]))

# ---------------------------------------------------------------------------
# Context
# ---------------------------------------------------------------------------

type MuPdfContext* = ref object
  raw*: ptr FzContext

proc close*(c: MuPdfContext) =
  ## Release the context resources immediately.
  if c.raw != nil:
    fz_drop_context(c.raw)
    c.raw = nil

proc newMuPdfContext*(storeSize: csize_t = FZ_STORE_DEFAULT): MuPdfContext =
  ## Create a new MuPDF context. One context should be created per thread.
  let ctx = fzNewContext(storeSize)
  if ctx == nil:
    raise newException(MuPdfError, "failed to create MuPDF context")
  fz_register_document_handlers(ctx)
  result = MuPdfContext(raw: ctx)

# ---------------------------------------------------------------------------
# Document
# ---------------------------------------------------------------------------

type MuPdfDocument* = ref object
  ctx*: MuPdfContext
  raw*: ptr FzDocument
  path*: string

proc close*(d: MuPdfDocument) =
  ## Release the document resources immediately.
  if d.raw != nil and d.ctx != nil and d.ctx.raw != nil:
    fz_drop_document(d.ctx.raw, d.raw)
    d.raw = nil

proc open*(ctx: MuPdfContext; path: string): MuPdfDocument =
  ## Open a document (PDF, XPS, EPUB, etc.) from a file path.
  var doc: ptr FzDocument
  var errbuf: array[ErrBufLen, char]
  checkMuPdf(nimupdf_open_document(ctx.raw, path.cstring, addr doc,
      cast[cstring](addr errbuf[0]), ErrBufLen.cint), errbuf)
  result = MuPdfDocument(ctx: ctx, raw: doc, path: path)

proc pageCount*(doc: MuPdfDocument): int =
  ## Return the total number of pages in the document.
  var count: cint
  var errbuf: array[ErrBufLen, char]
  checkMuPdf(nimupdf_count_pages(doc.ctx.raw, doc.raw, addr count,
      cast[cstring](addr errbuf[0]), ErrBufLen.cint), errbuf)
  int(count)

proc needsPassword*(doc: MuPdfDocument): bool =
  fz_needs_password(doc.ctx.raw, doc.raw) != 0

proc authenticate*(doc: MuPdfDocument; password: string): bool =
  fz_authenticate_password(doc.ctx.raw, doc.raw, password.cstring) != 0

proc metadata*(doc: MuPdfDocument; key: string): string =
  ## Retrieve a metadata value by key.
  ## Common keys: ``FZ_META_FORMAT``, ``FZ_META_INFO_TITLE``, etc.
  var buf: array[512, char]
  var errbuf: array[ErrBufLen, char]
  let n = nimupdf_lookup_metadata(doc.ctx.raw, doc.raw, key.cstring,
      cast[cstring](addr buf[0]), buf.len.cint,
      cast[cstring](addr errbuf[0]), ErrBufLen.cint)
  if n > 0:
    result = $cast[cstring](addr buf[0])

# ---------------------------------------------------------------------------
# Page
# ---------------------------------------------------------------------------

type MuPdfPage* = ref object
  doc*: MuPdfDocument
  raw*: ptr FzPage
  number*: int

proc close*(p: MuPdfPage) =
  ## Release the page resources immediately.
  if p.raw != nil and p.doc != nil and p.doc.ctx != nil and
      p.doc.ctx.raw != nil:
    fz_drop_page(p.doc.ctx.raw, p.raw)
    p.raw = nil

proc loadPage*(doc: MuPdfDocument; pageNum: int): MuPdfPage =
  ## Load a page by zero-based index.
  var page: ptr FzPage
  var errbuf: array[ErrBufLen, char]
  checkMuPdf(nimupdf_load_page(doc.ctx.raw, doc.raw, pageNum.cint,
      addr page, cast[cstring](addr errbuf[0]), ErrBufLen.cint), errbuf)
  result = MuPdfPage(doc: doc, raw: page, number: pageNum)

proc bounds*(page: MuPdfPage): FzRect =
  var errbuf: array[ErrBufLen, char]
  checkMuPdf(nimupdf_bound_page(page.doc.ctx.raw, page.raw,
      addr result, cast[cstring](addr errbuf[0]), ErrBufLen.cint), errbuf)

# ---------------------------------------------------------------------------
# Text extraction
# ---------------------------------------------------------------------------

type
  StextFlags* = enum
    sfPreserveLigatures
    sfPreserveWhitespace
    sfPreserveImages
    sfInhibitSpaces
    sfDehyphenate
    sfPreserveSpans

proc toInt(flags: set[StextFlags]): cint =
  if sfPreserveLigatures in flags: result = result or FZ_STEXT_PRESERVE_LIGATURES
  if sfPreserveWhitespace in flags: result = result or FZ_STEXT_PRESERVE_WHITESPACE
  if sfPreserveImages in flags: result = result or FZ_STEXT_PRESERVE_IMAGES
  if sfInhibitSpaces in flags: result = result or FZ_STEXT_INHIBIT_SPACES
  if sfDehyphenate in flags: result = result or FZ_STEXT_DEHYPHENATE
  if sfPreserveSpans in flags: result = result or FZ_STEXT_PRESERVE_SPANS

proc extractText*(page: MuPdfPage;
    flags: set[StextFlags] = {}): string =
  ## Extract the text content of a single page.
  let ctx = page.doc.ctx.raw

  var textPtr: cstring
  var errbuf: array[ErrBufLen, char]
  checkMuPdf(nimupdf_extract_page_text(ctx, page.raw, flags.toInt,
      addr textPtr, cast[cstring](addr errbuf[0]), ErrBufLen.cint), errbuf)

  if textPtr != nil:
    result = $textPtr
    fz_free(ctx, textPtr)

proc extractText*(doc: MuPdfDocument;
    flags: set[StextFlags] = {}): string =
  ## Extract text from all pages, separated by form-feed characters.
  let n = doc.pageCount
  for i in 0 ..< n:
    let page = doc.loadPage(i)
    if i > 0:
      result.add '\f'
    result.add page.extractText(flags)

proc extractText*(path: string;
    flags: set[StextFlags] = {}): string =
  ## Convenience: open a PDF and extract all text in one call.
  let ctx = newMuPdfContext()
  let doc = ctx.open(path)
  doc.extractText(flags)

# ---------------------------------------------------------------------------
# Page iteration
# ---------------------------------------------------------------------------

iterator pages*(doc: MuPdfDocument): MuPdfPage =
  ## Iterate over all pages in the document.
  let n = doc.pageCount
  for i in 0 ..< n:
    yield doc.loadPage(i)
