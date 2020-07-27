basic_file_syntax = [ws] ("{%" [ws] statement [ws] "%}")* [ws] [eof];

statement =
  paired_statement
  | single_statement;

single_statement =
  "file" "wget" string string
  | "file" "snippet" identifier string
  | "file" "binary" identifier string
  | "instance" identifier string
  ;

paired_statement =
  "file" string file_content "endfile"
  | "project" string project_content "endproject"
  | "template" string ("extends" string)* template_content "endtemplate"
  | "comment" comment_content "endcomment"
  | "json" identifier json_content "endjson"
  | "exec" exec_content "endexec"
  | "multiline" identifier multiline_content "endmultiline"
  | "module" identifier module_content "endmodule"
  | "instance" "multiline" identifier instance_multiline_content "endmultiline"
  ;









string = expand_variables(literal_source_string);
identifier = "C" style identifier. no dots.
  variables = "self".*; json_identifier.*; "std".* (std.year);
