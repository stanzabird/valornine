#include <config.h>
#include "generator.h"

#include <iostream>
#include <algorithm>

void parse_tree_lsmod(TypeInput* parse_tree)
{
  std::map<std::string,std::vector<std::string>> mods;
  std::string current_project;
  
  for (TypeInput* p = parse_tree; p; p = p->next)
    {
      switch (p->data->type)
	{
	case 3:			// TypeTag
	  {
	    TypeTag* tag = p->data->tag;

	    switch (tag->type)
	      {
	      case 1:		// TypeTagProject
		{
		  TypeTagProject* p = tag->tag_project;
		  current_project = sanitize_string_literal(p->str_projectname);

		  if (mods.find(current_project) == mods.end())
		    mods[current_project] = std::vector<std::string>{};
		}
		break;
		
	      case 2:		// TypeTagEndProject
		{
		  current_project = "";
		}
		break;
		
	      case 11:		// TypeTagModule
		{
		  TypeTagModule* m = tag->tag_module;
		  std::string modname = m->ident_modulename;

		  if (current_project != "")
		    mods[current_project].push_back(modname);
		}
		break;
	      }
	  }
	  break;
	}
    }

  // print the data neatly
  for (auto proj : mods)
    {
      std::cout << proj.first << ":";

      // pretty print the list of modules
      std::vector<std::string> pretty;
      
      for (auto mod : proj.second) {
	if (std::find(pretty.begin(),pretty.end(),mod) == pretty.end())
	  pretty.push_back(mod);
      }
      
      std::sort(pretty.begin(),pretty.end());

      for (auto s : pretty)
	std::cout << ' ' << s;
      
      std::cout << std::endl;
    }
}




