## Low-level C FFI bindings to MuPDF's fitz library.
##
## These map directly to the C API declared in ``<mupdf/fitz.h>``.
## Prefer the high-level wrapper in ``nimupdf`` for typical usage.

import std/os

const wrapDir = currentSourcePath().parentDir

{.passC: "-I/usr/local/include -I/opt/homebrew/include \"-I" & wrapDir & "\"".}
{.passL: "-L/usr/local/lib -L/opt/homebrew/lib -lmupdf -lmupdf-third".}
{.compile: wrapDir / "fitz_wrap.c".}

# ---------------------------------------------------------------------------
# Opaque types (pointers to C structs)
# ---------------------------------------------------------------------------

type
  FzContext* {.importc: "fz_context", header: "<mupdf/fitz.h>", incompleteStruct.} = object
  FzDocument* {.importc: "fz_document", header: "<mupdf/fitz.h>", incompleteStruct.} = object
  FzPage* {.importc: "fz_page", header: "<mupdf/fitz.h>", incompleteStruct.} = object
  FzDevice* {.importc: "fz_device", header: "<mupdf/fitz.h>", incompleteStruct.} = object
  FzOutput* {.importc: "fz_output", header: "<mupdf/fitz.h>", incompleteStruct.} = object
  FzStream* {.importc: "fz_stream", header: "<mupdf/fitz.h>", incompleteStruct.} = object
  FzFont* {.importc: "fz_font", header: "<mupdf/fitz.h>", incompleteStruct.} = object
  FzImage* {.importc: "fz_image", header: "<mupdf/fitz.h>", incompleteStruct.} = object
  FzCookie* {.importc: "fz_cookie", header: "<mupdf/fitz.h>", incompleteStruct.} = object

# ---------------------------------------------------------------------------
# Value types
# ---------------------------------------------------------------------------

type
  FzRect* {.importc: "fz_rect", header: "<mupdf/fitz.h>".} = object
    x0*, y0*, x1*, y1*: cfloat

  FzIrect* {.importc: "fz_irect", header: "<mupdf/fitz.h>".} = object
    x0*, y0*, x1*, y1*: cint

  FzMatrix* {.importc: "fz_matrix", header: "<mupdf/fitz.h>".} = object
    a*, b*, c*, d*, e*, f*: cfloat

  FzPoint* {.importc: "fz_point", header: "<mupdf/fitz.h>".} = object
    x*, y*: cfloat

  FzQuad* {.importc: "fz_quad", header: "<mupdf/fitz.h>".} = object
    ul*, ur*, ll*, lr*: FzPoint

  FzLocation* {.importc: "fz_location", header: "<mupdf/fitz.h>".} = object
    chapter*, page*: cint

  FzBuffer* {.importc: "fz_buffer", header: "<mupdf/fitz.h>", incompleteStruct.} = object

# ---------------------------------------------------------------------------
# Structured text types
# ---------------------------------------------------------------------------

type
  FzStextPage* {.importc: "fz_stext_page", header: "<mupdf/fitz.h>", incompleteStruct.} = object

  FzStextOptions* {.importc: "fz_stext_options", header: "<mupdf/fitz.h>".} = object
    flags*: cint
    scale*: cfloat
    clip*: FzRect

# ---------------------------------------------------------------------------
# Structured text option flags
# ---------------------------------------------------------------------------

const
  FZ_STEXT_PRESERVE_LIGATURES* = 1.cint
  FZ_STEXT_PRESERVE_WHITESPACE* = 2.cint
  FZ_STEXT_PRESERVE_IMAGES* = 4.cint
  FZ_STEXT_INHIBIT_SPACES* = 8.cint
  FZ_STEXT_DEHYPHENATE* = 16.cint
  FZ_STEXT_PRESERVE_SPANS* = 32.cint
  FZ_STEXT_COLLECT_STRUCTURE* = 256.cint

# ---------------------------------------------------------------------------
# Store size constants
# ---------------------------------------------------------------------------

const
  FZ_STORE_UNLIMITED* = 0.csize_t
  FZ_STORE_DEFAULT* = (256 shl 20).csize_t

# ---------------------------------------------------------------------------
# Global constants (extern in C)
# ---------------------------------------------------------------------------

