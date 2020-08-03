%{int yylex(){return 0;}char*yyfilename=0;int yyerror(){return 0;}%}
%token CHAR_LITERAL
%token HEX_LITERAL

/* please note that variable expansion does NOT occur at this level of parsing
 * the variables are expanded when the time comes to write the file contents. */

 /* variable expansion works all in STRING and in text_contents and multiline */
 /* its syntax:
  *  {{ std.year }} {{ self.project_name | toupper }}
  * BIG RULE: IF IT GIVES SYNTAX ERROR, IT ECHOS BACK BECAUSE ITS PROBABLY
  PART OF THE ORIGINAL TEXT WHERE JUST {{ HAPPENS TO COME UP */
 /* exec expansion in text_contents or multiline is done at time of variable 
  * expansion and the output of the script ends up in the file. */

 /* EXEC expansion on the project level happens *after* file generation */







 /* "{%" and "%}" */
%token TOK_OPEN TOK_CLOSE
%token IDENTIFIER STRING /* C-style identifier, C-style string */


 /* TOK_xxx is just keywords (keyword xxx) */

%token TOK_FILE TOK_FETCH TOK_SNIPPET TOK_BINARY
%token TOK_STRING /* MAYBE BOOLEANS/INTS IN THE FUTURE */

 /* BEGIN-END TOKENS */
%token /*TOK_FILE*/ TOK_ENDFILE
%token TOK_PROJECT TOK_ENDPROJECT
%token TOK_TEMPLATE TOK_ENDTEMPLATE
%token   TOK_EXTENDS
%token TOK_EXEC TOK_ENDEXEC
%token TOK_MULTILINE TOK_ENDMULTILINE
%token TOK_SNIPPET TOK_ENDSNIPPET
%token TOK_BINARY TOK_ENDBINARY

%%


input :
  | stmt_template
  | stmt_project
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
  /* empty, no inheritance */
  | TOK_EXTENDS STRING /* single inheritance */
  | extends_list TOK_EXTENDS STRING /* multiple inheritance */
  ;

stmt_exec :
  TOK_OPEN TOK_EXEC TOK_CLOSE content_exec TOK_OPEN TOK_ENDEXEC TOK_CLOSE
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

content_file :
  text_contents
  ;

/* please note that templates and projects have exactly the same type of contents */
content_template:
 | content_project
 ;

content_project:
  /* single statements */
  | stmt_file_fetch
  | stmt_file_snippet
  | stmt_file_binary
  | stmt_set_string
    
  /* begin-end statments */
  | stmt_file
  | stmt_exec /* git init statements could go here... */
  | stmt_multiline
  ;


/*content_comment:;*/
content_exec:
  | CHAR_LITERAL
  | content_exec CHAR_LITERAL
  ;

content_multiline: text_contents;
content_snippet: text_contents;

content_binary:
  | hexcodes
  ;
hexcodes:
  HEX_LITERAL
  | hexcodes HEX_LITERAL
  ;

text_contents : 
  /* empty */
  | CHAR_LITERAL
  | text_contents CHAR_LITERAL
  | stmt_exec
  | text_contents stmt_exec
  ;

%%

