/* expect 1 shift/reduce conflict */
%expect 2

/* the second shift/reduce conflicht was introduced when implementing 'hexcodes' */

%{
#include "parser.types.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/* function used to get the actual syntax tree from the
 * grammar into the parse_string() main function.
 * Note: This function is located in scanner.l */
void set_resultptr(TypeInput* result);
void set_header(TypeHeader* header);


/* Syntax tree construction functions */
TypeInput* createTypeInputEmpty();
TypeInput* addTypeInputChars(TypeInput*, TypeChars*);
TypeInput* addTypeInputObjectExpr(TypeInput*, TypeObjectExpr*);
TypeInput* addTypeInputTag(TypeInput*, TypeTag*);

TypeChars* createCharsCharLiteral(char);
TypeChars* addCharsCharLiteral(TypeChars*, char);

TypeObjectExpr* createObjectExpr(TypeObject*);
TypeObjectExpr* addObjectExprFilter(TypeObjectExpr*, TypeFilter*);


/* header types */
TypeHeader* createTypeHeader(TypeHVal*);
TypeHeader* addTypeHeaderHVal(TypeHeader*,TypeHVal*);
TypeHVal* createHVal(char*, TypeChars*);


/* objects */
TypeObject* createObjectFromStringLiteral(char*);
TypeObject* createObjectFromIdentifier(char*);
TypeObject* createObjectFromMember(char*, char*);


/* binary support */
/* TypeHexCodes --maps to--> TypeChars; 
   char --maps to-->unsigned char */
TypeInput*     addTypeInputHexCodes(TypeInput*, TypeHexCodes*);
TypeHexCodes*  createHexCodesHexLiteral(unsigned char);
TypeHexCodes*  addHexCodesHexLiteral(TypeHexCodes*, unsigned char);
TypeTag*       createTagFileBinary(char*,char*);
TypeTag*       createTagBinary(char*);
TypeTag*       createTagEndBinary();

TypeInput*     addTypeInputRawChars(TypeInput*, TypeRawChars*);
TypeRawChars*  createRawCharsRawChar(char);
TypeRawChars*  addRawCharsRawChar(TypeRawChars*, char);

/* tags */
TypeTag* createTagProject(char*);
TypeTag* createTagEndProject();
TypeTag* createTagFile(char*);
TypeTag* createTagEndFile();
TypeTag* createTagFileSnippet(char*,char*);
TypeTag* createTagSnippet(char*);
TypeTag* createTagEndSnippet();

TypeTag* createTagModule(char*);
TypeTag* createTagEndModule();


/* filters */
TypeFilter* createFilterFromAppend(TypeFilterAppend*);
TypeFilterAppend* createFilterAppend(TypeObject*);

TypeFilter* createFilterFromCapitalize(TypeFilterCapitalize*);
TypeFilterCapitalize* createFilterCapitalize();

TypeFilter* createFilterFromUpcase(TypeFilterUpcase*);
TypeFilterUpcase* createFilterUpcase();

TypeFilter* createFilterFromDowncase(TypeFilterDowncase*);
TypeFilterDowncase* createFilterDowncase();


%}


%token BEGIN_OUTPUT
%token END_OUTPUT
%token BEGIN_TAG
%token END_TAG
%token HVAL_DELIM


%token<pChar>           CHAR_LITERAL
%token<pStringLiteral>  STRING 
%token<pIdentifier>     IDENTIFIER


 /* tokens for use in statements (statements == TAGS) */
%token T_PROJECT T_ENDPROJECT T_FILE T_ENDFILE T_SNIPPET T_ENDSNIPPET
 /* binary snippets */
%token T_BINARY T_ENDBINARY
%token <pByte> HEX_LITERAL

/* raw mode */
%token <pRawChar> T_RAWCHAR
%token T_RAW T_ENDRAW
%token T_MODULE T_ENDMODULE

 /* tokens used as filter names: */
%token F_APPEND F_CAPITALIZE F_UPCASE F_DOWNCASE


%union {
  TypeInput* pInput;
  TypeChars* pChars;
  TypeObjectExpr* pObjectExpr;

  TypeHeader* pHeader;
  TypeHVal* pHVal;

  TypeObject* pObject;
  char pChar;
  unsigned char pByte;
  char* pStringLiteral;
  char* pIdentifier;
  TypeHexCodes* pHexCodes;

  char pRawChar;
  TypeRawChars* pRawChars;

  TypeTag* pTag;

  TypeFilter* pFilter;
  TypeFilterAppend* pFilterAppend;
  TypeFilterCapitalize* pFilterCapitalize;
  TypeFilterUpcase* pFilterUpcase;
  TypeFilterDowncase* pFilterDowncase;
};


