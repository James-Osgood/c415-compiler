/**
* Bison file for PAL compiler
* 
* Authors: Paul, James
* 
**/

%{
#include <stdio.h>
#include <memory.h>
#include <string.h>
#include <stdlib.h>
#include "symbol.h"
#include "myerror.h"

extern symbol 		*sList;  
extern myerror 		*eList;  
extern symbol 		*sSelected;  
extern int 			iserror;
extern int 			lineno, oldlineno;
extern int 			last_column;
extern char 		*errortext;
extern int              errorTextLength;
extern int 			looperrordetection;

void yyerror(const char *str)
{
    iserror = 1;
	eList = addError(eList, str, last_column, lineno);

}

int yywrap()
{
        return 1;
} 



%}

%defines  
%error-verbose

%union 
{
        
        double real;
        int number;
        char string[4096];
}
/* Reserved word tokens */
/* note: MOD and DIV are under operator tokens */
%token <string> AND ARRAY BEGIN_ CONST 
%token <string> CONTINUE DO ELSE
%token <string> END EXIT FUNCTION IF  
%token <string> NOT OF OR 
%token <string> PROCEDURE PROGRAM RECORD THEN
%token <string> TYPE VAR WHILE 

/* Relational tokens */
%token <string> ISEQUAL NOTEQUAL LESSTHAN GREATERTHAN 
%token <string> LESSTHANEQUALS GREATERTHANEQUALS

/* Operator tokens */
/* note: DIVIDE is for reals, div is for integer */
%token <string> PLUS MINUS MULTIPLY DIVIDE DIV MOD

/* Miscellaneous tokens */
%token <string> ASSIGN LEFTPAREN RIGHTPAREN PERIOD SEMICOLON COLON
%token <string> LEFTBRACKET RIGHTBRACKET COMMA DOUBLEPERIOD 

%token <string> ID RETURN

%token <string> UNKNOWN_CHARACTER

/* type tokens */

%token <string> INT_CONST REAL_CONST

%token <string> BOOL CHAR INT REAL STRING
/* %type <string> expr simple_expr term factor var subscripted_var unsigned_const */
/* %type <string> func_invok unsigned_num plist_finvok */

%left LEFTBRACKET ISEQUAL

%%
program                 : program_head decls compound_stat PERIOD
                        | error PERIOD /* ERROR */
                        | error /* ERROR */ {
                                                iserror = 1;
                                                yyerrok;
                                                looperrordetection++;
                                                if(looperrordetection == 300) {
                                                    looperrordetection = 0;
                                                    yyclearin;
                                                    /*yylex();*/
                                                    return 1;
                                                }
                                            }
                        ;

program_head            : PROGRAM ID LEFTPAREN ID COMMA ID RIGHTPAREN SEMICOLON
                        | PROGRAM ID LEFTPAREN error RIGHTPAREN SEMICOLON /* ERROR */
                        | error /* ERROR */
                        ;

decls                   : const_decl_part type_decl_part var_decl_part proc_decl_part
                        ;

const_decl_part         : /* empty */
                        | CONST const_decl_list SEMICOLON
                        | error SEMICOLON /* ERROR */
                        | error /* ERROR */
                        ;

const_decl_list         : const_decl
                        | const_decl_list SEMICOLON const_decl
                        ;

const_decl              : ID ISEQUAL expr
                        | error /* ERROR */
                        ;


type_decl_part          : /* empty */
                        | TYPE type_decl_list SEMICOLON
                        | error SEMICOLON /* ERROR */
                        | error /* ERROR */
                        ;

type_decl_list           :  /* empty */
                        | type_decl
                        | type_decl_list SEMICOLON type_decl
                        ;

type_decl               : ID ISEQUAL type
                        | error /* ERROR */
                        ;

type                    : simple_type
                        | structured_type
                        | error /* ERROR */
                        ;

simple_type             : scalar_type
                        | ID
                        ;

scalar_type             : LEFTPAREN scalar_list RIGHTPAREN
                        | LEFTPAREN error RIGHTPAREN /* ERROR */
                        | LEFTPAREN error /* ERROR */
                        | error RIGHTPAREN /* ERROR */
                        ;

scalar_list             : ID
                        | scalar_list COMMA ID
                        ;

structured_type         : ARRAY closed_array_type OF type
                        | RECORD field_list END
                        ;

closed_array_type       : LEFTBRACKET array_type RIGHTBRACKET
                        | LEFTBRACKET error RIGHTBRACKET /* ERROR */
                        | LEFTBRACKET error /* ERROR */
                        | error RIGHTBRACKET /* ERROR */
                        ;

