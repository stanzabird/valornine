#include "generator.h"

#include <iostream>
#include <fstream>
#include <iomanip>
#include <iterator>
#include <string>
#include <cstdlib>
#include <cctype>

#include <getopt.h>
#include <config.h>

#include "parser.types.h"

//
// program version and commandline usage
//

static void
version(const char* progname)
{
  std::cout <<
    PACKAGE_NAME " version " PACKAGE_VERSION "\n"
    "Compilation timestamp: " __DATE__ " " __TIME__ "\n\n"
    "Copyright (C) 2017 Opal Raava <opalraava@riseup.net>. GPL3 Licence.\n"
    "For more information on this package, \n"
    "visit: " PACKAGE_URL "\n"
    "\n"
    ;
}


static void
usage(const char* progname, std::string template_filename)
{
  std::cout <<
    "Usage: vn [--version] [--help] [--var <name>:<value>]\n"
    "          [--template <path>] <command> [<args>]\n\n"
    ;

  std::cout <<
    "  -t,--template <file>  Use this template instead of the default\n"
    "  -v,--var <name:value> Assign a value to a variable\n"
    "  -g,--git              Create git repo and perform initial checkin\n"
    "  -m,--module <name>    Generate code defined by module <name>\n"
    "\n"
    "  -V,--version          Display program version\n"
    "  -h,--help             Display this commandline help\n"
    "  -d,--debug            Show debugging messages\n"
    "  -D,--parser-debug     Show parser debugging messages\n"
    "\n"
    ;
  std::cout <<
    "These are the ValorNine commands used:\n"
    "\n"
    "   list      List the projects available in the template file.\n"
    "   generate  Generate a new project.\n"
    "             - example: \n"
    "                 vn generate yasm-basic bar\n"
    "             This wil generate a folder `bar' filled with the\n"
    "             project `yasm-basic'.\n"
    "   modules   List all projects, including the modules they define.\n"
    "\n"
    "   binary    Print out the hexdump of the file arguments to stdout. Use\n"
    "             this if you want to include binary files in the template.\n"
    "   test      Just parse the template file. Used to test speed.\n"
    "             Returns parse success as 0 to OS, nonzero on error.\n"
    "   vars      Print the variables defined in the template.\n"
    "   print     A debug command to print the parse tree to stdout.\n"
    "   help      Print this help message.\n"
    "   version   Print version info.\n"
    "\n"
    ;
  std::cout <<
    "Using template file: " << template_filename << "\n"
    "\n"
    ;
}

//
// program entry point
//

std::string get_template_filename(std::string opt_template)
{
  std::string folder ="./";
  
  if (getenv("HOME") != nullptr)
    folder = std::string(getenv("HOME")) + "/";
  
  std::string ifs_name = folder + ".default.vn";
  
  if (getenv("VN_DATAFILE") != nullptr) {
    ifs_name = getenv("VN_DATAFILE");
  }
  
  if (opt_template != "")
    ifs_name = opt_template;
  
  return ifs_name;
}

extern "C" { int opt_debug = 0; int opt_parser_debug = 0; }