var fz_identity* {.importc, header: "<mupdf/fitz.h>".}: FzMatrix
var fz_empty_rect* {.importc, header: "<mupdf/fitz.h>".}: FzRect
var fz_infinite_rect* {.importc, header: "<mupdf/fitz.h>".}: FzRect

# ---------------------------------------------------------------------------
# Context
# ---------------------------------------------------------------------------

proc fz_new_context_imp*(alloc: pointer; locks: pointer;
    max_store: csize_t; version: cstring): ptr FzContext
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_drop_context*(ctx: ptr FzContext)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_clone_context*(ctx: ptr FzContext): ptr FzContext
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_register_document_handlers*(ctx: ptr FzContext)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Document
# ---------------------------------------------------------------------------

proc fz_open_document*(ctx: ptr FzContext; filename: cstring): ptr FzDocument
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_open_document_with_stream*(ctx: ptr FzContext; magic: cstring;
    stream: ptr FzStream): ptr FzDocument
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_open_document_with_buffer*(ctx: ptr FzContext; magic: cstring;
    buffer: ptr FzBuffer): ptr FzDocument
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_drop_document*(ctx: ptr FzContext; doc: ptr FzDocument)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_keep_document*(ctx: ptr FzContext; doc: ptr FzDocument): ptr FzDocument
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_count_pages*(ctx: ptr FzContext; doc: ptr FzDocument): cint
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_needs_password*(ctx: ptr FzContext; doc: ptr FzDocument): cint
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_authenticate_password*(ctx: ptr FzContext; doc: ptr FzDocument;
    password: cstring): cint
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_lookup_metadata*(ctx: ptr FzContext; doc: ptr FzDocument;
    key: cstring; buf: cstring; size: csize_t): cint
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Page
# ---------------------------------------------------------------------------

proc fz_load_page*(ctx: ptr FzContext; doc: ptr FzDocument;
    number: cint): ptr FzPage
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_drop_page*(ctx: ptr FzContext; page: ptr FzPage)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_bound_page*(ctx: ptr FzContext; page: ptr FzPage): FzRect
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_run_page*(ctx: ptr FzContext; page: ptr FzPage; dev: ptr FzDevice;
    transform: FzMatrix; cookie: ptr FzCookie)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_run_page_contents*(ctx: ptr FzContext; page: ptr FzPage;
    dev: ptr FzDevice; transform: FzMatrix; cookie: ptr FzCookie)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Structured text
# ---------------------------------------------------------------------------

proc fz_new_stext_page*(ctx: ptr FzContext;
    mediabox: FzRect): ptr FzStextPage
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_drop_stext_page*(ctx: ptr FzContext; page: ptr FzStextPage)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_new_stext_device*(ctx: ptr FzContext; page: ptr FzStextPage;
    options: ptr FzStextOptions): ptr FzDevice
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_print_stext_page_as_text*(ctx: ptr FzContext; output: ptr FzOutput;
    page: ptr FzStextPage)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_print_stext_page_as_html*(ctx: ptr FzContext; output: ptr FzOutput;
    page: ptr FzStextPage; id: cint)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_print_stext_page_as_xml*(ctx: ptr FzContext; output: ptr FzOutput;
    page: ptr FzStextPage; id: cint)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_print_stext_page_as_json*(ctx: ptr FzContext; output: ptr FzOutput;
    page: ptr FzStextPage; scale: cfloat)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Buffer
# ---------------------------------------------------------------------------

proc fz_new_buffer*(ctx: ptr FzContext; capacity: csize_t): ptr FzBuffer
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_drop_buffer*(ctx: ptr FzContext; buf: ptr FzBuffer)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_string_from_buffer*(ctx: ptr FzContext;
    buf: ptr FzBuffer): cstring
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_buffer_storage*(ctx: ptr FzContext; buf: ptr FzBuffer;
    datap: ptr ptr uint8): csize_t
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_terminate_buffer*(ctx: ptr FzContext; buf: ptr FzBuffer)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_new_buffer_from_copied_data*(ctx: ptr FzContext;
    data: ptr uint8; size: csize_t): ptr FzBuffer
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

proc fz_new_output_with_buffer*(ctx: ptr FzContext;
    buf: ptr FzBuffer): ptr FzOutput
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_close_output*(ctx: ptr FzContext; output: ptr FzOutput)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_drop_output*(ctx: ptr FzContext; output: ptr FzOutput)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_stdout*(ctx: ptr FzContext): ptr FzOutput
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Stream
# ---------------------------------------------------------------------------

