#ifndef INCLUDED_PARSE_TYPES_H
#define INCLUDED_PARSE_TYPES_H

#ifdef __cplusplus
extern "C" {
#endif

  /*
   * Lexical types for parser
   */


  
  typedef struct {
    int lineno;
    int type;
    /* 1=string_literal, 2=identifier, 3=(object_name,member_name) */

    char* string_literal;
    char* identifier;
    char* object_name; char* member_name;
  } TypeObject;



  typedef struct { int lineno; TypeObject* object; } TypeFilterAppend;
  typedef struct { int lineno; } TypeFilterCapitalize;
  typedef struct { int lineno; } TypeFilterUpcase;
  typedef struct { int lineno; } TypeFilterDowncase;

  typedef struct {
    int lineno;
    int type;
    /* 1 = TypeFilterAppend,
     * 2 = TypeFilterCapitalize
     * 3 = TypeFilterUpcase
     * 4 = TypeFilterDowncase
     */

    union {
      TypeFilterAppend* filter_append;
      TypeFilterCapitalize* filter_capitalize;
      TypeFilterUpcase* filter_upcase;
      TypeFilterDowncase* filter_downcase;
    };
  } TypeFilter;


  
  typedef struct { char* str_projectname; } TypeTagProject;
  typedef struct { } TypeTagEndProject;
  typedef struct { char* str_filename; } TypeTagFile;
  typedef struct { } TypeTagEndFile;
  typedef struct { char* ident_snippetname; char* str_snippet_outputfile; } TypeTagFileSnippet;
  typedef struct { char* ident_binaryname;  char* str_binary_outputfile; } TypeTagFileBinary;
  typedef struct { char* ident_snippetname; } TypeTagSnippet;
  typedef struct { } TypeTagEndSnippet;
  typedef struct { char* ident_binaryname; } TypeTagBinary;
  typedef struct { } TypeTagEndBinary;
  typedef struct { char* ident_modulename; } TypeTagModule;
  typedef struct { } TypeTagEndModule;
  
  typedef struct {
    int lineno;
    int type;
    /* 1=TypeTagProject, 2=TypeTagEndProject,
     * 3=TypeTagFile, 4=TypeTagEndFile,
     * 5=TypeTagFileSnippet,
     * 6=TypeTagSnippet, 7=TypeTagEndSnippet
     * 8=TypeTagFileBinary
     * 9=TypeTagBinary, 10=TypeTagEndBinary
     * 11=TypeTagModule, 12=TypeTagEndModule
     */

    union {
      TypeTagProject* tag_project;
      TypeTagEndProject* tag_endproject;
      TypeTagFile* tag_file;
      TypeTagEndFile* tag_endfile;
      TypeTagFileSnippet* tag_file_snippet;
      TypeTagFileBinary* tag_file_binary;
      TypeTagSnippet* tag_snippet;
      TypeTagEndSnippet* tag_endsnippet;
      TypeTagBinary* tag_binary;
      TypeTagEndBinary* tag_endbinary;
      TypeTagModule* tag_module;
      TypeTagEndModule* tag_endmodule;
    };
  } TypeTag;



  
  /* these low-level structs don't need a 'lineno' */
  
  typedef struct tag_TypeFilterList {
    struct tag_TypeFilterList* next;
    TypeFilter* filter;
  } TypeFilterList;
  
  typedef struct {
    TypeObject* object;
    TypeFilterList* filter_list;
  } TypeObjectExpr;

  typedef struct tag_TypeChars {
    struct tag_TypeChars* next;
    struct tag_TypeChars* head;	/* this is storing two pointers and a char per byte. It's wasteful, but fast. */
    char value;
  } TypeChars;
  
  typedef struct tag_TypeHexCodes {
    struct tag_TypeHexCodes* next;
    struct tag_TypeHexCodes* head; /* same optimization as TypeChars */
    unsigned char value;
  } TypeHexCodes;

  typedef struct tag_TypeRawChars {
    struct tag_TypeRawChars* next;
    struct tag_TypeRawChars* head; /* same optimization as TypeChars */
    char value;
  } TypeRawChars;

  typedef struct {
    int type;
    /* 0=(empty), 1=TypeChars, 2=TypeObjectExpr, 3=TypeTag 4=TypeHexCodes 5=TypeRawChars*/

    union {
      TypeChars* chars;
      TypeObjectExpr* object_expr;
      TypeTag* tag;
      TypeHexCodes* hexcodes;
      TypeRawChars* rawchars;
    };
  } TypeInputT;

  typedef struct tag_TypeInput {
    struct tag_TypeInput* next;
    TypeInputT* data;
  } TypeInput;




  

  /* header parse types */
  typedef struct {
    char* ident;
    TypeChars* value;
  } TypeHVal;

  typedef struct tag_TypeHeader {
    struct tag_TypeHeader* next;
    TypeHVal* hval;
  } TypeHeader;





  /*
   * functions
   */


  /* suppress some warnings */
  int yylex();
  int yyerror(char*);

  /* parse string into parse tree (the big function) */
  void* parse_string(const char*, void** header);

  void free_resultptr(void* p); /* free the parse tree */
  void free_headerptr(void* p);
  


#ifdef __cplusplus
}
#endif

#endif /* INCLUDED_PARSE_TYPES_H */



