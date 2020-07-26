#ifndef INCLUDED_TRIM_H
#define INCLUDED_TRIM_H

// taken from:
// http://stackoverflow.com/questions/216823/whats-the-best-way-to-trim-stdstring

#include <string>

std::string &ltrim(std::string &s); // trim from start
std::string &rtrim(std::string &s); // trim from end
std::string &trim(std::string &s);  // trim from both ends

#endif

