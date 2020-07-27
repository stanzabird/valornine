basic_file_syntax = [ws] ("{%" [ws] statement [ws] "%}")* [ws] [eof];

statement =
  paired_statement
  | single_statement;

single_statement =
  "file" "wget" string string
  |  "file" "snippet" identifier string
  |  "file" "binary" identifier string
  |  "string" identifier string # self.indentifier = string
  ;

paired_statement =
   "file" string file_content "endfile"
  | "project" string ("extends" string)* project_content "endproject"
  | "template" string ("extends" string)* template_content "endtemplate"
  | "comment" comment_content "endcomment"
  | "json" identifier json_content "endjson"
  | "exec" exec_content "endexec"
  | "multiline" identifier multiline_content "endmultiline"
  | "module" identifier module_content "endmodule"
  | "multiline" identifier string_multiline_content "endmultiline" # self.indentifier = string_multiline_content
  | "snippet" identifier snippet_content "endsnippet"
  | "binary" identifier binary_content "endbinary"
  ;


string = expand_variables(literal_source_string);
identifier = "C" style identifier. no dots.
variables = "self".*; json_identifier.*; "std".* (std.year);

hardcoded: self.program_name
hardcoded: std.year
