extern "C" {
#include "syntax/parser.h"
}

int main(int argc,char* argv[])
{
  yyparse();
  return 0;
}
