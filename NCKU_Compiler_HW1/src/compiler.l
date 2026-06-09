/* Definition section */
%option yymore
%{
    #include <utf8.c/utf8.h>
    #include "chinese_number.h"
    #include "compiler_util.h"

    #define YY_NO_UNPUT
    #define YY_NO_INPUT

    int yycolumnUtf8=0, yylengUtf8=0, yytokenLine = 1;
    int tokenStartLine = 1, tokenStartColumn = 1;
    int tokenStartSaved = 0;
    utf8_string yytextUtf8;

    static inline void updateNewline() {
        yytokenLine++;
        yycolumnUtf8 = 0;
        yylengUtf8 = 0;
    }
    static inline int countUtf8Chars(const char *s){
        int count = 0;
        while(*s){
            unsigned char c = (unsigned char)*s;
            if((c & 0xC0) != 0x80){
                count++;
            }
            s++;
        }
        return count;
    }
    static inline void processUtf8Char() {
        yytextUtf8 = make_utf8_string(yytext);
        if (yytextUtf8.str) {
            yylengUtf8 = countUtf8Chars(yytext);
            yycolumnUtf8 += yylengUtf8;
        }
    }

    static inline void yymore_utf8() {
        yymore();
        if (yytextUtf8.str) {
            yycolumnUtf8 -= yylengUtf8;
        }
    }

    #define YY_USER_ACTION \
        if (!tokenStartSaved) { \
            tokenStartLine = yytokenLine; \
            tokenStartColumn = yycolumnUtf8 + 1; \
            tokenStartSaved = 1; \
        } \
        processUtf8Char();

    #define PRINT_TOKEN(format, ...) do { \
        printf("%d:%d: " format "\n", tokenStartLine, tokenStartColumn, ##__VA_ARGS__); \
        tokenStartSaved = 0; \
    } while (0)

    char* trimStringToken(int paddLen) {
        static char cache[4096];
        int len = yyleng - 2 * paddLen;
        if (len < 0) len = 0;
        if (len >= (int)sizeof(cache)) len = sizeof(cache) - 1;
        strncpy(cache, yytext + paddLen, len);
        cache[len] = '\0';
        return cache;
    }
%}

/* Define regular expression label */
/* Chinese digits used in number literals */
digit ("零"|"一"|"二"|"兩"|"三"|"四"|"五"|"六"|"七"|"八"|"九"|"十"|"百"|"千"|"萬"|"億")

UTF8_BOM "\357\273\277"

ASCII   [\x00-\x7f]
U       [\x80-\xbf]

B2      [\xC2-\xDF]{U}
B3_1    \xE0[\xA0-\xBF]{U}
B3_2    [\xE1-\xEC]{U}{U}
B3_3    \xED[\x80-\x9F]{U}
B3_4    [\xEE-\xEF]{U}{U}
B4_1    \xF0[\x90-\xBF]{U}{U}
B4_2    [\xF1-\xF3]{U}{U}{U}
B4_3    \xF4[\x80-\x8F]{U}{U}

/* ALL UTF-8 https://www.w3.org/2005/03/23-lex-U#charRange
  {ASCII}
| ([\xC2-\xDF] {U})
| ( \xE0       [\xA0-\xBF]{U})
| ([\xE1-\xEC] {U}{U})
| ( \xED       [\x80-\x9F]{U})
| ([\xEE-\xEF] {U}{U})
| ( \xF0       [\x90-\xBF]{U}{U})
| ([\xF1-\xF3] {U}{U}{U})
| ( \xF4       [\x80-\x8F]{U}{U})
*/

ALL_UTF8 {ASCII}|{B2}|{B3_1}|{B3_2}|{B3_3}|{B3_4}|{B4_1}|{B4_2}|{B4_3}

/* B3_2 excluding 」 (U+300D = \xE3\x80\x8D) */
B3_2_EXCLUDE_QUO ([\xE1-\xE2]{U}{U})|(\xE3\x80[\x80-\x8C\x8E-\xBF])|(\xE3[\x81-\xBF]{U})|([\xE4-\xEC]{U}{U})

/* All UTF-8 chars excluding 」 and control chars (no \x00-\x1F, no \x7F) */
EXCLUDE_QUO [\x20-\x7E]|{B2}|{B3_1}|{B3_2_EXCLUDE_QUO}|{B3_3}|{B3_4}|{B4_1}|{B4_2}|{B4_3}

%option yylineno
%x IDENT_CON
%x STR_CON

%%

"「「" {
    tokenStartLine = yytokenLine;
    tokenStartColumn = yycolumnUtf8 - yylengUtf8 + 1;
    BEGIN(STR_CON);
    yymore_utf8();
}

<STR_CON>"」」" {
    BEGIN(INITIAL);
    /* 「「 is 6 bytes (3 bytes each), 」」 is also 6 bytes */
    printf("%d:%d: STR_LIT \"%s\"\n",
           tokenStartLine,
           tokenStartColumn,
           trimStringToken(6));
    tokenStartSaved = 0;
}

<STR_CON>\r?\n {
    updateNewline();
    yymore();
}

<STR_CON>{EXCLUDE_QUO}+ {
    yymore_utf8();
}

<STR_CON>"」" {
    yymore_utf8();
}

"「" {
    tokenStartLine = yytokenLine;
    tokenStartColumn = yycolumnUtf8 - yylengUtf8 + 1;
    BEGIN(IDENT_CON);
    yymore_utf8();
}

<IDENT_CON>"」" {
    BEGIN(INITIAL);
    /* 「 is 3 bytes, 」 is 3 bytes */
    printf("%d:%d: IDENT '%s'\n",
           tokenStartLine,
           tokenStartColumn,
           trimStringToken(3));
    tokenStartSaved = 0;
}

