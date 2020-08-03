%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
%}


%%

. {
  printf("scanner.l yylex(): Unexpected %c\nExiting...\n",*yytext);
  exit(EXIT_FAILURE);
}

%%
int yywrap() { return 1; }

