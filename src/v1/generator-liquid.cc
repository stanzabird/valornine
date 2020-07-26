#include "symtab.h"
#include "generator.h"

#include <fstream>
#include <string>
#include <algorithm>

#include <sys/stat.h>		// for mkdir()


// --------------------------------------------------------------------------------------
//
// main function: generate_from_input()
//
// --------------------------------------------------------------------------------------





/*
 * This part executes the Liquid-like template language in files and snippets.
 */

extern std::string sanitize_string_literal(char* str);

void fileparse(std::string path, std::string& dir, std::string& name, std::string& ext);
void make_dirs(std::string path);

void fileparse(std::string input_path, std::string& dir, std::string& name, std::string& ext)
{
  std::string path = input_path;
  std::replace(begin(path), end(path), '\\', '/');
  
  auto pos = path.find_last_of('/');
  if (pos != std::string::npos) {
    dir = path.substr(0,pos);
    path = path.substr(pos+1);
  }
  pos = path.find_last_of('.');
  if (pos == std::string::npos || pos == 0) {
    name = path;
    ext = "";
  }
  else {
    name = path.substr(0,pos);
    ext = path.substr(pos+1);
  }
}

void make_dirs(std::string path)
{
  auto pos = path.find_first_of('/');

  while (pos != std::string::npos)
    {
      std::string s = path.substr(0,pos);
#ifndef __MINGW32__
      mkdir(s.c_str(), 0755);
#else
      mkdir(s.c_str());
#endif

      pos = path.find_first_of('/',pos+1);
    }
}



void expand_template(std::ofstream& ofs, SymTab& symtab, TypeInput* content_begin, TypeInput* content_end, std::vector<std::string> modules);




SymTab::DirectValue handle_object(TypeObject* object, SymTab& symtab)
{
  SymTab::DirectValue v;
  
  switch (object->type)
    {
    case 1:			// string_literal
      {
	v.type = SymTab::tString;
	v.str = sanitize_string_literal(object->string_literal);
      }
    break;
    case 2:			// identifier
      {
	std::string ident = object->identifier;
	
	if (symtab.is_defined(ident))
	  v = symtab.get_direct_value(ident);
	else
	  v.type = SymTab::tNil;
      }
      break;
    case 3:			// object_name,member_name
      {
	std::string ident = std::string(object->object_name) + "." + object->member_name;
	
	if (symtab.is_defined(ident))
	  v = symtab.get_direct_value(ident);
	else
	  v.type = SymTab::tNil;
      }
      break;	
    };
  return v;
};
  
void expand_template(std::ofstream& ofs, SymTab& symtab, TypeInput* content_begin, TypeInput* content_end, std::vector<std::string> modules)
{
  bool first_return = true, first_return_raw = true;
  bool module_disabled_flag = false;
  
  for (TypeInput* token = content_begin; token != content_end; token = token->next)
    switch (token->data->type)
      {
      case 0:			// (empty)
	break;

      case 1:			// TypeChars
	{
	  // no output when we're not in the right module
	  if (module_disabled_flag) break;
	  
	  std::string s;
	  
	  for (TypeChars* p = token->data->chars; p; p = p->next)
	    {
	      if (first_return)
		{
		  first_return = false;
		  if (p->value == '\n')
		    continue;
		}
	      s += p->value;
	    }
	  
	  ofs << s;
	}
	break;

      case 5:			// TypeRawChars
	{
	  // no output when we're not in the right module
	  if (module_disabled_flag) break;
	  
	  std::string s;
	  
	  for (TypeRawChars* p = token->data->rawchars; p; p = p->next)
	    {
	      if (first_return_raw)
		{
		  first_return_raw = false;
		  if (p->value == '\n')
		    continue;
		}
	      s += p->value;
	    }
	  
	  ofs << s;
	  first_return_raw = true;
	}
	break;
	
      case 4:			// TypeHexChars
	break;
	
      case 2:			// TypeObjectExpr
	{
	  // no output when we're not in the right module
	  if (module_disabled_flag) break;
	  
	  TypeObjectExpr* object_expr = token->data->object_expr;

	  SymTab::DirectValue v;
	  
	  TypeObject* object = object_expr->object;
	  
	  v = handle_object(object,symtab);

	    for (TypeFilterList* q = object_expr->filter_list; q; q = q->next)
	      {
		TypeFilter* filter = q->filter;

		switch (filter->type)
		  {
		  case 1:	// TypeFilterAppend
		    {
		      TypeFilterAppend* append = filter->filter_append;

		      auto arg1 = handle_object(append->object,symtab);
		      if (v.type == SymTab::tString && arg1.type == SymTab::tString) {
			v.str = v.str + arg1.str;
		      }
		    }
		    break;
		  case 2:	// TypeFilterCapitalize
		    {
		      TypeFilterCapitalize* capitalize = filter->filter_capitalize; // always NULL
		      if (v.type == SymTab::tString) {
			if (v.str.size() >= 1) { v.str[0] = toupper(v.str[0]); }
		      }
		    }
		    break;
		  case 3:	// TypeFilterUpcase
		    {
		      TypeFilterUpcase* upcase = filter->filter_upcase; // always NULL
		      if (v.type == SymTab::tString) {
			std::transform(begin(v.str), end(v.str), begin(v.str), ::toupper);
		      }
		    }
		    break;
		  case 4:	// TypeFilterDowncase
		    {
		      TypeFilterDowncase* downcase = filter->filter_downcase; // always NULL
		      if (v.type == SymTab::tString) {
			std::transform(begin(v.str), end(v.str), begin(v.str), ::tolower);
		      }
		    }
		    break;
		  }
	      }

	    // print 'v'
	    {
	      switch (v.type)
		{
		case SymTab::tString:
		  ofs << v.str;
		  break;
		case SymTab::tNumber:
		  ofs << v.num;
		break;
		case SymTab::tBoolean:
		if (v.b)
		  ofs << "true";
		else
		  ofs << "false";
		break;
		}
	    }
	  }
	  break;
	  
	case 3:			// TypeTag
	  {
	    TypeTag* tag = token->data->tag;

	    switch (tag->type)
	      {
	      case 1:		// TypeTagProject
	      case 2:		// TypeTagEndProject
	      case 3:		// TypeTagFile
	      case 4:		// TypeTagEndFile
	      case 5:		// TypeTagFileSnippet
	      case 6:		// TypeTagSnippet
	      case 7:		// TypeTagEndSnippet
	      case 8:		// TypeTagFileBinary
	      case 9:		// TypeTagBinary
	      case 10:		// TypeTagEndBinary
		break;		// We're done with that...
		
	      case 11:		// TypeTagModule
		{
		  TypeTagModule* m = tag->tag_module;
		  std::string module = m->ident_modulename;

		  bool in_modules = false;
		  
		  for (auto s : modules)
		    if (s == module) in_modules = true;
		  
		  if (in_modules)
		    {
		      module_disabled_flag = false;
		    }
		  else
		    {
		      module_disabled_flag = true;
		    }

		  first_return = true;
		}
		break;
		
	      case 12:		// TypeTagEndModule
		{
		  TypeTagEndModule* endmodule = tag->tag_endmodule;
		  module_disabled_flag = false;
		  
		  first_return = true;
		}
		break;
	      }
	  }
	  break;
      }
}


