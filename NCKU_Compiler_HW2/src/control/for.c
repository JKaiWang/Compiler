//
// Created by WavJaby on 2026/03/26.
//

#include "for.h"

#include <stdarg.h>
#include <WJCL/string/wjcl_string.h>

#include "lib/code_gen.h"
#include "compiler_util.h"
#include "scope.h"

bool code_forLoop(Object* src) {
    if (src->type == OBJECT_TYPE_UNDEFINED)
        goto FAILED;

    compilerLog("> (for loop, count: %s)\n", object_print(src));

    ScopeData* scope = scope_pushType(SCOPE_FOR_LOOP);
    scope->u.forLoop.symbol = (SymbolData){
        .type = OBJECT_TYPE_I32,
        .elementType = OBJECT_TYPE_UNDEFINED,
        .name = strdup("i"),
        .index = -1,
        .funcInfo = NULL,
        .funcArg = false,
    };

    char countName[MAX_NAME_LENGTH];
    Object regSrc = object_loadRegAndPromote(src, OBJECT_TYPE_I32, countName, MAX_NAME_LENGTH);
    if (regSrc.type == OBJECT_TYPE_UNDEFINED)
        goto FAILED;

    const int id = scope->id;
    buffPrintln(&ctx->code, "");
    buffPrintln(&ctx->code, "br label %%loop%d.entry", id);
    buffPrintlnS(&ctx->code, "loop%d.entry:", id);
    buffPrintln(&ctx->code, "br label %%loop%d.header", id);
    buffPrintlnS(&ctx->code, "loop%d.header:", id);
    buffPrintln(&ctx->code, "%%loop%d.i = phi i32 [ 0, %%loop%d.entry ], [ %%loop%d.i.next, %%loop%d.update ]",
                id, id, id, id);
    buffPrintln(&ctx->code, "%%loop%d.cond = icmp slt i32 %%loop%d.i, %s", id, id, countName);
    buffPrintln(&ctx->code, "br i1 %%loop%d.cond, label %%loop%d.body, label %%loop%d.exit", id, id, id);
    buffPrintlnS(&ctx->code, "loop%d.body:", id);

    if (src->type == OBJECT_TYPE_SYMBOL || (regSrc.type == OBJECT_TYPE_REGISTER && src->type != OBJECT_TYPE_REGISTER))
        object_free(&regSrc);
    object_free(src);
    return false;

FAILED:
    object_free(src);
    return true;
}

bool code_forLoopEnd(Object* obj) {
    const ScopeData* scope = scope_peek();
    const int id = scope->id;
    const char* typeName = objectType2llvmType[scope->u.forLoop.symbol.type];
    buffPrintln(&ctx->code, "br label %%loop%d.update", id);
    buffPrintlnS(&ctx->code, "loop%d.update:", id);
    buffPrintln(&ctx->code, "%%loop%d.i.next = add nsw %s %%loop%d.i, 1", id, typeName, id);
    buffPrintln(&ctx->code, "br label %%loop%d.header", id);
    buffPrintlnS(&ctx->code, "loop%d.exit:", id);
    buffPrintln(&ctx->code, "");

    scope_dump();
    compilerLog("< (for loop end)\n");
    return false;
}
