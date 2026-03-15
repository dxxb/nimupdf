# nimupdf

Nim bindings for [MuPDF](https://mupdf.com/) — a lightweight PDF, XPS, and EPUB rendering library.

Provides both low-level C FFI bindings and a high-level idiomatic Nim API for document operations, with a focus on text extraction.

## Prerequisites

MuPDF must be installed on your system:

```sh
# macOS
brew install mupdf

# Debian/Ubuntu
sudo apt install libmupdf-dev

# Arch
sudo pacman -S mupdf
```

## Installation

```sh
nimble install nimupdf
```

Or add to your `.nimble` file:

```nim
requires "nimupdf >= 0.1.0"
```

## Quick Start

```nim
import nimupdf

# One-liner: extract all text from a PDF
echo extractText("document.pdf")
```

## Usage

### Opening a document

```nim
import nimupdf

let ctx = newMuPdfContext()
let doc = ctx.open("document.pdf")

echo "Pages: ", doc.pageCount
echo "Format: ", doc.metadata("format")
echo "Title: ", doc.metadata("info:Title")
```

### Extracting text

```nim
# From a single page (zero-indexed)
let page = doc.loadPage(0)
echo page.extractText()

# From all pages
echo doc.extractText()

# With options
echo doc.extractText({sfPreserveLigatures, sfDehyphenate})
```

### Iterating pages

```nim
for page in doc.pages:
  let r = page.bounds
  echo "Page ", page.number, ": ", r.x1 - r.x0, " x ", r.y1 - r.y0
  echo page.extractText()
```

### Deterministic cleanup

Resources are released when objects are garbage-collected, but you can
release them explicitly with `close`:

```nim
page.close()
doc.close()
ctx.close()
```

### Document metadata

Available metadata keys:

| Key | Description |
|-----|-------------|
| `"format"` | Document format (e.g. "PDF 1.4") |
| `"encryption"` | Encryption method |
| `"info:Title"` | Document title |
| `"info:Author"` | Author |
| `"info:Subject"` | Subject |
| `"info:Keywords"` | Keywords |
| `"info:Creator"` | Creator application |
| `"info:Producer"` | PDF producer |

### Text extraction flags

| Flag | Effect |
|------|--------|
| `sfPreserveLigatures` | Keep ligature characters as-is |
| `sfPreserveWhitespace` | Preserve whitespace exactly |
| `sfPreserveImages` | Include image placeholders |
| `sfInhibitSpaces` | Don't insert synthetic spaces |
| `sfDehyphenate` | Remove end-of-line hyphens |
| `sfPreserveSpans` | Keep text span boundaries |

## Architecture

```
src/
  nimupdf.nim           High-level idiomatic Nim API
  nimupdf/
    fitz.nim            Low-level C FFI bindings (types + procs)
    fitz_wrap.c/.h      C wrappers for MuPDF's setjmp error handling
```

The low-level layer (`nimupdf/fitz`) maps directly to the MuPDF C API. A thin
C wrapper (`fitz_wrap.c`) translates MuPDF's `fz_try`/`fz_catch` exception
mechanism into return codes that Nim can check and convert to native exceptions.

The high-level layer (`nimupdf`) provides ref-counted wrapper types
(`MuPdfContext`, `MuPdfDocument`, `MuPdfPage`) with automatic resource cleanup
and Nim-native error handling via `MuPdfError` exceptions.

## Building from source

```sh
git clone <repo-url>
cd nimupdf
nim c --path:src -d:release examples/extract_text.nim
nim c --path:src -d:release -r tests/test_basic.nim
```

## License

AGPL-3.0-or-later (matching the MuPDF license).
