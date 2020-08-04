%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int yylex (void);
void yyerror (char const *s);
extern int yylineno;
%}






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
%token TOK_GUID /* this one is to generate a guid (needed for visual studio) */
 /* BEGIN-END TOKENS */
%token /*TOK_FILE*/ TOK_ENDFILE
%token TOK_PROJECT TOK_ENDPROJECT
%token TOK_TEMPLATE TOK_ENDTEMPLATE
%token   TOK_EXTENDS
%token TOK_EXEC TOK_ENDEXEC
%token TOK_MULTILINE TOK_ENDMULTILINE
%token /*TOK_SNIPPET*/ TOK_ENDSNIPPET
%token /*TOK_BINARY*/ TOK_ENDBINARY
%token TOK_MODULE TOK_ENDMODULE
%token TOK_VAR TOK_ENDVAR





%%





input :
  %empty
  | stmt_var
  | stmt_project_or_template
  | stmt_snippet
  | stmt_binary
  | input stmt_var
  | input stmt_project_or_template
  | input stmt_snippet
  | input stmt_binary
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
stmt_set_guid :
  TOK_OPEN TOK_GUID IDENTIFIER TOK_CLOSE
  ;






/* begin-end like statements */
stmt_file :
  TOK_OPEN TOK_FILE STRING TOK_CLOSE text_contents TOK_OPEN TOK_ENDFILE TOK_CLOSE
  | TOK_OPEN TOK_FILE STRING TOK_CLOSE TOK_OPEN TOK_ENDFILE TOK_CLOSE
  ;

stmt_project_or_template :
    TOK_OPEN TOK_PROJECT  STRING TOK_CLOSE TOK_OPEN TOK_ENDPROJECT  TOK_CLOSE
  | TOK_OPEN TOK_TEMPLATE STRING TOK_CLOSE TOK_OPEN TOK_ENDTEMPLATE TOK_CLOSE
  | TOK_OPEN TOK_PROJECT  STRING TOK_CLOSE content_project_or_template TOK_OPEN TOK_ENDPROJECT  TOK_CLOSE
  | TOK_OPEN TOK_TEMPLATE STRING TOK_CLOSE content_project_or_template TOK_OPEN TOK_ENDTEMPLATE TOK_CLOSE
  | TOK_OPEN TOK_PROJECT  STRING extends_list TOK_CLOSE TOK_OPEN TOK_ENDPROJECT  TOK_CLOSE
  | TOK_OPEN TOK_TEMPLATE STRING extends_list TOK_CLOSE TOK_OPEN TOK_ENDTEMPLATE TOK_CLOSE
  | TOK_OPEN TOK_PROJECT  STRING extends_list TOK_CLOSE content_project_or_template TOK_OPEN TOK_ENDPROJECT  TOK_CLOSE
  | TOK_OPEN TOK_TEMPLATE STRING extends_list TOK_CLOSE content_project_or_template TOK_OPEN TOK_ENDTEMPLATE TOK_CLOSE
  ;

extends_list :
  TOK_EXTENDS STRING /* single inheritance */
  | extends_list TOK_EXTENDS STRING /* multiple inheritance */
  ;

stmt_exec :
  TOK_OPEN TOK_EXEC TOK_CLOSE TOK_OPEN TOK_ENDEXEC TOK_CLOSE
  TOK_OPEN TOK_EXEC TOK_CLOSE content_exec TOK_OPEN TOK_ENDEXEC TOK_CLOSE
  ;
stmt_multiline :
  TOK_OPEN TOK_MULTILINE IDENTIFIER TOK_CLOSE text_contents TOK_OPEN TOK_ENDMULTILINE TOK_CLOSE
  | TOK_OPEN TOK_MULTILINE IDENTIFIER TOK_CLOSE TOK_OPEN TOK_ENDMULTILINE TOK_CLOSE
  ;
stmt_snippet :
  TOK_OPEN TOK_SNIPPET IDENTIFIER TOK_CLOSE text_contents TOK_OPEN TOK_ENDSNIPPET TOK_CLOSE
  | TOK_OPEN TOK_SNIPPET IDENTIFIER TOK_CLOSE TOK_OPEN TOK_ENDSNIPPET TOK_CLOSE
  ;
stmt_binary :
  TOK_OPEN TOK_BINARY IDENTIFIER TOK_CLOSE hexcodes TOK_OPEN TOK_ENDBINARY TOK_CLOSE
  | TOK_OPEN TOK_BINARY IDENTIFIER TOK_CLOSE TOK_OPEN TOK_ENDBINARY TOK_CLOSE
  ;

stmt_module :
  TOK_OPEN TOK_MODULE IDENTIFIER TOK_CLOSE TOK_OPEN TOK_ENDMODULE TOK_CLOSE
  | TOK_OPEN TOK_MODULE IDENTIFIER TOK_CLOSE text_contents TOK_OPEN TOK_ENDMODULE TOK_CLOSE
  ;


stmt_var :
  TOK_OPEN TOK_VAR IDENTIFIER TOK_CLOSE TOK_OPEN TOK_ENDVAR TOK_CLOSE
  | TOK_OPEN TOK_VAR IDENTIFIER TOK_CLOSE var_contents TOK_OPEN TOK_ENDVAR TOK_CLOSE
  ;

var_contents :
   stmt_multiline
  | stmt_set_string
  | stmt_set_guid
  | var_contents stmt_multiline
  | var_contents stmt_set_string
  | var_contents stmt_set_guid
  ;






/* please note that templates and projects have exactly the same type of contents */
content_project_or_template :
    stmt_file_fetch
  | stmt_file_snippet
  | stmt_file_binary
  | stmt_set_string
  | stmt_set_guid
    
  /* begin-end statments */
  | stmt_file
  | stmt_exec /* git init statements could go here... */
  | stmt_multiline
  | stmt_project_or_template_module
  ;

stmt_project_or_template_module :
  TOK_OPEN TOK_MODULE IDENTIFIER TOK_CLOSE TOK_OPEN TOK_ENDMODULE TOK_CLOSE
  | TOK_OPEN TOK_MODULE IDENTIFIER TOK_CLOSE content_project_or_template TOK_OPEN TOK_ENDMODULE TOK_CLOSE
  ;



content_exec:
  CHAR_LITERAL
  | content_exec CHAR_LITERAL
  ;

hexcodes:
  HEX_LITERAL
  | hexcodes HEX_LITERAL
  ;

text_contents : 
  CHAR_LITERAL
  | text_contents CHAR_LITERAL
  | stmt_exec
  | text_contents stmt_exec
  | stmt_module
  | text_contents stmt_module
  ;



%%

void yyerror (char const *s) {
  printf("parser.y: yyerror(): line %d: %s\nExiting...\n", yylineno,s);
  exit(EXIT_FAILURE);
}
