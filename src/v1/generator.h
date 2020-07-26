#ifndef INCLUDED_API_H
#define INCLUDED_API_H

#include <vector>
#include <string>
#include <map>

#include "parser.types.h"

// Liquid language
//   https://shopify.github.io/liquid/
//
// Luiquid api (in ruby)
//   https://github.com/Shopify/liquid

namespace valornine
{
  
  struct TemplateData
  {
    void* parse_tree;
    void* parse_header;
    
  public:
    TemplateData(void*,void*);
    bool error() { return parse_tree == nullptr && parse_header == nullptr; }
    
    void render_project(std::string project_name, std::string project_type,
			std::map<std::string,std::string> parameters = std::map<std::string,std::string>{}, std::vector<std::string> modules
			= std::vector<std::string>{});
    void list();
    void print();
    void lsmod();
  };

  TemplateData parse(std::string input);

  // for error reporting
  extern std::string datafile_name;
}

std::string sanitize_string_literal(char* str);
std::string chars2str(TypeChars* chars);
std::vector<unsigned char> hexcodes2buffer(TypeHexCodes* hexcodes);

#endif
