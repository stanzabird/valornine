#ifndef INCLUDED_SYMTAB_H
#define INCLUDED_SYMTAB_H

#include <string>
#include <vector>
#include <map>


struct SymTab
{
  enum Type {
    tString, tNumber, tBoolean, tNil, tArray
  };
  
  struct DirectValue {
    Type type;			// tString,tNumber,tBoolean
    
    // values (not an union because std::string causes problems)
    std::string str;
    float num;
    bool  b;
  };

  struct ObjectValue;
  
  struct ArrayValue {
    std::vector<DirectValue> values;
  };

  struct ObjectValue {
    std::map<std::string,DirectValue> direct_members;
    std::map<std::string,ArrayValue> array_members;
  };

  // the three symbol tables
  std::map<std::string,DirectValue> direct_symbols;
  std::map<std::string,ArrayValue>  array_symbols;
  std::map<std::string,ObjectValue> object_symbols;

  // adding symbols to the symtab
  void add(std::string name, std::string value);
  void add(std::string name, int value);
  void add(std::string name, float value);
  void add(std::string name, bool value);
  void add(std::string name, DirectValue value);

  // retrieving symbols
  bool is_defined(std::string name);
  bool is_array(std::string name);
  std::vector<DirectValue> get_array_value(std::string name);
  DirectValue get_direct_value(std::string name);

  // return a bool or number if value can be converted.
  static DirectValue string2direct_value(std::string value);
private:
  void parse_name(std::string name, std::string& varname, std::string& membername);
};




#endif
