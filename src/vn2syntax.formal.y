%token TOK_OPEN TOK_CLOSE
%token IDENTIFIER STRING

%token TOK_FILE TOK_FETCH TOK_SNIPPET TOK_BINARY
%token TOK_STRING /* MAYBE BOOLEANS/INTS IN THE FUTURE */

 /* BEGIN-END TOKENS */
%token /*TOK_FILE*/ TOK_ENDFILE
%token TOK_PROJECT TOK_ENDPROJECT
%token TOK_TEMPLATE TOK_ENDTEMPLATE
%token   TOK_EXTENDS
%token TOK_COMMENT TOK_ENDCOMMENT
%token TOK_EXEC TOK_ENDEXEC
%token TOK_MULTILINE TOK_ENDMULTILINE
%token TOK_SNIPPET TOK_ENDSNIPPET
%token TOK_BINARY TOK_ENDBINARY

%%

statement :
  /* single statements */
    stmt_file_fetch
  | stmt_file_snippet
  | stmt_file_binary
  | stmt_set_string
    
  /* begin-end statments */
  | stmt_file
  | stmt_project
  | stmt_template
  | stmt_comment
  | stmt_exec
  | stmt_multiline
  | stmt_snippet
  | stmt_binary
  ;

/* single statements */
stmt_file_fetch :
  TOK_OPEN TOK_FILE TOK_FETCH STRING STRING TOK_CLOSE
  ;
stmt_file_snippet :
  TOK_OPEN TOK_FILE TOK_SNIPPET IDENTIFIER STRING TOK_CLOSE
  ;
stmt_file_binary :
  TOK_OPEN TOK_FILE TOK_BINARY IDENTIFIER STRING TOK_CLOSE
  ;
stmt_set_string :
  TOK_OPEN TOK_STRING IDENTIFIER STRING TOK_CLOSE
  ;

/* begin-end like statements */
stmt_file :
  TOK_OPEN TOK_FILE STRING TOK_CLOSE content_file TOK_OPEN TOK_ENDFILE TOK_CLOSE
  ;
stmt_project :
  TOK_OPEN TOK_PROJECT STRING extends_list TOK_CLOSE content_project TOK_OPEN TOK_ENDPROJECT TOK_CLOSE
  ;
stmt_template :
  TOK_OPEN TOK_TEMPLATE STRING extends_list TOK_CLOSE content_template TOK_OPEN TOK_ENDTEMPLATE TOK_CLOSE
  ;
extends_list :
  /* empty */
  | TOK_EXTENDS STRING
  ;
stmt_comment :
  TOK_OPEN TOK_COMMENT TOK_CLOSE content_comment TOK_OPEN TOK_ENDCOMMENT TOK_CLOSE
  ;
stmt_exec :
  TOK_OPEN TOK_EXEC TOK_CLOSE content_exec TOK_OPEN TOK_ENDCOMMENT TOK_CLOSE
  ;
stmt_multiline :
  TOK_OPEN TOK_MULTILINE IDENTIFIER TOK_CLOSE content_multiline TOK_OPEN TOK_ENDMULTILINE TOK_CLOSE
  ;
stmt_snippet :
  TOK_OPEN TOK_SNIPPET IDENTIFIER TOK_CLOSE content_snippet TOK_OPEN TOK_ENDSNIPPET TOK_CLOSE
  ;
stmt_binary :
  TOK_OPEN TOK_BINARY IDENTIFIER TOK_CLOSE content_binary TOK_OPEN TOK_ENDBINARY TOK_CLOSE
  ;

/* content_xxx */
content_file:;
content_project:;
content_template:;
content_comment:;
content_exec:;
content_multiline:;
content_snippet:;
content_binary:;

%%