<IDENT_CON>\r?\n {
    updateNewline();
    yymore();
}

<IDENT_CON>{EXCLUDE_QUO}+ {
    yymore_utf8();
}


"注曰"|"疏曰"|"批曰" {
    PRINT_TOKEN("COMMENT %s", yytext);
}


"今有"|"吾有" {
    PRINT_TOKEN("HERE_ARE %s", yytext);
}

"有" {
    PRINT_TOKEN("HERE_IS_A %s", yytext);
}

"名之曰" {
    PRINT_TOKEN("NAME_IT %s", yytext);
}

"曰" {
    PRINT_TOKEN("SAID %s", yytext);
}

"昔之" {
    PRINT_TOKEN("PAST %s", yytext);
}

"者" {
    PRINT_TOKEN("TOPIC %s", yytext);
}

"今" {
    PRINT_TOKEN("SET %s", yytext);
}

"其" {
    PRINT_TOKEN("ITS %s", yytext);
}

"是矣" {
    PRINT_TOKEN("IS_THUS %s", yytext);
}


"術" {
    PRINT_TOKEN("VAR_TYPE_FUNC %s", yytext);
}

"爻"|"數"|"言"|"長"|"元"|"列" {
    PRINT_TOKEN("VAR_TYPE %s", yytext);
}


"陰" {
    PRINT_TOKEN("BOOL_LIT false");
}

"陽" {
    PRINT_TOKEN("BOOL_LIT true");
}


"加" {
    PRINT_TOKEN("EXP_MATH +");
}

"減" {
    PRINT_TOKEN("EXP_MATH -");
}

"乘" {
    PRINT_TOKEN("EXP_MATH *");
}

"除" {
    PRINT_TOKEN("EXP_MATH /");
}

"所餘幾何" {
    PRINT_TOKEN("EXP_MATH_OP %%");
}

"於" {
    PRINT_TOKEN("<-");
}

"以" {
    PRINT_TOKEN("->");
}

"中有陽乎" {
    PRINT_TOKEN("EXP_LOGIC ||");
}

"中無陰乎" {
    PRINT_TOKEN("EXP_LOGIC &&");
}

"不大於" {
    PRINT_TOKEN("EXP_LOGIC <=");
}

"不小於" {
    PRINT_TOKEN("EXP_LOGIC >=");
}

"大於" {
    PRINT_TOKEN("EXP_LOGIC >");
}

"小於" {
    PRINT_TOKEN("EXP_LOGIC <");
}

"不等於" {
    PRINT_TOKEN("EXP_LOGIC !=");
}

"等於" {
    PRINT_TOKEN("EXP_LOGIC ==");
}


"若非" {
    PRINT_TOKEN("ELSE %s", yytext);
}

"或若" {
    PRINT_TOKEN("ELSE_IF %s", yytext);
}

"若" {
    PRINT_TOKEN("IF %s", yytext);
}

"恆為是" {
    PRINT_TOKEN("WHILE_TRUE %s", yytext);
}

"為是" {
    PRINT_TOKEN("FOR %s", yytext);
}

"遍" {
    PRINT_TOKEN("TIMES %s", yytext);
}

"乃止" {
    PRINT_TOKEN("BREAK %s", yytext);
}

"乃得" {
    PRINT_TOKEN("RETURN %s", yytext);
}

"云云"|"也"|"矣" {
    PRINT_TOKEN("END %s", yytext);
}

"欲行是術" {
    PRINT_TOKEN("TO_PERFORM_FUNC %s", yytext);
}

"必先得" {
    PRINT_TOKEN("REQUIRE_ARGS %s", yytext);
}

"乃行是術曰"|"乃是術曰" {
    PRINT_TOKEN("FUNC_BEGIN %s", yytext);
}

"是謂" {
    PRINT_TOKEN("FUNC_END_FOR %s", yytext);
}

"之術也" {
    PRINT_TOKEN("FUNC_END %s", yytext);
}

"施" {
    PRINT_TOKEN("CALL %s", yytext);
}

"之長" {
    PRINT_TOKEN("LENGTH %s", yytext);
}

"之" {
    PRINT_TOKEN("INDEX %s", yytext);
}

"充" {
    PRINT_TOKEN("PUSH %s", yytext);
}

"書之" {
    PRINT_TOKEN("PRINT %s", yytext);
}

"夫" {
    PRINT_TOKEN("THOSE %s", yytext);
}

"取" {
    PRINT_TOKEN("TAKE %s", yytext);
}


{digit}+"\xC2\xB7"{digit}+ {
    ScientificNotation sci;
    chineseToArabic(yytext, &sci);
    PRINT_TOKEN("NUMBER_LIT %g", sciToDouble(&sci));
}

{digit}+ {
    ScientificNotation sci;
    chineseToArabic(yytext, &sci);
    PRINT_TOKEN("NUMBER_LIT %lld", (long long)sciToInt32(&sci));
}



"。"|"，"|"、" {
    tokenStartSaved = 0;
    /* ignore decoration */
}



[ \t]+      { tokenStartSaved = 0; /* ignore whitespace */ }
\r?\n       { updateNewline(); tokenStartSaved = 0; }
{UTF8_BOM}  { tokenStartSaved = 0; yycolumnUtf8 = 0; yylengUtf8 = 0; /* Skip UTF-8 BOM */ }


<<EOF>>     { yyterminate(); }


{ALL_UTF8}  { PRINT_TOKEN("UNKNOWN CHAR %s", yytext); }
.           { PRINT_TOKEN("UNKNOWN CHAR %s", yytext); }

%%
/*  C Code section */
int yywrap(void) {
    return 1;
}
