%{
#include "parser.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int flag_chars = 0;
int flag_in_text_contents = 0;
%}

/* an identifier */
DIGIT        [0-9]
LETTER       [a-zA-Z]
IDENTLETTER  ({LETTER}|_)
IDENT        {IDENTLETTER}({IDENTLETTER}|{DIGIT})*

digit		[0-9]
alpha		[a-fA-F]
hextail		({digit}|{alpha}){1,2}
hex_char	0[xX]{hextail}

ws     [ \t]+
str    \"([^\\\"]|\\.)*\"
/* this is c-like strings, idents and whitespace. */
open   "{%"
close  "%}"

%x comment lang chars

%%

<INITIAL,chars>{open}{ws}*"comment"{ws}*{close}              { BEGIN(comment); }
<comment>{open}{ws}*"endcomment"{ws}*{close}  { if (flag_chars) BEGIN(chars); else BEGIN(INITIAL); }
<comment>"\n"                                 { ++yylineno; }
<comment>.                                    { }

{open}                 { flag_chars = 0; BEGIN(lang); return TOK_OPEN; }
<lang>{close}          { if (flag_chars) BEGIN(chars); else BEGIN(INITIAL); return TOK_CLOSE; }

<lang>"file"           { flag_in_text_contents = 1; flag_chars = 1; return TOK_FILE; }
<lang>"fetch"          { flag_in_text_contents = 0; flag_chars = 0; return TOK_FETCH; }
<lang>"snippet"        { if (flag_chars == 1) { flag_chars = 0; flag_in_text_contents = 0; } else flag_chars = 1; return TOK_SNIPPET; }
<lang>"binary"         { flag_chars = 0; /*flag_hexcodes=1*/ return TOK_BINARY; }

<lang>"string"         { flag_chars = 0; return TOK_STRING; }
<lang>"guid"           { flag_chars = 0; return TOK_GUID; }
<lang>"endfile"        { flag_in_text_contents = 0; flag_chars = 0; return TOK_ENDFILE; }
<lang>"project"        { flag_chars = 0; return TOK_PROJECT; }
<lang>"endproject"     { flag_chars = 0; return TOK_ENDPROJECT; }
<lang>"template"       { flag_chars = 0; return TOK_TEMPLATE; }
<lang>"endtemplate"    { flag_chars = 0; return TOK_ENDTEMPLATE; }
<lang>"extends"        { flag_chars = 0; return TOK_EXTENDS; }
<lang>"exec"           { flag_chars = 1; return TOK_EXEC; }
<lang>"endexec"        { flag_chars = 0; if (flag_in_text_contents == 1) flag_chars = 1; return TOK_ENDEXEC; }
<lang>"multiline"      { flag_chars = 1; return TOK_MULTILINE; }
<lang>"endmultiline"   { flag_chars = 0; return TOK_ENDMULTILINE; }
<lang>"endsnippet"     { flag_chars = 0; return TOK_ENDSNIPPET; }
<lang>"endbinary"      { flag_chars = 0; return TOK_ENDBINARY; }
<lang>"module"         { flag_chars = 0; if (flag_in_text_contents == 1) flag_chars = 1; return TOK_MODULE; }
<lang>"endmodule"      { flag_chars = 0; if (flag_in_text_contents == 1) flag_chars = 1; return TOK_ENDMODULE; }
<lang>"var"            { flag_chars = 0; return TOK_VAR; }
<lang>"endvar"         { flag_chars = 0; return TOK_ENDVAR; }

<lang>{IDENT}          { return IDENTIFIER; }
<lang>{str}            { return STRING; }
<lang>{ws}             { }



<chars>{open} { BEGIN(lang); return TOK_OPEN; }
<chars>"\n"   { ++yylineno; return CHAR_LITERAL; }
<chars>.      { return CHAR_LITERAL; }





{ws}    { }
"\n"    { ++yylineno; }
.       {
          printf("Error: Line %d: Unexpected character `%c'\nExiting...\n", yylineno, *yytext);
          exit(1);
        }
%%

int yywrap() { return 1; }
