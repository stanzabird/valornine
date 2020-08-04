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

%x comment lang
%%



{open}{ws}*"comment"{ws}*{close}              { BEGIN(comment); }
<comment>{open}{ws}*"endcomment"{ws}*{close}  { BEGIN(INITIAL); }
<comment>"\n"                                 { ++yylineno; }
<comment>.                                    { }





{open}                 { BEGIN(lang);     return TOK_OPEN;  }
<lang>{close}          { BEGIN(INITIAL);  return TOK_CLOSE; }

<lang>"file"           { return TOK_FILE; }
<lang>"fetch"          { return TOK_FETCH; }
<lang>"snippet"        { return TOK_SNIPPET; }
<lang>"binary"         { return TOK_BINARY; }
<lang>"string"         { return TOK_STRING; }
<lang>"guid"           { return TOK_GUID; }
<lang>"endfile"        { return TOK_ENDFILE; }
<lang>"project"        { return TOK_PROJECT; }
<lang>"endproject"     { return TOK_ENDPROJECT; }
<lang>"template"       { return TOK_TEMPLATE; }
<lang>"endtemplate"    { return TOK_ENDTEMPLATE; }
<lang>"extends"        { return TOK_EXTENDS; }
<lang>"exec"           { return TOK_EXEC; }
<lang>"endexec"        { return TOK_ENDEXEC; }
<lang>"multiline"      { return TOK_MULTILINE; }
<lang>"endmultiline"   { return TOK_ENDMULTILINE; }
<lang>"endsnippet"     { return TOK_ENDSNIPPET; }
<lang>"endbinary"      { return TOK_ENDBINARY; }
<lang>"module"         { return TOK_MODULE; }
<lang>"endmodule"      { return TOK_ENDMODULE; }
<lang>"var"            { return TOK_VAR; }
<lang>"endvar"         { return TOK_ENDVAR; }
<lang>{IDENT}          { return IDENTIFIER; }
<lang>{str}            { return STRING; }
<lang>{ws}             { }


"\n" { ++yylineno; }
.                { /*return CHAR_LITERAL; */}




%%
int yywrap() { return 1; }

