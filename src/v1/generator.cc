#include "symtab.h"
#include "generator.h"
#include "trim.h"

#include <iostream>
#include <algorithm>
#include <fstream>
#include <iterator>
#include <cstring> 		// for strdup()
#include <ctime>

#include <sys/stat.h>		// for mkdir()


// the namespace sprot functionality is merely calling these functions
// that actually inteprete the parse tree.
void parse_tree_print(TypeInput* parse_tree, TypeHeader* parse_header);
void parse_tree_list(TypeInput* parse_tree, TypeHeader* parse_header);
void parse_tree_project(TypeInput* parse_tree, TypeHeader* parse_header,
			std::string project_name, std::string project_type,
			std::map<std::string,std::string> parameters,
			std::vector<std::string> modules);

void parse_tree_lsmod(TypeInput* parse_tree);


// helper functions to convert parse data in decent strings
std::string chars2str(TypeChars* chars);
std::string sanitize_string_literal(char* str);

char* yyfilename = NULL;	// for displaying error messages in parse.y


namespace valornine
{
  std::string datafile_name;	// set in main()
  
  TemplateData::TemplateData(void* p, void* q) : parse_tree(p), parse_header(q) {}

  TemplateData parse(std::string input)
  {
    yyfilename = strdup(datafile_name.c_str()); // for syntax errors
    
    void* q = NULL;
    void* p = parse_string(input.c_str(), &q);

    free(yyfilename); yyfilename = NULL; // clean it up
    
    return TemplateData(p,q);
  }
  
  void TemplateData::render_project(std::string project_name, std::string project_type,
				    std::map<std::string,std::string> parameters, 
                                    std::vector<std::string> modules)
  {
    TypeInput* root = static_cast<TypeInput*>(parse_tree);
    TypeHeader* header = static_cast<TypeHeader*>(parse_header);
    
    parse_tree_project(root, header, project_name, project_type, parameters,modules);
  }
  
  void TemplateData::list()
  {
    TypeInput* root = static_cast<TypeInput*>(parse_tree);
    TypeHeader* header = static_cast<TypeHeader*>(parse_header);
    
    parse_tree_list(root,header);
  }
  
  void TemplateData::print()
  {
    TypeInput* root = static_cast<TypeInput*>(parse_tree);
    TypeHeader* header = static_cast<TypeHeader*>(parse_header);
    
    parse_tree_print(root,header);
  }

  void TemplateData::lsmod()
  {
    TypeInput* root = static_cast<TypeInput*>(parse_tree);
    
    parse_tree_lsmod(root);
  }
}




/*
 * utilities
 */




std::string sanitize_string_literal(char* str)
{
  std::string retval;

  for (char* s = str; *s; s++)
    {
      if (s != str)
	{
	  if (s[1] != '\0')
	    {
	      retval += *s;
	    }
	}
    }

  return retval;
}

std::string chars2str(TypeChars* chars)
{
  std::string s;

  while (chars)
    {
      s += chars->value;
      chars = chars->next;
    }
  
  return s;
}


std::vector<unsigned char> hexcodes2buffer(TypeHexCodes* hexcodes)
{
	std::vector<unsigned char> retval;

	while (hexcodes)
	{
		retval.push_back(hexcodes->value);
		hexcodes = hexcodes->next;
	}

	return retval;
}




// --------------------------------------------------------------------------------------




/*
 * parse_tree_list(): List the available projects (commandline ==> sprot list)
 */


void parse_tree_list(TypeInput* parse_tree, TypeHeader* parse_header)
{
  std::vector<std::string> items;
  
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
		  TypeTagProject* project = tag->tag_project;
		  items.push_back(sanitize_string_literal(project->str_projectname));
		}
		break;
	      }
	  }
	  break;
	}
    }

  std::sort(items.begin(),items.end());
  for (std::string s : items)
    std::cout << s << std::endl;
}






// --------------------------------------------------------------------------------------




/*
 * parse_tree_project(): Generate the project (commandline ==> sprot project <projtype> <dirname>)
 */





struct ProjectAction
{
  struct FileContent {
    std::string filename;
    TypeInput* content_begin;
    TypeInput* content_end;
  };

  struct FileSnippet {
    std::string ident, filename;
    int lineno;
  };

  struct SnippetContent {
    std::string ident;
    TypeInput* content_begin;
    TypeInput* content_end;
  };
  
