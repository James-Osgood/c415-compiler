/**
 * Author: James Osgood
 * Add various semantic type errors.
 */

#include <stdio.h>
#include <string.h>
#include "myerror.h"

extern myerror *eList;
extern int iserror;
extern int lineno;
extern int last_column;

void
addTypeError(const char *errMsg) {
    iserror = 1;
    eList = addError(eList, errMsg, last_column, lineno);
}

void
typeNotDefinedError(const char *id) {
    char errMsg[90 + strlen(id)];
    sprintf(errMsg,
            "type not defined for symbol '%s'; subsequent type errors with this symbol will be ignored",
            id);
    addTypeError(errMsg);
}

void
symExistsError(const char *id) {
    char errMsg[50 + strlen(id)];
    sprintf(errMsg, "symbol '%s' already defined in this scope", id);
    addTypeError(errMsg);
}

void
symNotDefinedError(const char *id) {
    char errMsg[25 + strlen(id)];
    sprintf(errMsg, "no '%s' symbol defined", id);
    addTypeError(errMsg);
}

void
symNotATypeError(const char *id) {
    char errMsg[25 + strlen(id)];
    sprintf(errMsg, "symbol '%s' not a type", id);
    addTypeError(errMsg);
}

void symNotAVarParmConstError(const char *id) {
    char errMsg[50 + strlen(id)];
    sprintf(errMsg, "symbol '%s' not a variable, parameter, or constant", id);
    addTypeError(errMsg);
}

void
symNotValidEnumError(const char *id) {
    char errMsg[50 + strlen(id)];
    sprintf(errMsg, "symbol '%s' not a valid enumeration type", id);
    addTypeError(errMsg);
}

void
illArrayAssignObjError(){
    addTypeError("illegal array assignment (object types not compatible)");
}

void arrayMissLowerError() {
    addTypeError("array index missing lower bound");
}

void arrayLowerNotConstError() {
    addTypeError("array index lower bound not of constant type");
}

void arrayBoundTypeError() {
    addTypeError("array index lower bound not the same type as upper bound");
}

void arrayBoundInvalidError() {
    addTypeError("array index bounds are not valid array index types");
}

void lowerGreaterThanUpperError() {
    addTypeError("lower bound is greater than upper bound");
}

void arrayIndexTypeError() {
    addTypeError("array index type not a valid array index type");
}

void
duplicateFieldError(const char *id) {
    char errMsg[25 + strlen(id)];
    sprintf(errMsg, "duplicate field '%s'", id);
    addTypeError(errMsg);
}

void
opNotBooleanError() {
    addTypeError("operator not of type boolean");
}