int
main(int argc,char* argv[])
{
  std::map<std::string,std::string> parameters;
  std::vector<std::string> modules;
  std::string opt_template;
  bool opt_git_init = false;
  
  int c;
  int digit_optind = 0;

  while (1) 
    {
      int this_option_optind = optind ? optind : 1;
      int option_index = 0;

      static struct option long_options[] = {
        {"parser-debug", no_argument,       0,  'D' },
        {"debug",        no_argument,       0,  'd' },
        {"version",      no_argument,       0,  'V' },
        {"help",         no_argument,       0,  'h' },
        {"git",          no_argument,       0,  'g' },
        {"module",       required_argument, 0,  'm' },
        {"template",     required_argument, 0,  't' },
	{"var",          required_argument, 0,  'v' },
        {0,          0,                 0,  0 }
      };

      c = getopt_long(argc, argv, "DdgVht:v:m:",
                      long_options, &option_index);
      if (c == -1)
        break;

      switch (c) 
        {
	case 'D':
	  opt_parser_debug = 1;
	  break;
	case 'd':
	  opt_debug = 1;
	  break;
	case 'g':
	  opt_git_init = true;
	  break;
        case 'V':
          version(argv[0]);
          return 0;
        case 'h':
	  valornine::datafile_name = get_template_filename(opt_template);
          usage(argv[0],get_template_filename(opt_template));
          return 0;
        case 't':
	  opt_template = optarg;
          break;

        case 'm':
	  {
	    modules.push_back(std::string(optarg));
	  }
          break;

	case 'v':		// --var pi:3.1415
	  {
	    std::string s = optarg;
	    std::size_t pos = s.find_first_of(':');
	    
	    if (pos == std::string::npos) {
	      std::cout << argv[0] << ": commandline error, the --var command expects the "
		"\nvariable name be seperated from its value by a colon (like so-v pi:3.1415)\n";
	      return 1;
	    }
	    
	    std::string var, val;
	    var = s.substr(0,pos);
	    val = s.substr(pos+1);

	    if (var.size() == 0) {
	      std::cout << argv[0] << ": commandline error, the name of the "
		"variable cannot be empty (--var " << s << ")\n";
	      return 1;
	    }

	    parameters.insert(std::make_pair(var,val));
	  }
	  break;
        default:
	  std::cout << argv[0] << ": getopt() returned unknown value\n";
	  return 1;
        }
    }                                 
                                                                     
  valornine::datafile_name = get_template_filename(opt_template);
  
  if (optind < argc) {

    // part 1: parse the template tree
    
    auto init_data = [opt_template]() {
      std::string template_contents;
      
      // todo : fill the template_contents string using the
      // specified template filename.

      if (opt_debug) std::cout << "[debug] Using template: `" << valornine::datafile_name << std::endl;
    
      std::ifstream ifs(valornine::datafile_name);

      if (!ifs) {
	std::cout << valornine::datafile_name << ": error: cannot open file for reading\n";
	exit(1);
      }

      
      template_contents = std::string( std::istreambuf_iterator<char>(ifs), std::istreambuf_iterator<char>() );
      
      // parse the template and return it's data
      valornine::TemplateData retval = valornine::parse(template_contents);
      
      return retval;
    };
    
    //
    // part 2: execute commandline commands

    if (std::string("list") == argv[optind])
      {
	if (optind + 1 != argc) {
	  std::cout << "valornine: error: junk parameters after `list' command\n";
	  return 1;
	}
	
	valornine::TemplateData data = init_data();
	if (data.error())
	  return 1;
	
	data.list();
      }
    else if (std::string("version") == argv[optind])
      {
	version(argv[0]);
      }
    else if (std::string("print") == argv[optind])
      {
	if (optind + 1 != argc) {
	  std::cout << "valornine: error: junk parameters after `print' command\n";
	  return 1;
	}
	
	valornine::TemplateData data = init_data();
	if (data.error())
	  return 1;
	
	data.print();
      }
    else if (std::string("modules") == argv[optind] || std::string("lsmod") == argv[optind] )
      {
	if (optind + 1 != argc) {
	  std::cout << "valornine: error: junk parameters after `modules' command\n";
	  return 1;
	}
	
	valornine::TemplateData data = init_data();
	if (data.error())
	  return 1;
	
	data.lsmod();
      }
    else if (std::string("binary") == argv[optind])
      {
	if (++optind < argc)
	  {
	    for (int i = optind; i < argc; i++)
	      {
		std::ifstream file(argv[i], std::ios::binary | std::ios::ate);
		std::streamsize size = file.tellg();
		file.seekg(0, std::ios::beg);
		std::vector<char> buffer(size);

		if (!file.read(buffer.data(),size))
		  {
		    std::cout << argv[i] << ": unable to read file\n";
		    return 1;
		  }
		  

		if (opt_debug)
		  std::cout << "[debug] buffer size = " << buffer.size() << std::endl;

		// print them bytes
		int pos = 0;
		for (char c : buffer)
		  {
		    int tmp = (unsigned char)c;

		    if (pos > 0)
		      std::cout << ' ';
		    
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
	      }
	  }
	else
	  {
	    std::cout << "valornine: printing binaries: please specify one or more files to print\n";
	    return 1;
	  }
      }
    else if (std::string("vars") == argv[optind])
      {
	valornine::TemplateData data = init_data();
	if (data.error()) {
	  return 1;
	}
	
	auto header = static_cast<TypeHeader*>(data.parse_header);

	for (auto p = header; p; p = p->next)
	  {
	    std::cout << p->hval->ident << ": ";

	    
	    auto q = p->hval->value;
	    while (std::isspace(q->value))
	      {
		q = q->next;
	      }
	    
	    for (; q; q = q->next)
	      {
		std::cout << q->value;
	      }
	    
	    std::cout << '\n';
	      
	  }
	
      }
    else if (std::string("test") == argv[optind])
      {
	valornine::TemplateData data = init_data();
	if (data.error()) {
	  return 1;
	}
      }
    else if (std::string("help") == argv[optind])
      {
	usage(argv[0],valornine::datafile_name);
	return 0;
      }
    else if (std::string("generate") == argv[optind])
      {
	if (++optind < argc)
	  {
	    char* opt_project_type = argv[optind];
		
	    if (++optind < argc)
	      {
		valornine::TemplateData data = init_data();
		if (data.error())
		  return 1;
	
		for (int i = optind; i < argc; i++)
		  {
		    data.render_project(std::string(argv[i]), std::string(opt_project_type), parameters, modules);

		    // optionally initialize a git repo for the project...
		    if (opt_git_init == true)
		      {
			std::string s;

			s = std::string("cd ") + argv[i] + "; git init";
			std::cout << s << std::endl;
			std::system(s.c_str());

			s = std::string("cd ") + argv[i] + "; git add *";
			std::cout << s << std::endl;
			std::system(s.c_str());
			
			s = std::string("cd ") + argv[i] + "; git commit -am 'Initial commit'";
			std::cout << s << std::endl;
			std::system(s.c_str());
		      }
		  }
	      }
	    else
	      {
		std::cout << "valornine: generate error: please specify one or more target folders\n";
		return 1;
	      }
	  }
	else
	  {
	    std::cout << "valornine: generate error: please specify a project type\n";
	    return 1;
	  }
      }
    else
      {
	std::cout << "valornine: error: invalid command. Perhaps a typo? Use 'vn help' for help.\n";
	return 1;
      }
  }
  else
    usage(argv[0],valornine::datafile_name);
                                                                                                   
  return 0;
}