  struct FileBinary {
    std::string ident, filename;
    int lineno;
  };

  struct BinaryContent {
    std::string ident;
    TypeInput* content_begin;
    TypeInput* content_end;
  };
  
  std::vector<FileContent> files;
  
  std::vector<FileSnippet> file_snippets;
  std::vector<SnippetContent> snippets;
  
  std::vector<FileBinary> file_binaries;
  std::vector<BinaryContent> binaries;
  
  std::map<std::string,std::string> program_parameters, header_parameters;
  std::vector<std::string> modules;

  std::string project_name;	// dirname of the project to generate

  void pass2() {
    for (auto fc : files)
      generate_file(fc);
    for (auto fs : file_snippets)
      generate_file_from_snippet(fs);
    for (auto fb : file_binaries)
      generate_file_from_binary(fb);
  }
  
  void generate_file(FileContent& fc);
  void generate_file_from_snippet(FileSnippet& fs);
  void generate_file_from_binary(FileBinary& fb);

  void generate_from_input (std::string fname, TypeInput* content_begin, TypeInput* content_end);
};





void parse_tree_project(TypeInput* parse_tree, TypeHeader* parse_header,
			std::string project_name, std::string project_type,
			std::map<std::string,std::string> parameters,
                        std::vector<std::string> modules)
{
  
  ProjectAction action;

  /* parse_tree_project() is the first pass. It fills the ProjectAction type
   * with the relevant parts of parse_tree and parse_header. Then it passes
   * control to a ProjectAction member function to do the actual work of 
   * interpreting tags and objects. I'm not happy with this construct, and
   * can imagine having a better parser.y that enforces the syntax better. 
   * 
   * In short, it fills the ProjectAction class with data such as chunks of
   * the parse tree into snippets and files, and other data */
  
  action.project_name = project_name;
  action.program_parameters = parameters;
  action.modules = modules;
  
  bool in_project = false, in_snippet = false, in_file = false, in_binary = false, in_module = false;
  bool found_project = false, active_project = false; // true if we found the project we're looking for
  bool module_discard_flag = false;
  
  ProjectAction::FileContent fc;
  ProjectAction::SnippetContent sc;
  ProjectAction::BinaryContent bc;
  std::string module;

  auto tag_error = [](int lineno, const std::string& msg) {
    std::cout << valornine::datafile_name << ":" << lineno << ": error: " << msg << std::endl;
    exit(1);
  };
  
  /* header parsing */
  if (parse_header)
    {
      for (TypeHeader* p = parse_header; p; p = p->next)
	{
	  TypeHVal* hval = p->hval;
	  
	  action.header_parameters[hval->ident] = chars2str(hval->value);
	  trim(action.header_parameters[hval->ident]);
	}
    }

  /* body parsing */
  for (TypeInput* p = parse_tree; p; p = p->next)
    {
      switch (p->data->type)
	{
	case 0:			// (empty)
	  break;
	  
	case 1:			// TypeChars
	  break;

	case 4:			// TypeHexCodes
	  break;
	  
	case 2:			// TypeObjectExpr
	  break;
	  
	case 3:			// TypeTag
	  {
	    TypeTag* tag = p->data->tag;

	    switch (tag->type)
	      {
	      case 1:		// TypeTagProject
		{
		  TypeTagProject* project = tag->tag_project;
		  std::string s = sanitize_string_literal(project->str_projectname);

		  if (in_project) { tag_error(tag->lineno,"new {%project%} tag found but old project not ended with {%endproject%} yet"); }
		  
		  in_project = true;
		  if (s == project_type) {
		    found_project = true;
		    active_project = true;
		  }
		}
		break;
	      case 2:		// TypeTagEndProject
		{
		  TypeTagEndProject* endproject = tag->tag_endproject;
		  if (!in_project) { tag_error(tag->lineno,"tag {%endproject%} found but there is no preceding {%project%} tag"); }
		  
		  in_project = false;
		  active_project = false;
		}
		break;


		
	      case 3:		// TypeTagFile
		{
		  TypeTagFile* file = tag->tag_file;
		  if (!in_project) { tag_error(tag->lineno,"tag {%file%} only valid inside a project"); }
		  if (in_file) { tag_error(tag->lineno,"tag {%file%} not valid here, we're already inside a {%file%} segment"); }
		  if (in_snippet) { tag_error(tag->lineno, "tag {%file%} not valid here, we're inside a {%snippet%} segment"); }
		  if (in_binary) { tag_error(tag->lineno, "tag {%file%} not valid here, we're inside a {%binary%} segment"); }

		  in_file = true;
		  
		  // this file not expanded cuz not in the right module
		  if (module_discard_flag) break;
		  
		  if (active_project) {
		    fc.filename = sanitize_string_literal(file->str_filename);
		    fc.content_begin = p;
		  }
		}
		break;
		
	      case 4:		// TypeTagEndFile
		{
		  TypeTagEndFile* endfile = tag->tag_endfile;
		  if (!in_project) { tag_error(tag->lineno,"tag {%endfile%} only valid inside {%project%} segment"); }
		  if (!in_file) { tag_error(tag->lineno,"tag {%endfile%} found, but no matching {%file%} tag precedes it"); }
		  if (in_snippet) { tag_error(tag->lineno,"tag {%endfile%} not allowed inside a {%snippet%} segment"); }
		  if (in_binary) { tag_error(tag->lineno,"tag {%endfile%} not allowed inside a {%binary%} segment"); }

		  in_file = false;
		  
		  // this file not expanded cuz not in the right module
		  if (module_discard_flag) break;
		  
		  if (active_project) {
		    fc.content_end = p;
		    action.files.push_back(fc);
		  }
		}
		break;

		
		
	      case 5:		// TypeTagFileSnippet
		{
		  TypeTagFileSnippet* file_snippet = tag->tag_file_snippet;
		  
		  if (!in_project) { tag_error(tag->lineno,"this tag is only valid inside a {%project%} segment"); }
		  if (in_file) { tag_error(tag->lineno,"this tag is not valid inside a {%file%} segment"); }
		  if (in_snippet) { tag_error(tag->lineno,"this tag is not valid iside a {%snippet%} segment"); }
		  if (in_binary) { tag_error(tag->lineno,"this tag is not valid iside a {%binary%} segment"); }
		  
		  // this file not expanded cuz not in the right module
		  if (module_discard_flag) break;
		  
		  if (active_project) {
		    ProjectAction::FileSnippet tmp;
		    tmp.lineno = tag->lineno;
		    tmp.ident = file_snippet->ident_snippetname;
		    tmp.filename = sanitize_string_literal(file_snippet->str_snippet_outputfile);
		    action.file_snippets.push_back(tmp);
		  }
		}
		break;
	      case 6:		// TypeTagSnippet
		{
		  TypeTagSnippet* snippet = tag->tag_snippet;
		  if (in_project) { tag_error(tag->lineno, "snippets are global only, can't have them in a {%project%} segment"); }
		  if (in_snippet) { tag_error(tag->lineno, "we're already defining a {%snippet%} and snippet tags don't nest"); }
		  if (in_binary) { tag_error(tag->lineno, "we're defining a {%binary%} and snippet tags are not allowed"); }
		  
		  std::string s = snippet->ident_snippetname;
		  sc.ident = s;
		  sc.content_begin = p;
		  in_snippet=true;
		}
		break;
	      case 7:		// TypeTagEndSnippet
		{
		  TypeTagEndSnippet* endsnippet = tag->tag_endsnippet;
		  if (in_project) { tag_error(tag->lineno, "the {%endsnippet%} tag is not valid inside {%project%} segments"); }
		  if (!in_snippet) { tag_error(tag->lineno, "no matching {% snippet %} begin tag found"); }
		  if (in_binary) { tag_error(tag->lineno, "no matching {% binary %} begin tag found"); }
		  
		  in_snippet = false;
		  sc.content_end = p;
		  action.snippets.push_back(sc);
		}
		break;

	      case 8:		// TypeTagFileBinary
		{
		  TypeTagFileBinary* file_binary = tag->tag_file_binary;
		  
		  if (!in_project) { tag_error(tag->lineno,"this tag is only valid inside a {%project%} segment"); }
		  if (in_file) { tag_error(tag->lineno,"this tag is not valid inside a {%file%} segment"); }
		  if (in_snippet) { tag_error(tag->lineno,"this tag is not valid iside a {%snippet%} segment"); }
		  if (in_binary) { tag_error(tag->lineno,"this tag is not valid iside a {%binary%} segment"); }
		  
		  // this file not expanded cuz not in the right module
		  if (module_discard_flag) break;
		  
		  if (active_project) {
		    ProjectAction::FileBinary tmp;
		    tmp.lineno = tag->lineno;
		    tmp.ident = file_binary->ident_binaryname;
		    tmp.filename = sanitize_string_literal(file_binary->str_binary_outputfile);
		    action.file_binaries.push_back(tmp);
		  }
		}
		break;
	      case 9:		// TypeTagBinary
		{
		  TypeTagBinary* binary = tag->tag_binary;
		  if (in_project) { tag_error(tag->lineno, " {% binary %} is global only, can't have them in a {%project%} segment"); }
		  if (in_snippet) { tag_error(tag->lineno, "we're already defining a {%snippet%} and can't start a binary. use {% endsnippet %}"); }
		  if (in_binary) { tag_error(tag->lineno, "we're defining a {%binary%} and binary tags don't nest"); }
		  
		  std::string s = binary->ident_binaryname;
		  bc.ident = s;
		  bc.content_begin = p;
		  in_binary=true;
		}
		break;
	      case 10:		// TypeTagEndBinary
		{
		  TypeTagEndBinary* endbinary = tag->tag_endbinary;
		  
		  if (in_project) { tag_error(tag->lineno, "the {%endbinary%} tag is not valid inside {%project%} segments"); }
		  if (in_snippet) { tag_error(tag->lineno, "We're inside a {% snippet %} segment"); }
		  if (!in_binary) { tag_error(tag->lineno, "no matching {% binary %} begin tag found"); }
		  
		  in_binary = false;
		  bc.content_end = p;
		  action.binaries.push_back(bc);
		}
		break;



		
              case 11:		// TypeTagModule
                {
		  TypeTagModule* m = tag->tag_module;
		  module = m->ident_modulename;

		  if (in_module) { tag_error(tag->lineno, "The {% module %} tag does not nest (yet)"); }

		  if (in_snippet || in_file)
		    {
		      // this is to be expanded in the second pass
		    }
		  else if (in_project)
		    {
		      // this is the case when it's global and selects what files to expand
		      // find if this module is in the list
		      auto in_list = false;
		      for (auto s : modules)
			{
			  if (s == module) in_list = true;
			}
		      if (in_list)
			module_discard_flag = false;
		      else
			module_discard_flag = true;
		    }
		  
		  in_module = true;
                }
                break;
		
              case 12:		// TypeTagEndModule
                {
		  TypeTagEndModule* endmodule = tag->tag_endmodule;

		  if (!in_module) break;

		  if (in_snippet || in_file)
		    {
		      // this is to be expanded in the second pass
		    }
		  else if (in_project)
		    {
		      // this is the case when it's global and selects what files to expand
		    }
		  
		  in_module = false;
		  module_discard_flag = false;
                }
                break;

		
	      }
	  }
	  break;
	}
    }

  if (!found_project) { std::cout << valornine::datafile_name << ": error: requested project type `" << project_type << "' not found\n"; exit(1); }
  if (in_file)        { std::cout << valornine::datafile_name << ": error: expected {%endfile%} but found EOF\n"; exit(1); }
  if (in_project)     { std::cout << valornine::datafile_name << ": error: expected {%endproject%} but found EOF\n"; exit(1); }
  if (in_snippet)     { std::cout << valornine::datafile_name << ": error: expected {%endsnippet%} but found EOF\n"; exit(1); }
  if (in_binary)      { std::cout << valornine::datafile_name << ": error: expected {%endbinary%} but found EOF\n"; exit(1); }

  // now we have all the data needed to actually generate the project inside our 'action' object.
  action.pass2();
}








