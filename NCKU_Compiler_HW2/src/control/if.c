//
// Created by Wavjaby on 2026/3/26.
//

#include "if.h"

#include <stdarg.h>
#include <WJCL/string/wjcl_string.h>

#include "lib/code_gen.h"
#include "compiler_util.h"
#include "scope.h"

inline bool code_if(Object* src) {
    compilerLog("> (if)\n");
    char condName[MAX_NAME_LENGTH];
    Object cond = object_loadRegAndPromote(src, OBJECT_TYPE_BOOL, condName, MAX_NAME_LENGTH);
    if (cond.type == OBJECT_TYPE_UNDEFINED) {
        object_free(src);
        return true;
    }

    ScopeData* scope = scope_pushType(SCOPE_IF_STMT);
    scope->u.ifInfo = (IfInfo){.elseifCount = 0, .containsElse = false};
    buffPrintln(&ctx->code, "br i1 %s, label %%if%d.true, label %%if%d.false",
                condName, scope->id, scope->id);
    buffPrintlnS(&ctx->code, "if%d.true:", scope->id);

    if (src->type == OBJECT_TYPE_SYMBOL || (cond.type == OBJECT_TYPE_REGISTER && src->type != OBJECT_TYPE_REGISTER))
        object_free(&cond);
    object_free(src);
    return false;
}

inline bool code_elseIfLabel() {
    ScopeData* scope = scope_peek();
    const int id = scope->id;
    const int count = scope->u.ifInfo.elseifCount;
    buffPrintln(&ctx->code, "br label %%if%d.endif", id);
    if (count == 0)
        buffPrintlnS(&ctx->code, "if%d.false:", id);
    else
        buffPrintlnS(&ctx->code, "if%d.elseif%d.false:", id, count - 1);
    return false;
}

inline bool code_elseIf(Object* src) {
    ScopeData* oldScope = scope_peek();
    const int id = oldScope->id;
    const int count = oldScope->u.ifInfo.elseifCount;
    const bool containsElse = oldScope->u.ifInfo.containsElse;
    scope_dump();

    char condName[MAX_NAME_LENGTH];
    Object cond = object_loadRegAndPromote(src, OBJECT_TYPE_BOOL, condName, MAX_NAME_LENGTH);
    if (cond.type == OBJECT_TYPE_UNDEFINED) {
        object_free(src);
        return true;
    }

    compilerLog("> (else if)\n");
    ScopeData* scope = scope_pushId(SCOPE_IF_STMT, id);
    scope->u.ifInfo = (IfInfo){.elseifCount = count + 1, .containsElse = containsElse};
    buffPrintln(&ctx->code, "br i1 %s, label %%if%d.elseif%d.true, label %%if%d.elseif%d.false",
                condName, id, count, id, count);
    buffPrintlnS(&ctx->code, "if%d.elseif%d.true:", id, count);

    if (src->type == OBJECT_TYPE_SYMBOL || (cond.type == OBJECT_TYPE_REGISTER && src->type != OBJECT_TYPE_REGISTER))
        object_free(&cond);
    object_free(src);
    return false;
}

inline bool code_else() {
    ScopeData* oldScope = scope_peek();
    const int id = oldScope->id;
    const int count = oldScope->u.ifInfo.elseifCount;
    scope_dump();
    compilerLog("> (else)\n");

    buffPrintln(&ctx->code, "br label %%if%d.endif", id);
    if (count == 0)
        buffPrintlnS(&ctx->code, "if%d.false:", id);
    else
        buffPrintlnS(&ctx->code, "if%d.elseif%d.false:", id, count - 1);

    ScopeData* scope = scope_pushId(SCOPE_IF_STMT, id);
    scope->u.ifInfo = (IfInfo){.elseifCount = count, .containsElse = true};
    return false;
}

inline bool code_ifEnd() {
    ScopeData* scope = scope_peek();
    const int id = scope->id;
    const int count = scope->u.ifInfo.elseifCount;
    const bool hasElse = scope->u.ifInfo.containsElse;

    if (hasElse) {
        buffPrintln(&ctx->code, "br label %%if%d.endif", id);
        buffPrintlnS(&ctx->code, "if%d.endif:", id);
    } else if (count == 0) {
        buffPrintln(&ctx->code, "br label %%if%d.false", id);
        buffPrintlnS(&ctx->code, "if%d.false:", id);
    } else {
        buffPrintln(&ctx->code, "br label %%if%d.endif", id);
        buffPrintlnS(&ctx->code, "if%d.elseif%d.false:", id, count - 1);
        buffPrintln(&ctx->code, "br label %%if%d.endif", id);
        buffPrintlnS(&ctx->code, "if%d.endif:", id);
    }
    scope_dump();
    compilerLog("< (if end)\n");
    return false;
}
