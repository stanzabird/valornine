#include "generator.h"
#include <iostream>
#include <iomanip>


/*
 * print the parse. skeleton for all other functions that operate 
 * on the parse tree.
 */



void parse_tree_print(TypeInput* parse_tree, TypeHeader* parse_header)
{
  auto handle_object = [](TypeObject* object) {
    switch (object->type)
      {
      case 1:			// string_literal
	std::cout << object->string_literal;
	break;
      case 2:			// identifier
	std::cout << object->identifier;
	break;
      case 3:			// object_name,member_name
	std::cout << object->object_name << "." << object->member_name;
	break;
      };
  };
  
  auto handle_chars = [](TypeChars* chars) {
    for (TypeChars* q = chars; q; q = q->next)
      {
	std::cout << q->value;
      }
  };

  auto handle_rawchars = [](TypeRawChars* rawchars) {
    std::cout << "{% raw %}";
    for (TypeRawChars* q = rawchars; q; q = q->next)
      {
	std::cout << q->value;
      }
    std::cout << "{% endraw %}";
  };

  auto handle_hexcodes = [](TypeHexCodes* hexcodes) {

  	int pos = 0;
  	for (TypeHexCodes* q = hexcodes; q; q = q->next)
  	{
  		int tmp = q->value;

  		if (pos > 0) std::cout << ' ';

		std::cout
			<< std::hex
			<< std::setfill('0')
			<< std::setw(2)
			<< tmp
			;

		if (pos == 25) {
			pos = 0;
			std::cout << '\n';
		}
		else
			++pos;
  	}

	if (pos > 0) std::cout << '\n';
  };

  /* header parsing */
  if (parse_header)
    {
      std::cout << "---\n";
      
      for (TypeHeader* p = parse_header; p; p = p->next)
	{
	  TypeHVal* hval = p->hval;
	  
	  std::cout << hval->ident << ":";
	  handle_chars(hval->value);
	  std::cout << "\n";
	}
      
      std::cout << "---";
    }

  /* body parsing */
  for (TypeInput* p = parse_tree; p; p = p->next)
    {
      switch (p->data->type)
	{
	case 0:			// (empty)
	  break;
	  
	case 1:			// TypeChars
	  {
	    handle_chars(p->data->chars);
	  }
	  break;
	case 4: // TypeHexChars
	  {
	    handle_hexcodes(p->data->hexcodes);
	  }
	  break;

	case 5:
	  {
	    handle_rawchars(p->data->rawchars);
	  }
	  break;
	  
	case 2:			// TypeObjectExpr
	  {
	    TypeObjectExpr* object_expr = p->data->object_expr;

	    std::cout << "{{ ";
	    
	    TypeObject* object = object_expr->object;
	    handle_object(object);

	    for (TypeFilterList* q = object_expr->filter_list; q; q = q->next)
	      {
		TypeFilter* filter = q->filter;

		std::cout << " | ";
		
		switch (filter->type)
		  {
		  case 1:	// TypeFilterAppend
		    {
		      TypeFilterAppend* append = filter->filter_append;

		      std::cout << "append: ";
		      handle_object(append->object);
		    }
		    break;
		  case 2:	// TypeFilterCapitalize
		    {
		      TypeFilterCapitalize* capitalize = filter->filter_capitalize; // always NULL
		      
		      std::cout << "capitalize";
		    }
		    break;
		  case 3:	// TypeFilterUpcase
		    {
		      TypeFilterUpcase* upcase = filter->filter_upcase; // always NULL
		      
		      std::cout << "upcase";
		    }
		    break;
		  case 4:	// TypeFilterDowncase
		    {
		      TypeFilterDowncase* downcase = filter->filter_downcase; // always NULL
		      
		      std::cout << "downcase";
		    }
		    break;
		  }
	      }

	    std::cout << " }}";
	  }
	  break;
	  
	case 3:			// TypeTag
	  {
	    TypeTag* tag = p->data->tag;

	    switch (tag->type)
	      {
	      case 1:		// TypeTagProject
		{
		  TypeTagProject* project = tag->tag_project;
		  std::cout << "{% project " << project->str_projectname << " %}";
		}
		break;
	      case 2:		// TypeTagEndProject
		{
		  std::cout << "{% endproject %}";
		}
		break;
	      case 3:		// TypeTagFile
		{
		  TypeTagFile* file = tag->tag_file;
		  std::cout << "{% file " << file->str_filename << " %}";
		}
		break;
	      case 4:		// TypeTagEndFile
		{
		  std::cout << "{% endfile %}";
		}
		break;
	      case 5:		// TypeTagFileSnippet
		{
		  TypeTagFileSnippet* file_snippet = tag->tag_file_snippet;
		  std::cout << "{% file snippet " << file_snippet->ident_snippetname << " "
			    << file_snippet->str_snippet_outputfile << " %}";
		}
		break;
	      case 6:		// TypeTagSnippet
		{
		  TypeTagSnippet* snippet = tag->tag_snippet;
		  std::cout << "{% snippet " << snippet->ident_snippetname << " %}";
		}
		break;
	      case 7:		// TypeTagEndSnippet
		{
		  std::cout << "{% endsnippet %}";
		}
		break;
	      case 8:		// TypeTagFileBinary
		{
		  TypeTagFileBinary* file_binary = tag->tag_file_binary;
		  std::cout << "{% file binary " << file_binary->ident_binaryname << " "
			    << file_binary->str_binary_outputfile << " %}";
		}
		break;
	      case 9:		// TypeTagBinary
		{
		  TypeTagBinary* binary = tag->tag_binary;
		  std::cout << "{% binary " << binary->ident_binaryname << " %}\n";
		}
		break;
	      case 10:		// TypeTagEndBinary
		{
		  std::cout << "{% endbinary %}";
		}
		break;
	      }
	  }
	  break;
	}
    }
}