array_type              : expr
                        | expr DOUBLEPERIOD expr
                        ;

field_list              : field
                        | field_list SEMICOLON field
                        ;

field                   : ID COLON type
                        | error /* ERROR */
                        ;

var_decl_part           : /* empty */
                        | VAR var_decl_list SEMICOLON
                        | error /* ERROR */
                        ;

var_decl_list           : var_decl
                        | var_decl_list SEMICOLON var_decl
                        ;

var_decl                : ID COLON type
                        | ID COMMA var_decl
                        | error /* ERROR */
                        ;

proc_decl_part          : /* empty */
                        | proc_decl_list
                        ;

proc_decl_list          : proc_decl
                        | proc_decl_list proc_decl
                        ;

proc_decl               : proc_heading decls compound_stat SEMICOLON
//                        | error SEMICOLON /* ERROR */
                        ;

proc_heading            : PROCEDURE ID f_parm_decl SEMICOLON
                        | FUNCTION ID f_parm_decl COLON ID SEMICOLON
                        | PROCEDURE error SEMICOLON /* ERROR */
                        | FUNCTION error SEMICOLON /* ERROR */
                        | error /* ERROR */
                        ;

f_parm_decl             : LEFTPAREN f_parm_list RIGHTPAREN
                        | LEFTPAREN RIGHTPAREN
                        | error RIGHTPAREN /* ERROR */
                        | error /* ERROR */
                        ;

f_parm_list             : f_parm
                        | f_parm_list SEMICOLON f_parm
                        ;

f_parm                  : ID COLON type
                        | VAR ID COLON type
                        | error /* ERROR */
                        ;

compound_stat           : BEGIN_ stat_list END
                        ;

stat_list               : stat
                        | stat_list SEMICOLON stat
                        | error SEMICOLON stat /* ERROR */
                        ;

stat                    : simple_stat
                        | struct_stat
                        ;

simple_stat             : /* empty */
                        | stat_assigment
                        | proc_invok
                        | compound_stat
                        ;

stat_assigment          : var ASSIGN expr
                        | error /* ERROR */
                        ;
                        
proc_invok              : plist_finvok RIGHTPAREN
                        | ID LEFTPAREN RIGHTPAREN
                        ;

var                     : ID
                        | var PERIOD ID
                        | subscripted_var RIGHTBRACKET
                        | error RIGHTBRACKET /* ERROR */
                        ;

subscripted_var         : var LEFTBRACKET expr
                        | subscripted_var COMMA expr
                        ;

expr                    : simple_expr
                        | expr ISEQUAL simple_expr
                        | expr NOTEQUAL simple_expr
                        | expr LESSTHANEQUALS simple_expr
                        | expr LESSTHAN simple_expr
                        | expr GREATERTHANEQUALS simple_expr
                        | expr GREATERTHAN simple_expr
                        ;

simple_expr             : term
                        | PLUS term
                        | MINUS term
                        | simple_expr PLUS term
                        | simple_expr MINUS term
                        | simple_expr OR term
                        | error /* ERROR */
                        ;

term                    : factor
                        | term MULTIPLY factor
                        | term DIVIDE factor
                        | term DIV factor
                        | term MOD factor
                        | term AND factor
                        ;

factor                  : var
                        | unsigned_const
                        | LEFTPAREN expr RIGHTPAREN
                        | LEFTPAREN error RIGHTPAREN /* ERROR */
                        | func_invok
                        | NOT factor
                        ;

unsigned_const          : unsigned_num
                        | STRING
                        ;

unsigned_num            : INT_CONST
                        | REAL_CONST
                        ;

func_invok              : plist_finvok RIGHTPAREN
                        | ID LEFTPAREN RIGHTPAREN
                        ;

plist_finvok            : ID LEFTPAREN parm
                        | plist_finvok COMMA parm
                        ;

parm                    : expr
                        ;

struct_stat             : IF expr THEN matched_stat ELSE stat
                        | error ELSE stat /* ERROR */
                        | IF expr THEN stat
                        | error THEN stat /* ERROR */
                        | WHILE expr DO stat
                        | error DO stat /* ERROR */
                        | CONTINUE
                        | EXIT
                        ;

matched_stat            : simple_stat
                        | IF expr THEN matched_stat ELSE matched_stat
                        | error ELSE matched_stat /* ERROR */
                        | WHILE expr DO matched_stat
                        | error DO matched_stat /* ERROR */
                        | CONTINUE
                        | EXIT
                        ;

%%
