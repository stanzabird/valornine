#include "symtab.h"




void SymTab::parse_name(std::string name, std::string& varname, std::string& membername)
{
  // look for '.' in name
  auto pos = name.find('.');
  
  if (pos != std::string::npos) {
    varname = name.substr(0,pos);
    membername = name.substr(pos+1);
  }
  else
    varname = name;
}

void SymTab::add(std::string name, std::string value) {
  std::string varname, membername;
  parse_name(name,varname,membername);
  
  DirectValue v;
  v.type = tString;
  v.str = value;
  if (membername.empty())
    direct_symbols[varname] = v;
  else {
    ObjectValue o;
    o.direct_members[membername] = v;
    object_symbols[varname] = o;
  } 
}
void SymTab::add(std::string name, int value)
{
  std::string varname, membername;
  parse_name(name,varname,membername);
  
  DirectValue v;
  v.type = tNumber;
  v.num = value;
  if (membername.empty())
    direct_symbols[varname] = v;
  else {
    ObjectValue o;
    o.direct_members[membername] = v;
    object_symbols[varname] = o;
  } 
}
void SymTab::add(std::string name, float value)
{
  std::string varname, membername;
  parse_name(name,varname,membername);
  
  DirectValue v;
  v.type = tNumber;
  v.num = value;
  if (membername.empty())
    direct_symbols[varname] = v;
  else {
    ObjectValue o;
    o.direct_members[membername] = v;
    object_symbols[varname] = o;
  } 
}
void SymTab::add(std::string name, bool value)
{
  std::string varname, membername;
  parse_name(name,varname,membername);
  
  DirectValue v;
  v.type = tBoolean;
  v.b = value;
  if (membername.empty())
    direct_symbols[varname] = v;
  else {
    ObjectValue o;
    o.direct_members[membername] = v;
    object_symbols[varname] = o;
  } 
}
void SymTab::add(std::string name, DirectValue value)
{
  std::string varname, membername;
  parse_name(name,varname,membername);
  
  if (membername.empty())
    direct_symbols[varname] = value;
  else {
    ObjectValue o;
    o.direct_members[membername] = value;
    object_symbols[varname] = o;
  } 
}

bool SymTab::is_defined(std::string name)
{
  std::string varname, membername;
  parse_name(name,varname,membername);
  
  if (membername.empty()) {
    if (direct_symbols.find(varname) != direct_symbols.end())
      return true;
    else if (array_symbols.find(varname) != array_symbols.end())
      return true;
  }
  else {
    if (object_symbols.find(varname) != object_symbols.end()) {
	if (object_symbols[varname].direct_members.find(membername) != object_symbols[varname].direct_members.end())
	  return true;
	else if (object_symbols[varname].array_members.find(membername) != object_symbols[varname].array_members.end())
	  return true;
    }
  }
  
  return false;
}
bool SymTab::is_array(std::string name)
{
  std::string varname, membername;
  parse_name(name,varname,membername);
  
  if (membername.empty()) {
    if (direct_symbols.find(varname) != direct_symbols.end())
      return false;
    else if (array_symbols.find(varname) != array_symbols.end())
      return true;
  }
  else {
    if (object_symbols.find(varname) != object_symbols.end()) {
	if (object_symbols[varname].direct_members.find(membername) != object_symbols[varname].direct_members.end())
	  return false;
	else if (object_symbols[varname].array_members.find(membername) != object_symbols[varname].array_members.end())
	  return true;
    }
  }
  
  return false;
}
std::vector<SymTab::DirectValue> SymTab::get_array_value(std::string name)
{
  std::string varname, membername;
  parse_name(name,varname,membername);
  
  if (membername.empty())
    return array_symbols[varname].values;
  else
    return object_symbols[varname].array_members[membername].values;
  
  return std::vector<SymTab::DirectValue>();
}
SymTab::DirectValue SymTab::get_direct_value(std::string name)
{
  std::string varname, membername;
  parse_name(name,varname,membername);
  
  if (membername.empty())
    return direct_symbols[varname];
  else
    return object_symbols[varname].direct_members[membername];
  
  DirectValue v;
  v.type = tNil;
  return v;
}






SymTab::DirectValue SymTab::string2direct_value(std::string value)
{
  SymTab::DirectValue retval;
  
  if (value == "true" || value == "false") {
    retval.type = SymTab::tBoolean;
    if (value == "true")
      retval.b = true;
    else
      retval.b = false;

    return retval;
  }

  float f;
  
  try {
    f = std::stof(value);
    retval.type = SymTab::tNumber;
    retval.num = f;
    return retval;
  } catch (std::invalid_argument ex) {
  } catch (std::out_of_range ex) {
  }

  try {
    f = std::stoi(value);
    retval.type = SymTab::tNumber;
    retval.num = f;
    return retval;
  } catch (std::invalid_argument ex) {
  } catch (std::out_of_range ex) {
  }
  
  retval.type = SymTab::tString;
  retval.str = value;
  return retval;
}


