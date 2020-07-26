%x comment lang vars varvalue body binary raw


%{
#include "parser.types.h"
#include "parser.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int last_was_begin_tag; /* needed to implement 'binary' */
static unsigned char make_byte(const char* str);
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


%%

"---"                                           { BEGIN(vars); last_was_begin_tag = 0; return HVAL_DELIM; }
<vars>"\n"                                      { ++yylineno; /* whitespace */ }
<vars>[ \t]+                                    { /* whitespace */}
<vars>{IDENT}                                   { yylval.pIdentifier = strdup(yytext); return IDENTIFIER; }
<vars>":"                                       { BEGIN(varvalue); return ':'; }
<vars>"---"                                     { BEGIN(body); return HVAL_DELIM; }

<varvalue>"\n"                                  { BEGIN(vars); ++yylineno; return '\n'; }
<varvalue>.                                     { yylval.pChar = yytext[0]; return CHAR_LITERAL; }


<body>"{{"                                      { BEGIN(lang); last_was_begin_tag = 0; return BEGIN_OUTPUT; }
<body>"{%"                                      { BEGIN(lang); last_was_begin_tag = 1; return BEGIN_TAG; }
<body>"\n"                                      { ++yylineno; yylval.pChar = yytext[0]; last_was_begin_tag = 0; return CHAR_LITERAL; }
<body>.                                         {             yylval.pChar = yytext[0]; last_was_begin_tag = 0; return CHAR_LITERAL; }



 /* INITIAL state - notice <body> rules above */
"{{"                                      { BEGIN(lang); last_was_begin_tag = 0; return BEGIN_OUTPUT; }
"{%"                                      { BEGIN(lang); last_was_begin_tag = 1; return BEGIN_TAG; }
                                          /* these two rules below MUST match the 
                                           * corresponding lines in the <body> state */
"\n"                                      { BEGIN(body); ++yylineno; yylval.pChar = yytext[0]; last_was_begin_tag = 0; return CHAR_LITERAL; }
.                                         { BEGIN(body);             yylval.pChar = yytext[0]; last_was_begin_tag = 0; return CHAR_LITERAL; }




<INITIAL,body>"{%"[ \t]*"comment"[ \t]*"%}"          BEGIN(comment);
<comment>"{%"[ \t]*"endcomment"[ \t]*"%}"            BEGIN(body);
<comment>"\n"                                        ++yylineno;
<comment>.                                           ;

<raw>"{%"[ \t]*"endraw"[ \t]*"%}"  { BEGIN(body); return T_ENDRAW; }
<raw>"\n"                          { ++yylineno; yylval.pRawChar = yytext[0]; return T_RAWCHAR; }
<raw>.                             { yylval.pRawChar = yytext[0]; return T_RAWCHAR; }

<lang>"raw"[ \t]*"%}"     { BEGIN(raw);  return T_RAW; }
<lang>"}}"                { BEGIN(body); return END_OUTPUT; }
<lang>"%}"                { BEGIN(body); return END_TAG; }

<lang>"project"           { return T_PROJECT; }
<lang>"endproject"        { return T_ENDPROJECT; }
<lang>"file"              { last_was_begin_tag = 0; return T_FILE; }
<lang>"endfile"           { return T_ENDFILE; }
<lang>"snippet"           { return T_SNIPPET; }
<lang>"endsnippet"        { return T_ENDSNIPPET; }
<lang>"binary"            { if (last_was_begin_tag) { BEGIN(binary); } return T_BINARY; }
<lang>"endbinary"         { return T_ENDBINARY; }

<lang>"append"            { return F_APPEND; }
<lang>"capitalize"        { return F_CAPITALIZE; }
<lang>"upcase"            { return F_UPCASE; }
<lang>"downcase"          { return F_DOWNCASE; }

<lang>"module"            { return T_MODULE; }
<lang>"endmodule"         { return T_ENDMODULE; }

<lang>{IDENT}             { yylval.pIdentifier = strdup(yytext); return IDENTIFIER; }
<lang>\"([^\\\"]|\\.)*\"  { yylval.pStringLiteral = strdup(yytext); return STRING; }

<lang>"|"                 { return '|'; }
<lang>"."                 { return '.'; }
<lang>":"                 { return ':'; }

<lang>"\n"                { ++yylineno; /* whitespace */ }
<lang>[ \t\r]+            { /* whitespace */ }

<lang>.                   { char buf[1024]; sprintf(buf,"Invalid char `%s' in template tag", yytext);
                            yyerror(buf); exit(1); }




<binary>"%}"                { return END_TAG; }
<binary>"\n"                { ++yylineno; /* whitespace */ }
<binary>[ \t\r]+            { /* whitespace */ }

<binary>{hextail}           { /* without 0x */ yylval.pByte = make_byte(yytext);   return HEX_LITERAL; }
<binary>{hex_char}          { /* with 0x */    yylval.pByte = make_byte(yytext+2); return HEX_LITERAL; }

<binary>{IDENT}             { yylval.pIdentifier = strdup(yytext); return IDENTIFIER; }
<binary>\"([^\\\"]|\\.)*\"  { yylval.pStringLiteral = strdup(yytext); return STRING; }

<binary>"{%"                { BEGIN(lang); last_was_begin_tag = 1; return BEGIN_TAG; }
<binary>.                   { char buf[1024]; sprintf(buf,"Invalid char `%s' in binary snippet", yytext);
                              yyerror(buf); exit(1); }




%%


/* called at end of input (file/string) */
int yywrap() {
  return 1;
}

static unsigned char make_byte(const char* str)
{
  int i;
  sscanf(str,"%x",&i);
  return (unsigned char) i;
}



static void* headerptr = NULL;
void set_header(TypeHeader* p)
{
  headerptr = p;
}

static void* resultptr = NULL;
void set_resultptr(TypeInput* p)
{
  resultptr = p;
}

extern int opt_parser_debug; /* defined in main.cc */
void* parse_string(const char* input, void** header)
{
  YY_BUFFER_STATE bs = yy_scan_string(input);

  if (opt_parser_debug) {	  /* enable/disable debugging */
    yy_flex_debug = 1;
    yydebug=1;
  }
  else {
    yy_flex_debug = 0;
    yydebug=0;
  }

  int result = yyparse();
  
  yy_delete_buffer(bs);

  if (result != 0) {
    *header = NULL;
    return NULL;
  }
  else {
   *header = headerptr;
   return resultptr; /* TODO: need to return the pointer to the tree somehow */
  }
}



void free_resultptr(void* p)
{
  /* TODO: free the parse tree, dont forget to 
   * free the stdrup() strings that are allocated in scanner.l */
}

void free_headerptr(void* p)
{
  /* TODO: free the header tree, dont forget to 
   * free the stdrup() strings that are allocated in scanner.l */
}





