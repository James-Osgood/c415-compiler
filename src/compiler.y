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
#include <glib.h>

#include "symbol.h"
#include "type.h"
#include "operators.h"
#include "myerror.h"

#include "debug.h"

extern myerror *eList;
extern int iserror;
extern int lineno;
extern int last_column;
extern int looperrordetection;

void yyerror(const char *str) {
    iserror = 1;
    eList = addError(eList, str, last_column, lineno);
}

int yywrap() {
        return 1;
}

%}

%defines
%error-verbose

%union {
    char *id;
    char *string;
    int integer;
    double real;
    symbol *symbol;
    GPtrArray *garray;
    struct type_desc *anon_type; // can probably get rid of this ...
}

/* Reserved word tokens */
/* note: MOD and DIV are under operator tokens */
%token AND ARRAY BEGIN_ CONST 
%token CONTINUE DO ELSE
%token END EXIT FUNCTION IF  
%token NOT OF OR 
%token PROCEDURE PROGRAM RECORD THEN
%token TYPE VAR WHILE 

/* Relational tokens */
%token ISEQUAL NOTEQUAL LESSTHAN GREATERTHAN 
%token LESSTHANEQUALS GREATERTHANEQUALS

/* Operator tokens */
/* note: DIVIDE is for reals, div is for integer */
%token PLUS MINUS MULTIPLY DIVIDE DIV MOD

/* type tokens */

%token <integer> INT_CONST
%token <real> REAL_CONST 
%token <string> STRING

/* Miscellaneous tokens */
%token ASSIGN LEFTPAREN RIGHTPAREN PERIOD SEMICOLON COLON
%token LEFTBRACKET RIGHTBRACKET COMMA DOUBLEPERIOD 
%token RETURN
%token <id> ID

%token <string> UNKNOWN_CHARACTER

/* Symbol types */
%type <symbol> type 
%type <symbol> structured_type closed_array_type array_type
%type <symbol> simple_type
%type <garray> scalar_type scalar_list field_list
%type <symbol> field
%type <symbol> var_decl
%type <symbol> var subscripted_var parm
%type <symbol> expr simple_expr term factor unsigned_const unsigned_num
%type <garray> f_parm_decl f_parm_list
%type <symbol> f_parm
/*%type <symbol> const_decl
%type <symbol> type_decl type simple_type scalar_type scalar_list structured_type closed_array_type array_type
%type <symbol> field

%type <symbol> proc_heading
%type <symbol> var subscripted_var f_parm*/

/* %type <string> expr simple_expr term factor var subscripted_var unsigned_const */
/* %type <string> func_invok unsigned_num plist_finvok */

%left LEFTBRACKET ISEQUAL