%type <pInput> input;
%type <pChars> chars;
%type <pObjectExpr> object_expr;
%type <pTag> tag;
%type <pObject> object;
%type <pHeader> header;
%type <pHVal> hval;
%type <pChars> hstr;
%type <pHexCodes> hexcodes;  /* binary */
%type <pRawChars> rawchars;

%type <pFilter> filter;
%type <pFilterAppend> append;
%type <pFilterCapitalize> capitalize;
%type <pFilterUpcase> upcase;
%type <pFilterDowncase> downcase;

%%


grammar:
  HVAL_DELIM header HVAL_DELIM input                        { set_header($2);    set_resultptr($4); } /* $4 is our syntax tree */
  | input                                                   { set_header(NULL);  set_resultptr($1); }
  ;



header:
  hval                             { $$ = createTypeHeader($1); }
  | header hval                    { $$ = addTypeHeaderHVal($1, $2); }
  ;

hval :
  IDENTIFIER ':' hstr '\n'         { $$ = createHVal($1,$3); }
  ;

hstr:
  CHAR_LITERAL                     { $$ = createCharsCharLiteral($1); }
  | hstr CHAR_LITERAL              { $$ = addCharsCharLiteral($1,$2); }
  ;




input:                                                      { $$ = createTypeInputEmpty(); }
  | input chars                                             { $$ = addTypeInputChars($1,$2); }
  | input BEGIN_OUTPUT object_expr END_OUTPUT               { $$ = addTypeInputObjectExpr($1,$3); }
  | input BEGIN_TAG tag END_TAG                             { $$ = addTypeInputTag($1,$3); }
  | input hexcodes                                          { $$ = addTypeInputHexCodes($1,$2); }
  | input BEGIN_TAG T_RAW rawchars T_ENDRAW                 { $$ = addTypeInputRawChars($1,$4); }
  | input BEGIN_TAG T_RAW T_ENDRAW                          /* following eachother without any content in between (ignored) */
  ;

chars:
  CHAR_LITERAL                                              { $$ = createCharsCharLiteral($1); }
  | chars CHAR_LITERAL                                      { $$ = addCharsCharLiteral($1,$2); }
  ;

hexcodes:
  HEX_LITERAL                                               { $$ = createHexCodesHexLiteral($1); }
  | hexcodes HEX_LITERAL                                    { $$ = addHexCodesHexLiteral($1,$2); }
  ;

rawchars:
  T_RAWCHAR                                                 { $$ = createRawCharsRawChar($1); }
  | rawchars T_RAWCHAR                                      { $$ = addRawCharsRawChar($1,$2); }
  ;



object_expr:
  object                                                    { $$ = createObjectExpr($1); }
  | object_expr '|' filter                                  { $$ = addObjectExprFilter($1,$3); }
  ;

object:
  STRING                                                    { $$ = createObjectFromStringLiteral($1); }
  | IDENTIFIER                                              { $$ = createObjectFromIdentifier($1); }
  | IDENTIFIER '.' IDENTIFIER                               { $$ = createObjectFromMember($1,$3); }
  ; /* TODO: STRING is not the only type in liquid 
     (NUMBER_INT, NUMBER_FLOAT, BOOLEAN, NIL, ARRAY) */





tag:
  T_PROJECT STRING                                          { $$ = createTagProject($2); }
  | T_ENDPROJECT                                            { $$ = createTagEndProject(); }
  | T_FILE STRING                                           { $$ = createTagFile($2); }
  | T_ENDFILE                                               { $$ = createTagEndFile(); }
  | T_FILE T_SNIPPET IDENTIFIER STRING                      { $$ = createTagFileSnippet($3,$4); }
  | T_FILE T_BINARY  IDENTIFIER STRING                      { $$ = createTagFileBinary($3,$4); }
  | T_SNIPPET IDENTIFIER                                    { $$ = createTagSnippet($2); }
  | T_ENDSNIPPET                                            { $$ = createTagEndSnippet(); }
  | T_BINARY IDENTIFIER                                     { $$ = createTagBinary($2); }
  | T_ENDBINARY                                             { $$ = createTagEndBinary(); }
  | T_MODULE IDENTIFIER                                     { $$ = createTagModule($2); }
  | T_ENDMODULE                                             { $$ = createTagEndModule(); }
  ;





