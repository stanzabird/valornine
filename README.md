# ValorNine

### what is it used for?

Use a personal set of stored projects to generate fresh new projects with a simple command. I mostly
use it for creating templates of programs that use the [Gnu Autoconf Archive](https://www.gnu.org/software/autoconf-archive/index.html).

The name 'ValorNine' is inspired by the signifcance of the number nine in Norse mythology. The name of the executable is 'vn'. The subfolder 'tests' contains examples of vn templates to get you started. You can read the whole syntax in the file [syntax.md](https://github.com/opalraava/valornine/blob/master/syntax.md).

### how to compile?
```
./configure
make
```
If ./configure is not found, run the following:
```
autoreconf -i
```
To cross-compile to win64 on Fedora, use:
```
mingw64-configure
```
### default location for the stored projects?
I use a folder *~/.vn.d* to store my various templates and use a symlink to the default template, which is *~/.default.vn*.
```
ls -lad ~/.default.vn
lrwxrwxrwx 1 user user 19 Apr 30 02:20 .default.vn -> .vn.d/yasm.vn

```
To change the file used for stored projects, do:
```
VN_DATAFILE=/tmp/mydatafile.vn vn list
```
Or specify the template file on the commandline with the -t option.

Using the VN_DATAFILE variable to point to the default template is the preferred way to specify it under Windows.

## Syntax
The syntax of the valornine files is based on [Luiqid](https://shopify.github.io/liquid/) and Jekyll.
A simple example file could be:
```
---
author: John Doe
email: john.doe@example.com
---

{% project "my-example" %}

{% file "README.txt" %}
This is just an example file.
{% endfile %}

{% file "hello.c" %}
#include <stdio.h>

int main()
{
  printf("Hi, I'm {{ author }} and my email is {{ email }}\n");
  return 0;
}
{% endfile %}

{% endproject %}
```
As you can see, the header part defines two variables, much like you do in Jekyll markdown files.

You can find two working examples in the tests/ subfolder of this project. The c.vn file contains the most basic type of autotools project, written in "C".

The c++.vn file contains two projects, one called *cxx-basic* that has the most basic form of C++ autotools project. It includes macro's to detect the C++ version wanted, such as c++14 or c++17.

The other project in c++.vn is *cxx-boost-asio* That produces the smallest possible project in c++ that has language version detection and includes Boost.Asio.

Please note that if boost is used for mingw cross-compilation to windows, you should specify the boost libdir like so:
```
mingw64-configure --with-boost-libdir=/usr/x86_64-w64-mingw32/sys-root/mingw/lib
```
