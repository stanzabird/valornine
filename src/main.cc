extern "C" {
#include "syntax/parser.h"
}

int main(int argc,char* argv[])
{
  const bool debug = true;
  extern int yy_flex_debug;
  if (debug) {
    yy_flex_debug = 1;
    yydebug = 1;
  }
  else {
    yy_flex_debug = 0;
    yydebug = 0;
  }
  yyparse();
  return 0;
}