filter:
  append                                                    { $$ = createFilterFromAppend($1); }
  | capitalize                                              { $$ = createFilterFromCapitalize($1); }
  | upcase                                                  { $$ = createFilterFromUpcase($1); }
  | downcase                                                { $$ = createFilterFromDowncase($1); }
  ;	/* TODO: just enumerate the rest of the filters a bit later... */

append:
  F_APPEND ':' object                                       { $$ = createFilterAppend($3); }
  ;

capitalize:
  F_CAPITALIZE                                              { $$ = createFilterCapitalize(); }

upcase:
  F_UPCASE                                                  { $$ = createFilterUpcase(); }
  ;

downcase:
  F_DOWNCASE                                                { $$ = createFilterDowncase(); }
  ;




%%

extern int yylineno;
extern char* yyfilename;

int yyerror(char *s) {
  fprintf(stderr, "%s:%d: error: %s\n", yyfilename, yylineno, s);
  exit(1);
}



/*
 *
 * Syntax tree construction functions.
 *
 */




/*
 * TypeInput 
 */

TypeInput* createTypeInputEmpty()
{
  TypeInput* input = malloc(sizeof(TypeInput));
  
  input->next = NULL;

  input->data = malloc(sizeof(TypeInputT));
  input->data->type = 0; /* empty */

  return input;
}

TypeInput* addTypeInputChars(TypeInput* input,TypeChars* chars)
{
  TypeInput* root = input;

  while (input->next) input = input->next;
  input->next = malloc(sizeof(TypeInput));
  input->next->next = NULL;

  input->next->data = malloc(sizeof(TypeInputT));
  input->next->data->type = 1;
  input->next->data->chars = chars;

  return root;
}

TypeInput* addTypeInputObjectExpr(TypeInput* input, TypeObjectExpr* object_expr)
{
  TypeInput* root = input;

  while (input->next) input = input->next;
  input->next = malloc(sizeof(TypeInput));
  input->next->next = NULL;

  input->next->data = malloc(sizeof(TypeInputT));
  input->next->data->type = 2;
  input->next->data->object_expr = object_expr;

  return root;
}

TypeInput* addTypeInputTag(TypeInput* input, TypeTag* tag)
{
  TypeInput* root = input;

  while (input->next) input = input->next;
  input->next = malloc(sizeof(TypeInput));
  input->next->next = NULL;

  input->next->data = malloc(sizeof(TypeInputT));
  input->next->data->type = 3;
  input->next->data->tag = tag;

  return root;
}


/* 
 * TypeChars 
 */

TypeChars* createCharsCharLiteral(char c)
{
  TypeChars* chars = malloc(sizeof(TypeChars));
  
  chars->next = NULL;
  chars->head = NULL;
  chars->value = c;

  return chars;
}

TypeChars* addCharsCharLiteral(TypeChars* chars, char c)
{
  TypeChars* root = chars;
  
  if (root->head == NULL)
    {
      while (chars->next) chars = chars->next;
      root->head = chars;
    }
  else
    {
      chars = root->head;
    }
  
  chars->next = malloc(sizeof(TypeChars));
  chars->next->next = NULL;
  chars->next->value = c;

  root->head = chars->next;

  return root;
}


/*
 * TypeObjectExpr
 */

TypeObjectExpr* createObjectExpr(TypeObject* object)
{
  TypeObjectExpr* object_expr = malloc(sizeof(TypeObjectExpr));

  object_expr->object = object;
  object_expr->filter_list = NULL;

  return object_expr;
}

TypeObjectExpr* addObjectExprFilter(TypeObjectExpr* object_expr, TypeFilter* filter)
{
  TypeFilterList* p = malloc(sizeof(TypeFilterList));
  TypeFilterList* q = object_expr->filter_list;

  p->next = NULL;
  p->filter = filter;

  if (!q) {
    object_expr->filter_list = p;
  }
  else {
    while (q->next) q = q->next;
    q->next = p;
  }

  return object_expr;
}


/* 
 * header types 
 */

TypeHeader* createTypeHeader(TypeHVal* hval)
{
  TypeHeader* header = malloc(sizeof(TypeHeader));

  header->next = NULL;
  header->hval = hval;

  return header;
}