proc fz_open_file*(ctx: ptr FzContext; filename: cstring): ptr FzStream
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_open_memory*(ctx: ptr FzContext; data: ptr uint8;
    len: csize_t): ptr FzStream
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_open_buffer*(ctx: ptr FzContext; buf: ptr FzBuffer): ptr FzStream
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_drop_stream*(ctx: ptr FzContext; stm: ptr FzStream)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Device
# ---------------------------------------------------------------------------

proc fz_close_device*(ctx: ptr FzContext; dev: ptr FzDevice)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_drop_device*(ctx: ptr FzContext; dev: ptr FzDevice)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Error handling
# ---------------------------------------------------------------------------

proc fz_caught_message*(ctx: ptr FzContext): cstring
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_caught*(ctx: ptr FzContext): cint
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_report_error*(ctx: ptr FzContext)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

proc fz_ignore_error*(ctx: ptr FzContext)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Metadata keys
# ---------------------------------------------------------------------------

const
  FZ_META_FORMAT* = "format"
  FZ_META_ENCRYPTION* = "encryption"
  FZ_META_INFO_TITLE* = "info:Title"
  FZ_META_INFO_AUTHOR* = "info:Author"
  FZ_META_INFO_SUBJECT* = "info:Subject"
  FZ_META_INFO_KEYWORDS* = "info:Keywords"
  FZ_META_INFO_CREATOR* = "info:Creator"
  FZ_META_INFO_PRODUCER* = "info:Producer"

# ---------------------------------------------------------------------------
# Memory
# ---------------------------------------------------------------------------

proc fz_free*(ctx: ptr FzContext; p: pointer)
    {.importc, cdecl, header: "<mupdf/fitz.h>".}

# ---------------------------------------------------------------------------
# Convenience: fz_new_context wraps fz_new_context_imp with the version
# ---------------------------------------------------------------------------

proc nimupdf_fz_version*(): cstring
    {.importc, cdecl, header: "fitz_wrap.h".}

proc fzNewContext*(maxStore: csize_t = FZ_STORE_DEFAULT): ptr FzContext =
  fz_new_context_imp(nil, nil, maxStore, nimupdf_fz_version())

# ---------------------------------------------------------------------------
# Safe C wrappers (translate fz_try/fz_catch to return codes)
# ---------------------------------------------------------------------------

proc nimupdf_open_document*(ctx: ptr FzContext; filename: cstring;
    outDoc: ptr ptr FzDocument; errbuf: cstring; errlen: cint): cint
    {.importc, cdecl, header: "fitz_wrap.h".}

proc nimupdf_count_pages*(ctx: ptr FzContext; doc: ptr FzDocument;
    outCount: ptr cint; errbuf: cstring; errlen: cint): cint
    {.importc, cdecl, header: "fitz_wrap.h".}

proc nimupdf_load_page*(ctx: ptr FzContext; doc: ptr FzDocument;
    number: cint; outPage: ptr ptr FzPage; errbuf: cstring; errlen: cint): cint
    {.importc, cdecl, header: "fitz_wrap.h".}

proc nimupdf_bound_page*(ctx: ptr FzContext; page: ptr FzPage;
    outRect: ptr FzRect; errbuf: cstring; errlen: cint): cint
    {.importc, cdecl, header: "fitz_wrap.h".}

proc nimupdf_run_page*(ctx: ptr FzContext; page: ptr FzPage;
    dev: ptr FzDevice; transform: FzMatrix; errbuf: cstring; errlen: cint): cint
    {.importc, cdecl, header: "fitz_wrap.h".}

proc nimupdf_extract_page_text*(ctx: ptr FzContext; page: ptr FzPage;
    stextFlags: cint; outText: ptr cstring; errbuf: cstring; errlen: cint): cint
    {.importc, cdecl, header: "fitz_wrap.h".}

proc nimupdf_lookup_metadata*(ctx: ptr FzContext; doc: ptr FzDocument;
    key: cstring; buf: cstring; size: cint; errbuf: cstring; errlen: cint): cint
    {.importc, cdecl, header: "fitz_wrap.h".}
