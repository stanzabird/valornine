CC=gcc
YACC=bison
LEX=flex

json: json.o
	ln -nfs $< $@

%.o: %.lex.c %.tab.c %.tab.h
	$(CC) -o $@ $^ #-lfl

%.lex.c: %.l
	$(LEX) -o $(patsubst %.l,%.lex.c,$<) $<

%.tab.c %.tab.h: %.y
	$(YACC) -d $<

.PHONY: clean

clean:
	rm -f *.lex.c *.tab.c *.tab.h *.o json
