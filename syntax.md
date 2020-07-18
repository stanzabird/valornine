# ValorNine Template Syntax

## header
You can optinally define global variables in the header like so:
```
---
a: Some string
b: 1
my_bool: true
---
```
It's just a list of variables and their values much like you do in Jekyll.

## Main body
The main body has three toplevel elements:

* **{% project %}**
* **{% snippet %}**
* **{% binary %}**

Template expansion works only on files in a project and on snippets.

### {% project %}
A project is nothing more than a set of files. You end the definition
of a project by the {% endproject %} tag.
### {% file %}
You can have the following ways to create a file in the project.

* {% file "src/foo.py" %} *template content...* {% endfile %}
* {% file snippet test_m4 "m4/test.m4" %}
* {% file binary my_icon "src/appico.png" %}

### {% snippet %}
A snippet has the following syntax:

* {% snippet test_m4 %} *template content...* {% endsnippet %}

### {% binary %}

* {% binary my_icon %} *hex bytes...* {% endbinary %}

The easiest way to make the hex bytes content of the {% binary %} tag is to let vn provide them to you, like so:
```
vn binary appico.png > tmp.txt
```
And then insert tmp.txt into your template using a text editor.

## Template expansion:

Within {% file %} and {% snippet %}, you have template expansion much like you have in Jekyll and Liquid. ValorNine does not implement the whole of Liquid, and the syntax of the template expansion evolves as the need arrives.

Currently, the only thing working is variable expansion and filters:

* **{{ var }}** - expand the value of 'var'.
* **{{ project_name }}** - special variable that expands to the name of the current project.
* **{{ name }}** - name of the file currently expanded. This also holds when expanding a {% snippet %}.
* **{{ ext }}** - extension of the current file (without dot).
* **{{ year }}** - the current year. Mostly for copyright messages.

The filters:
* **{{ var | capitalize }}** - get the value of var, and then capitalize it.
* **{{ "hi" | capitalize | append: " there." }}** - This wil give the string "Hi there.".
* **{{ "hi" | upcase }}** - to uppercase, "HI".
* **{{ "HI" | downcase }}** - to lowercase, "hi".