void ProjectAction::generate_file(FileContent& fc)
{
  std::string fname = project_name + "/" + fc.filename;
  std::replace(begin(fname),end(fname),'\\','/');

  TypeInput* content_begin = fc.content_begin;
  TypeInput* content_end = fc.content_end;

  
  /* we now have a filename, and content_begin and content_end */
  generate_from_input(fname,content_begin, content_end);
}




void ProjectAction::generate_file_from_snippet(FileSnippet& fs)
{
  std::string fname = project_name + "/" + fs.filename;
  std::replace(begin(fname),end(fname),'\\','/');

  // find the parse string of the specified snippet
  SnippetContent sc;
  for (auto s : snippets) {
    if (s.ident == fs.ident) { sc = s; break; }
  }
  if (sc.ident != fs.ident) {
    std::cout << valornine::datafile_name << ":" << fs.lineno
	      << ": error: did not find the matching snippet `"<<fs.ident<<"'\n";
    exit(1);
  }
  
  TypeInput* content_begin = sc.content_begin;
  TypeInput* content_end = sc.content_end;

  
  /* we now have a filename, and content_begin and content_end */
  generate_from_input(fname,content_begin, content_end);
}



void make_dirs(std::string path);

void ProjectAction::generate_file_from_binary(FileBinary& fb)
{
  std::string fname = project_name + "/" + fb.filename;
  std::replace(begin(fname),end(fname),'\\','/');

  // quirk. we allow for ${pn} in the filename to be replaced
  // with the name of the project (so we can have src/${pn}.c be src/foo.c
  auto index = fname.find("${pn}");
  if (index != std::string::npos)
    {
      fname.replace(index,5,project_name);
    }

  // now we have the final filename, print it.
  std::cout << fname << std::endl;
  
  // find the parse string of the specified snippet
  BinaryContent bc;
  for (auto s : binaries) {
    if (s.ident == fb.ident) { bc = s; break; }
  }
  if (bc.ident != fb.ident) {
    std::cout << valornine::datafile_name << ":" << fb.lineno
	      << ": error: did not find the matching binary `"<<fb.ident<<"'\n";
    exit(1);
  }
  
  TypeInput* content_begin = bc.content_begin;
  TypeInput* content_end = bc.content_end;

  /* we now have a filename, and content_begin and content_end */
  for (TypeInput* token = content_begin; token != content_end; token = token->next)
    switch (token->data->type)
      {
      case 4:			// TypeHexCodes
	{
	  TypeHexCodes* hexcodes = token->data->hexcodes;
	  std::vector<unsigned char> buffer = hexcodes2buffer(hexcodes);

	  make_dirs(fname);
	  
	  {
	    std::ofstream ofs(fname, std::ios::binary | std::ios::out);

	    if (!ofs) {
	      std::cout << fname << ": unable to open file for writing\n";
	      return;
	    }

	    std::ostream_iterator<unsigned char> iter(ofs);
	    std::copy(begin(buffer),end(buffer), iter);
	    ofs.close();
	  }
	}
	break;
      }
}