TypeHeader* addTypeHeaderHVal(TypeHeader* root, TypeHVal* hval)
{
  TypeHeader* header = root;

  while (header->next) header = header->next;
  header->next = malloc(sizeof(TypeHeader));
  header->next->next = NULL;
  header->next->hval = hval;

  return root;
}

TypeHVal* createHVal(char* ident, TypeChars* value)
{
  TypeHVal* hval = malloc(sizeof(TypeHVal));

  hval->ident = ident;
  hval->value = value;

  return hval;
}




/*
 * TypeObject
 */

TypeObject* createObjectFromStringLiteral(char* string_literal)
{
  TypeObject* object = malloc(sizeof(TypeObject));
  object->lineno = yylineno;
  object->string_literal = object->identifier = object->object_name = object->member_name = NULL;

  object->type = 1;
  object->string_literal = string_literal;
  
  return object;
}

TypeObject* createObjectFromIdentifier(char* identifier)
{
  TypeObject* object = malloc(sizeof(TypeObject));
  object->lineno = yylineno;
  object->string_literal = object->identifier = object->object_name = object->member_name = NULL;

  object->type = 2;
  object->identifier = identifier;

  return object;
}

TypeObject* createObjectFromMember(char* object_name, char* member_name)
{
  TypeObject* object = malloc(sizeof(TypeObject));
  object->lineno = yylineno;
  object->string_literal = object->identifier = object->object_name = object->member_name = NULL;

  object->type = 3;
  object->object_name = object_name;
  object->member_name = member_name;

  return object;
}



/*
 * TypeTag
 *
 */

TypeTag* createTagProject(char* str_projectname)
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 1;
  tag->tag_project = malloc(sizeof(TypeTagProject));
  tag->tag_project->str_projectname = str_projectname;
  
  return tag;
}

TypeTag* createTagEndProject()
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 2;
  tag->tag_endproject = NULL;
  
  return tag;
}

TypeTag* createTagFile(char* str_filename)
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 3;
  tag->tag_file = malloc(sizeof(TypeTagFile));
  tag->tag_file->str_filename = str_filename;
  
  return tag;
}

TypeTag* createTagEndFile()
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 4;
  tag->tag_endfile = NULL;
  
  return tag;
}

TypeTag* createTagFileSnippet(char* ident_snippetname, char* str_snippet_outputfile)
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 5;
  tag->tag_file_snippet = malloc(sizeof(TypeTagFileSnippet));
  tag->tag_file_snippet->ident_snippetname = ident_snippetname;
  tag->tag_file_snippet->str_snippet_outputfile = str_snippet_outputfile;
  
  return tag;
}

TypeTag* createTagSnippet(char* ident_snippetname)
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 6;
  tag->tag_snippet = malloc(sizeof(TypeTagSnippet));
  tag->tag_snippet->ident_snippetname = ident_snippetname;
  
  return tag;
}

TypeTag* createTagEndSnippet()
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 7;
  tag->tag_endsnippet = NULL;
  
  return tag;
}


/*
 * TypeFilter
 */

TypeFilter* createFilterFromAppend(TypeFilterAppend* filter_append)
{
  TypeFilter* filter = malloc(sizeof(TypeFilter));

  filter->lineno = yylineno;
  filter->type = 1;
  filter->filter_append = filter_append;

  return filter;
}
TypeFilter* createFilterFromCapitalize(TypeFilterCapitalize* filter_capitalize)
{
  TypeFilter* filter = malloc(sizeof(TypeFilter));

  filter->lineno = yylineno;
  filter->type = 2;
  filter->filter_capitalize = filter_capitalize;

  return filter;
}

/* specific filters */
TypeFilterAppend* createFilterAppend(TypeObject* object)
{
  TypeFilterAppend* append = malloc(sizeof(TypeFilterAppend));

  append->lineno = yylineno;
  append->object = object;

  return append;
}

TypeFilterCapitalize* createFilterCapitalize()
{
  TypeFilterCapitalize* capitalize = malloc(sizeof(TypeFilterCapitalize));

  capitalize->lineno = yylineno;
  
  return capitalize;
}






/* binary support */
/* TypeHexCodes --maps to--> TypeChars; 
   char --maps to-->unsigned char */
