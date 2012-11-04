# Makefile for pal executable
#
# Authors:
#  Mike Bujold
#  Dan Chui
#  James Osgood
#
# To Compile, type:
#     make

CC = gcc
FLAGS = -g

PY = python

GRAMMAR = src/compiler.y
GRAMMAR_C = compiler.tab.c
LEXER = src/compiler.lex
LEXER_C = lex.yy.c
SOURCE = src/myerror.c src/symbol.c src/compiler.c
GLIB = `pkg-config --cflags --libs glib-2.0`

RUNNER = tests/runner.py
TESTS = 0 1 2 3 4

CP2DIR = c415g05_cp2
SOLUTION = Makefile README src doc
SUBTESTS = submitted_tests

# Stops bison from overwriting compiler.c
%.c: %.y
%.c: %.l

all: clean pal

man:
	groff -man -T ascii doc/pal.1

pal: ${GRAMMAR} ${LEXER} ${SOURCE}
	flex -i -o src/${LEXER_C} ${LEXER} 
	bison -d -v ${GRAMMAR} -o src/${GRAMMAR_C} 
	$(CC) $(FLAGS) src/${GRAMMAR_C} src/${LEXER_C} ${SOURCE} -o pal $(GLIB)

debug: ${GRAMMAR} ${LEXER} ${SOURCE}
	flex -i ${LEXER}
	bison -d -v ${GRAMMAR}
	$(CC) $(FLAGS) ${GRAMMAR_C} ${LEXER_C} ${SOURCE} -D DEBUG=1 -o pal $(GLIB) 

cp2:
	make pal
	$(PY) $(RUNNER) -sn $(TESTS)
	mkdir $(CP2DIR)
	make clean
	cp -r $(SOLUTION) $(SUBTESTS) $(CP2DIR)
	tar -cvzf $(CP2DIR).tgz $(CP2DIR)
	rm -rf $(CP2DIR) $(SUBTESTS)
	
clean:
	rm -f pal core *.output
	rm -f src/lex.yy.c src/*.tab.c src/*.tab.h 
	rm -f doc/pal.log
	rm -f doc/pal.pdf
	find . -name \*~ -type f -delete
	find . -name \*.lst -type f -delete

