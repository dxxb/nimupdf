/*
 * Thin C wrappers around MuPDF functions to translate fz_try/fz_catch
 * error handling into return codes usable from Nim FFI.
 *
 * Every wrapper returns 0 on success or -1 on error.  When an error
 * occurs the message is copied into `errbuf`.
 */

#ifndef NIMUPDF_FITZ_WRAP_H
#define NIMUPDF_FITZ_WRAP_H

#include <mupdf/fitz.h>

int nimupdf_open_document(fz_context *ctx, const char *filename,
    fz_document **out_doc, char *errbuf, int errlen);

int nimupdf_count_pages(fz_context *ctx, fz_document *doc,
    int *out_count, char *errbuf, int errlen);

int nimupdf_load_page(fz_context *ctx, fz_document *doc, int number,
    fz_page **out_page, char *errbuf, int errlen);

int nimupdf_bound_page(fz_context *ctx, fz_page *page,
    fz_rect *out_rect, char *errbuf, int errlen);

int nimupdf_run_page(fz_context *ctx, fz_page *page, fz_device *dev,
    fz_matrix transform, char *errbuf, int errlen);

int nimupdf_extract_page_text(fz_context *ctx, fz_page *page,
    int stext_flags, char **out_text, char *errbuf, int errlen);

int nimupdf_lookup_metadata(fz_context *ctx, fz_document *doc,
    const char *key, char *buf, int size, char *errbuf, int errlen);

#endif