TypeInput* addTypeInputHexCodes(TypeInput* input, TypeHexCodes* hexcodes)
{
  TypeInput* root = input;

  while (input->next) input = input->next;
  input->next = malloc(sizeof(TypeInput));
  input->next->next = NULL;

  input->next->data = malloc(sizeof(TypeInputT));
  input->next->data->type = 4;
  input->next->data->hexcodes = hexcodes;

  return root;
}
TypeHexCodes* createHexCodesHexLiteral(unsigned char b)
{
  TypeHexCodes* chars = malloc(sizeof(TypeHexCodes));
  
  chars->next = NULL;
  chars->head = NULL;
  chars->value = b;

  return chars;
}
TypeHexCodes* addHexCodesHexLiteral(TypeHexCodes* hexcodes, unsigned char b)
{
  TypeHexCodes* root = hexcodes;

  if (root->head == NULL)
    {
      while (hexcodes->next) hexcodes = hexcodes->next;
      root->head = hexcodes;
    }
  else
    {
      hexcodes = root->head;
    }
  
  hexcodes->next = malloc(sizeof(TypeHexCodes));
  hexcodes->next->next = NULL;
  hexcodes->next->value = b;

  root->head = hexcodes->next;
  
  return root;
}
TypeTag* createTagFileBinary(char* ident_binaryname, char* str_binary_outputfile)
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 8;
  tag->tag_file_binary = malloc(sizeof(TypeTagFileBinary));
  tag->tag_file_binary->ident_binaryname = ident_binaryname;
  tag->tag_file_binary->str_binary_outputfile = str_binary_outputfile;
  
  return tag;
}
TypeTag* createTagBinary(char* ident_binaryname)
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 9;
  tag->tag_binary = malloc(sizeof(TypeTagBinary));
  tag->tag_binary->ident_binaryname = ident_binaryname;
  
  return tag;
}
TypeTag* createTagEndBinary()
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 10;
  tag->tag_endbinary = NULL;
  
  return tag;
}


TypeTag* createTagModule(char* ident_modulename)
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 11;
  tag->tag_module = malloc(sizeof(TypeTagModule));
  tag->tag_module->ident_modulename = ident_modulename;
  
  return tag;
}
TypeTag* createTagEndModule()
{
  TypeTag* tag = malloc(sizeof(TypeTag));

  tag->lineno = yylineno;
  tag->type = 12;
  tag->tag_endmodule = NULL;
  
  return tag;
}



/* 
 * Filters ==>   |upcase  and |downcase.
 */


TypeFilter* createFilterFromUpcase(TypeFilterUpcase* filter_upcase)
{
  TypeFilter* filter = malloc(sizeof(TypeFilter));

  filter->lineno = yylineno;
  filter->type = 3;
  filter->filter_upcase = filter_upcase;

  return filter;
}
TypeFilterUpcase* createFilterUpcase()
{
  TypeFilterUpcase* upcase = malloc(sizeof(TypeFilterUpcase));

  upcase->lineno = yylineno;
  
  return upcase;
}


TypeFilter* createFilterFromDowncase(TypeFilterDowncase* filter_downcase)
{
  TypeFilter* filter = malloc(sizeof(TypeFilter));

  filter->lineno = yylineno;
  filter->type = 4;
  filter->filter_downcase = filter_downcase;

  return filter;
}
TypeFilterDowncase* createFilterDowncase()
{
  TypeFilterDowncase* downcase = malloc(sizeof(TypeFilterDowncase));

  downcase->lineno = yylineno;
  
  return downcase;
}


/* Raw Characters */
TypeInput* addTypeInputRawChars(TypeInput* input, TypeRawChars* rawchars)
{
  TypeInput* root = input;

  while (input->next) input = input->next;
  input->next = malloc(sizeof(TypeInput));
  input->next->next = NULL;

  input->next->data = malloc(sizeof(TypeInputT));
  input->next->data->type = 5;
  input->next->data->rawchars = rawchars;

  return root;
}

TypeRawChars* createRawCharsRawChar(char c)
{
  TypeRawChars* rawchars = malloc(sizeof(TypeRawChars));
  
  rawchars->next = NULL;
  rawchars->head = NULL;
  rawchars->value = c;

  return rawchars;
}

TypeRawChars* addRawCharsRawChar(TypeRawChars* rawchars, char c)
{
  TypeRawChars* root = rawchars;

  if (root->head == NULL)
    {
      while (rawchars->next) rawchars = rawchars->next;
      root->head = rawchars;
    }
  else
    {
      rawchars = root->head;
    }
  
  rawchars->next = malloc(sizeof(TypeHexCodes));
  rawchars->next->next = NULL;
  rawchars->next->value = c;

  root->head = rawchars->next;
  
  return root;
}



