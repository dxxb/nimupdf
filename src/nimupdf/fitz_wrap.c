/*
 * Thin C wrappers around MuPDF functions to translate fz_try/fz_catch
 * error handling into return codes usable from Nim FFI.
 */

#include "fitz_wrap.h"
#include <stdio.h>
#include <string.h>

static void set_err(char *errbuf, int errlen, const char *msg)
{
    if (errbuf && errlen > 0) {
        strncpy(errbuf, msg, errlen - 1);
        errbuf[errlen - 1] = '\0';
    }
}

int nimupdf_open_document(fz_context *ctx, const char *filename,
    fz_document **out_doc, char *errbuf, int errlen)
{
    fz_try(ctx) {
        *out_doc = fz_open_document(ctx, filename);
    }
    fz_catch(ctx) {
        set_err(errbuf, errlen, fz_caught_message(ctx));
        return -1;
    }
    return 0;
}

int nimupdf_count_pages(fz_context *ctx, fz_document *doc,
    int *out_count, char *errbuf, int errlen)
{
    fz_try(ctx) {
        *out_count = fz_count_pages(ctx, doc);
    }
    fz_catch(ctx) {
        set_err(errbuf, errlen, fz_caught_message(ctx));
        return -1;
    }
    return 0;
}

int nimupdf_load_page(fz_context *ctx, fz_document *doc, int number,
    fz_page **out_page, char *errbuf, int errlen)
{
    fz_try(ctx) {
        *out_page = fz_load_page(ctx, doc, number);
    }
    fz_catch(ctx) {
        set_err(errbuf, errlen, fz_caught_message(ctx));
        return -1;
    }
    return 0;
}

int nimupdf_bound_page(fz_context *ctx, fz_page *page,
    fz_rect *out_rect, char *errbuf, int errlen)
{
    fz_try(ctx) {
        *out_rect = fz_bound_page(ctx, page);
    }
    fz_catch(ctx) {
        set_err(errbuf, errlen, fz_caught_message(ctx));
        return -1;
    }
    return 0;
}

int nimupdf_run_page(fz_context *ctx, fz_page *page, fz_device *dev,
    fz_matrix transform, char *errbuf, int errlen)
{
    fz_try(ctx) {
        fz_run_page(ctx, page, dev, transform, NULL);
    }
    fz_catch(ctx) {
        set_err(errbuf, errlen, fz_caught_message(ctx));
        return -1;
    }
    return 0;
}

int nimupdf_extract_page_text(fz_context *ctx, fz_page *page,
    int stext_flags, char **out_text, char *errbuf, int errlen)
{
    fz_stext_page *stext = NULL;
    fz_device *dev = NULL;
    fz_buffer *buf = NULL;
    fz_output *output = NULL;

    fz_var(stext);
    fz_var(dev);
    fz_var(buf);
    fz_var(output);

    fz_try(ctx) {
        fz_rect mediabox = fz_bound_page(ctx, page);

        fz_stext_options opts;
        memset(&opts, 0, sizeof(opts));
        opts.flags = stext_flags;

        stext = fz_new_stext_page(ctx, mediabox);
        dev = fz_new_stext_device(ctx, stext, &opts);
        fz_run_page(ctx, page, dev, fz_identity, NULL);
        fz_close_device(ctx, dev);
        fz_drop_device(ctx, dev);
        dev = NULL;

        buf = fz_new_buffer(ctx, 1024);
        output = fz_new_output_with_buffer(ctx, buf);
        fz_print_stext_page_as_text(ctx, output, stext);
        fz_close_output(ctx, output);

        fz_terminate_buffer(ctx, buf);
        const char *text = fz_string_from_buffer(ctx, buf);
        size_t len = strlen(text);
        *out_text = (char *)fz_malloc(ctx, len + 1);
        memcpy(*out_text, text, len + 1);
    }
    fz_always(ctx) {
        fz_drop_output(ctx, output);
        fz_drop_buffer(ctx, buf);
        fz_drop_device(ctx, dev);
        fz_drop_stext_page(ctx, stext);
    }
    fz_catch(ctx) {
        set_err(errbuf, errlen, fz_caught_message(ctx));
        return -1;
    }
    return 0;
}

int nimupdf_lookup_metadata(fz_context *ctx, fz_document *doc,
    const char *key, char *buf, int size, char *errbuf, int errlen)
{
    int n = -1;
    fz_try(ctx) {
        n = fz_lookup_metadata(ctx, doc, key, buf, size);
    }
    fz_catch(ctx) {
        set_err(errbuf, errlen, fz_caught_message(ctx));
        return -1;
    }
    return n;
}
