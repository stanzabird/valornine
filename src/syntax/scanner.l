%{
#include "parser.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
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
ws              [ \t]+
str             \"([^\\\"]|\\.)*\"
/* this is c-like strings, idents and whitespace. */
open "{%"
close "%}"

%x comment
%%



{open}{ws}*"comment"{ws}*{close}              { BEGIN(comment); }
<comment>{open}{ws}*"endcomment"{ws}*{close}  { BEGIN(INITIAL); }
<comment>"\n"                                 { ++yylineno; }
<comment>.                                    { }





{open}           { return TOK_OPEN; }
{close}          { return TOK_CLOSE; }

"file"           { return TOK_FILE; }
"fetch"          { return TOK_FETCH; }
"snippet"        { return TOK_SNIPPET; }
"binary"         { return TOK_BINARY; }
"string"         { return TOK_STRING; }
"guid"           { return TOK_GUID; }
"endfile"        { return TOK_ENDFILE; }
"project"        { return TOK_PROJECT; }
"endproject"     { return TOK_ENDPROJECT; }
"template"       { return TOK_TEMPLATE; }
"endtemplate"    { return TOK_ENDTEMPLATE; }
"extends"        { return TOK_EXTENDS; }
"exec"           { return TOK_EXEC; }
"endexec"        { return TOK_ENDEXEC; }
"multiline"      { return TOK_MULTILINE; }
"endmultiline"   { return TOK_ENDMULTILINE; }
"endsnippet"     { return TOK_ENDSNIPPET; }
"endbinary"      { return TOK_ENDBINARY; }
"module"         { return TOK_MODULE; }
"endmodule"      { return TOK_ENDMODULE; }
"var"            { return TOK_VAR; }
"endvar"         { return TOK_ENDVAR; }

{IDENT}          { return IDENTIFIER; }
{str}            { return STRING; }
"\n"             { ++yylineno; }
{ws}             { }
.                { return CHAR_LITERAL; }



%%
int yywrap() { return 1; }