// --------------------------------------------------------------------------------



void expand_template(std::ofstream& ofs, SymTab& symtab, TypeInput* content_begin, TypeInput* content_end, std::vector<std::string> modules);
void fileparse(std::string path, std::string& dir, std::string& name, std::string& ext);
void make_dirs(std::string path);


void ProjectAction::generate_from_input(std::string fname, TypeInput* content_begin, TypeInput* content_end)
{
  SymTab symtab;

  // quirk. we allow for ${pn} in the filename to be replaced
  // with the name of the project (so we can have src/${pn}.c be src/foo.c
  auto index = fname.find("${pn}");
  if (index != std::string::npos)
    {
      fname.replace(index,5,project_name);
    }

  // now we have the final filename, print it.
  std::cout << fname << std::endl;
  
  // The variables we have available from the object:
  //
  // std::map<std::string,std::string> program_parameters, header_parameters;
  for (auto i : header_parameters) {
    symtab.add(i.first,SymTab::string2direct_value(i.second));
  }
  for (auto i : program_parameters) {
    symtab.add(i.first,SymTab::string2direct_value(i.second));
  }

  // std::string project_name;               // (dir)name of the project to generate
  //    this will become {{ project.name }}...
  symtab.add("project_name", SymTab::string2direct_value(project_name));
  
  // We also have the full filename of the target file where we can extract:
  //   {{ name }} {{ ext }}
  std::string dir, name, ext;
  fileparse(fname, dir,name,ext);
  symtab.add("name",name);
  symtab.add("ext",ext);
  
  // We also want to automatically have a correct {{ year }} variable.
  time_t theTime = time(NULL);
  struct tm* aTime = localtime(&theTime);
  int year = aTime->tm_year + 1900;
  symtab.add("year", year);
  
  //
  // Create file with full directories and open it for writing
  make_dirs(fname);

  std::ofstream ofs(fname);

  if (!ofs) {
    std::cout << fname << ": unable to open file for writing\n";
    return;
  }

  //
  // The task is now to interprete the Parse tree once more, but now we assume full
  // liquid syntax possible. Take inspiration from _print().
  //
  
  expand_template(ofs,symtab,content_begin,content_end,modules);
}