%%
program                 : program_head decls compound_stat PERIOD
                            {
/*                                 showAllSymbols(); */
                                popLevel();
                            }
                        | error PERIOD /* ERROR */
                            {
/*                                 showAllSymbols(); */
                                popLevel();
                            }
                        | error /* ERROR */
                            {
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
                            {
                                pushLevel();
                                addProgramSymbols($2, $4, $6);
                            }
                        | PROGRAM ID LEFTPAREN error RIGHTPAREN SEMICOLON /* ERROR */
                            {
                                pushLevel();
                            }
                        | error /* ERROR */
                            {
                                pushLevel();
                            }
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
                            {
                                addNewConst($1, $3);
                            }
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
                            {
                                if ($3 != NULL) {
                                    addNewType($1, $3);
                                }
                            }
                        | error /* ERROR */
                        ;

type                    : simple_type
                            {
                                $$ = $1;
                            }
                        | structured_type
                            {
                                $$ = $1;
                            }
                        | error /* ERROR */
                            {
                                $$ = NULL;
                            }
                        ;

simple_type             : scalar_type
                            {
                                if ($1 != NULL) {
                                    $$ = createScalarList($1);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        | ID
                            {
                                $$ = getType($1);
                            }
                        ;

scalar_type             : LEFTPAREN scalar_list RIGHTPAREN
                            {
                                $$ = $2;
                            }
                        | LEFTPAREN error RIGHTPAREN /* ERROR */
                            {
                                $$ = NULL;
                            }
                        | LEFTPAREN error /* ERROR */
                            {
                                $$ = NULL;
                            }
                        | error RIGHTPAREN /* ERROR */
                            {
                                $$ = NULL;
                            }
                        ;

scalar_list             : ID
                            {
                                $$ = addScalar(NULL, $1);
                            }
                        | scalar_list COMMA ID
                            {
                                if ($1 != NULL) {
                                    $$ = addScalar($1, $3);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        ;

structured_type         : ARRAY closed_array_type OF type
                            {
                                DEBUG_PRINT (("Inside structured type\n"));
                                if ($2 != NULL && $4 != NULL) {
                                    $$ = createArray($2, $4);
                                } else {
                                    $$ = NULL;
                                }
                                DEBUG_PRINT(("Finished calling structured type\n"));
                            }
                        | RECORD field_list END
                            {
                                if ($2 != NULL) {
                                    $$ = createRecord($2);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        ;

closed_array_type       : LEFTBRACKET array_type RIGHTBRACKET
                            {
                                DEBUG_PRINT (("inside closed aray type: %p", $$));
                                $$ = $2;
                            }
                        | LEFTBRACKET error RIGHTBRACKET /* ERROR */
                            {
                                $$ = NULL;
                            }
                        | LEFTBRACKET error /* ERROR */
                            {
                                $$ = NULL;
                            }
                        | error RIGHTBRACKET /* ERROR */
                            {
                                $$ = NULL;
                            }
                        ;

array_type              : expr
                            {
                                if ($1 != NULL) {
                                    $$ = createArrayIndex(NULL, $1);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        | expr DOUBLEPERIOD expr
                            {
                                if ($1 != NULL && $3 != NULL) {
                                    $$ = createArrayIndex($1, $3);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        ;

field_list              : field
                            {
                                if ($1 != NULL) {
                                    $$ = addField(NULL, $1);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        | field_list SEMICOLON field
                            {
                                if ($1 != NULL && $3 != NULL) {
                                    $$ = addField($1, $3);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        ;

field                   : ID COLON type
                            {
                                DEBUG_PRINT(("In field\n"));
                                if ($3 != NULL) {
                                    $$ = createSymbol($1, $3, OC_PARAM, NULL);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        | error /* ERROR */
                            {
                                $$ = NULL;
                            }
                        ;

var_decl_part           : /* empty */
                        | VAR var_decl_list SEMICOLON
                        | error /* ERROR */
                        ;

var_decl_list           : var_decl
                        | var_decl_list SEMICOLON var_decl
                        ;

var_decl                : ID COLON type
                            {
                                if ($3 != NULL) {
                                    $$ = addNewVar($1, $3);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        | ID COMMA var_decl
                            {
                                if ($3 != NULL) {
                                    $$ = addNewVar($1, $3);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        | error /* ERROR */
                            {
                                $$ = NULL;
                            }
                        ;

proc_decl_part          : /* empty */
                        | proc_decl_list
                        ;

proc_decl_list          : proc_decl
                        | proc_decl_list proc_decl
                        ;

proc_decl               : proc_heading decls compound_stat SEMICOLON
                            {
/*                                 showAllSymbols(); */
                                popLevel();
                            }
                        | error SEMICOLON /* ERROR */
                            {
/*                                 showAllSymbols(); */
                                popLevel();
                            }
                        ;

proc_heading            : PROCEDURE ID f_parm_decl SEMICOLON
                            {
                                if ($3 != NULL) {
                                    addNewProc($2, $3);
                                }
                            }
                        | FUNCTION ID f_parm_decl COLON ID SEMICOLON
                            {
                                if ($3 != NULL) {
                                    addNewFunc($2, $5, $3);
                                }
                            }
                        | PROCEDURE error SEMICOLON /* ERROR */
                            {
                                //pushLevel();
                            }
                        | FUNCTION error SEMICOLON /* ERROR */
                            {
                                pushLevel();
                            }
                        | error /* ERROR */
                            {
                                pushLevel();
                            }
                        ;

f_parm_decl             : LEFTPAREN f_parm_list RIGHTPAREN
                            {
                                $$ = $2;
                            }
                        | LEFTPAREN RIGHTPAREN
                            {
                                pushLevel();
                                $$ = addParam(NULL, NULL);
                            }
                        | error RIGHTPAREN /* ERROR */
                            {
                                pushLevel();
                                $$ = NULL;
                            }
                        | error /* ERROR */
                            {
                                pushLevel();
                                $$ = NULL;
                            }
                        ;

f_parm_list             : f_parm
                            {
                                if ($1 != NULL) {
                                    $$ = addParam(NULL, $1);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        | f_parm_list SEMICOLON f_parm
                            {
                                if ($1 != NULL && $3 != NULL) {
                                    $$ = addParam($1, $3);
                                } else {
                                    $$ = NULL;
                                }
                            }
                        ;

f_parm                  : ID COLON ID
                            {
                                $$ = addNewParam($1, $3);
                            }
                        | VAR ID COLON ID
                            {
                                $$ = addNewParam($2, $4);
                            }
                        | error /* ERROR */
                            {
                                $$ = NULL;
                            }
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
                        | stat_assignment
                        | proc_invok
                        | compound_stat
                        ;

stat_assignment         : var ASSIGN expr
                            {
			      //DEBUG_PRINT(("Inside a var assignment"));
			      doVarAssignment ($1, $3);
                                // Have to finish this ...
                            }
                        | error /* ERROR */
                            {
                                //$$ = NULL:
                            }
                        ;
                        
proc_invok              : plist_finvok RIGHTPAREN
                        | ID LEFTPAREN RIGHTPAREN
                        ;

var                     : ID
                            {
                                $$ = getVarSymbol($1);
                            }
                        | var PERIOD ID
                        | subscripted_var RIGHTBRACKET
                        | error RIGHTBRACKET /* ERROR */
                            {
                                $$ = NULL;
                            }
                        ;

subscripted_var         : var LEFTBRACKET expr
                        | subscripted_var COMMA expr
                        ;

expr                    : simple_expr
                            {
                                $$ = $1;
                            }
                        | expr ISEQUAL simple_expr
                        | expr NOTEQUAL simple_expr
                        | expr LESSTHANEQUALS simple_expr
                        | expr LESSTHAN simple_expr
                        | expr GREATERTHANEQUALS simple_expr
                        | expr GREATERTHAN simple_expr
                        ;

simple_expr             : term
                            {
                                $$ = $1;
                            }
                        | PLUS term
                        | MINUS term
                        | simple_expr PLUS term
                        | simple_expr MINUS term
                        | simple_expr OR term
                        ;

term                    : factor
                            {
                                $$ = $1;
                            }
                        | term MULTIPLY factor
                        | term DIVIDE factor
                        | term DIV factor
                        | term MOD factor
                        | term AND factor
                        | error /* ERROR */
                            {
                                $$ = NULL;
                            }
                        ;

factor                  : var
                            {
                                $$ = $1;
                            }
                        | unsigned_const
                            {
                                $$ = $1;
                            }
                        | LEFTPAREN expr RIGHTPAREN
                            {
                                $$ = $2;
                            }
                        | LEFTPAREN error RIGHTPAREN /* ERROR */
                            {
                                $$ = NULL;
                            }
                        | func_invok
                            {
                                // Have to finish this ...
                            }
                        | NOT factor
                            {
                                $$ = notOp($2);
                            }
                        ;

unsigned_const          : unsigned_num
                            {
                                $$ = $1;
                            }
                        | STRING
                            {
                                union constant_values value = { .string = $1 };
                                $$ = createConstant(TC_STRING, value);
                            }
                        ;

unsigned_num            : INT_CONST
                            {                                
                                union constant_values value = { .integer = $1 };
                                $$ = createConstant(TC_INTEGER, value);
                            }
                        | REAL_CONST
                            {                                
                                union constant_values value = { .real = $1 };
                                $$ = createConstant(TC_REAL, value);
                            }
                        ;

func_invok              : plist_finvok RIGHTPAREN
                        | ID LEFTPAREN RIGHTPAREN
                        ;

plist_finvok            : ID LEFTPAREN parm
                        | plist_finvok COMMA parm
                        ;

parm                    : expr
                            {
                                $$ = $1;
                            }
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
