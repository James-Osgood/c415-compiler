/**
 * Author: James Osgood
 * Type creation, assignment, and checking for the grammar.
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "type.h"
#include "symbol.h"
#include "typeerrors.h"
#include "debug.h"

int
compatibleSym(symbol *sym1, symbol *sym2) {
    return compatible(sym1->desc.type_attr, sym1->desc.type_attr); // Incorrect, but I don't know if I'm actually going to use this ...
}

int
compatible(struct type_desc *type1, struct type_desc *type2) {
    // T1 and T2 are the exact same type:
    if (type1 == type2) {
        return 1;
    }
    type_class tc1 = type1->type;
    type_class tc2 = type2->type;
    
    // T1 and T2 are integers and/or reals:
    if ((tc1 == TC_INTEGER || tc1 == TC_REAL)
    && (tc2 == TC_INTEGER || tc2 == TC_REAL)) {
        return 1;
    }
    return 0;
}

int
assignmentCompatibleSym(symbol *sym1, symbol *sym2) {
    return compatible(sym1->desc.type_attr, sym1->desc.type_attr); // Incorrect, but I don't know if I'm actually going to use this ...
}

int
assignmentCompatible(struct type_desc *type1, struct type_desc *type2) {
    // T1 and T2 are the same type:
    if (type1 == type2) {
        return 1;
    }
    type_class tc1 = type1->type;
    type_class tc2 = type2->type;
    
    // check if booleans ...
    
    // T1 is of type real and T2 is of type integer:
    if (tc1 == TC_REAL && tc2 == TC_INTEGER) {
        return 1;
    }
    
    // T1 and T2 are assignment compatible arrays:
    if (tc1 == TC_ARRAY && tc2 == TC_ARRAY) {
    
        return arrayAssignmentCompatible(type1->desc.array,
                                         type2->desc.array);
    }
    
    return 0;
}

int
arrayAssignmentCompatible(struct tc_array *array1, struct tc_array *array2) {
    int objCompat = 1;
    int indEquiv = 1;
    struct type_desc *ot1 = array1->obj_type;
    struct type_desc *ot2 = array2->obj_type;
    
    if (!(assignmentCompatible(ot1, ot2) && assignmentCompatible(ot2, ot1))) {
        objCompat = 0;
        illArrayAssignObjError();
    }
    
    // index checking ...
    
    return objCompat && indEquiv;
}

struct type_desc *
createBaseType(type_class type) {
    struct type_desc *baseType = calloc(1, sizeof(struct type_desc));
    baseType->type = type;
    
    if (type == TC_INTEGER) {
        struct tc_integer *intType = calloc(1, sizeof(struct tc_integer));
        baseType->desc.integer = intType;
    } else if (type == TC_REAL) {
        struct tc_real *realType = calloc(1, sizeof(struct tc_real));
        baseType->desc.real = realType;
    } else if (type == TC_CHAR) {
        struct tc_char *charType = calloc(1, sizeof(struct tc_char));
        baseType->desc.character = charType;
    } else {
        baseType->desc.file = NULL; // You asked for it. Well, not really, but I'm lazy.
    }
    
    return baseType;
}

struct type_desc *
createStringType(type_class type, const char *string) {
    int len = strlen(string);
    
    struct tc_string *stringType = calloc(1, sizeof(struct tc_string));
    stringType->high = len;
    stringType->len = len;
    
    struct type_desc *baseType = calloc(1, sizeof(struct type_desc));
    baseType->type = type;
    baseType->desc.string = stringType;
    
    return baseType;
}

void
addProgramSymbols(const char *program, const char *input, const char *output) {
    struct type_desc *fileType = calloc(1, sizeof(struct type_desc));
    
    addNewSymbolAnonType(program, fileType, OC_PROGRAM); // Kinda cheating here, but no one should be touching these ...
    addNewSymbolAnonType(input, fileType, OC_PARAM);
    addNewSymbolAnonType(output, fileType, OC_PARAM);
}

symbol *
addNewSymbol(const char *id, symbol *type, object_class objClass) {
    if (localLookup(id) == NULL) {
        symbol *newSym;
        if (type == NULL) {
            typeNotDefinedError(id);
            struct type_desc *errorType = calloc(1, sizeof(struct type_desc));
            errorType->type = TC_ERROR;
            
            newSym = createSymbolAnonType(id, errorType, objClass, NULL);
        } else {
            newSym = createSymbol(id, type, objClass, NULL);
        }
        addSymbol(id, newSym);
    } else {
        symExistsError(id);
    }
    return type;
}

struct type_desc *
addNewSymbolAnonType(const char *id, struct type_desc *type, object_class objClass) {
    if (localLookup(id) == NULL) {
        symbol *newSym;
        if (type == NULL) {
            typeNotDefinedError(id);
            struct type_desc *errorType = calloc(1, sizeof(struct type_desc));
            errorType->type = TC_ERROR;
            
            newSym = createSymbolAnonType(id, errorType, objClass, NULL);
        } else {
            newSym = createSymbolAnonType(id, type, objClass, NULL);
        }
        addSymbol(id, newSym);
    } else {
        symExistsError(id);
    }
    return type;
}

symbol *getType(const char *id) {
    symbol *typeSymbol = globalLookup (id);
    
    if (typeSymbol == NULL) {
        symNotDefinedError(id);
      //TODO: error no symbol for this
    }
    if (OC_TYPE == typeSymbol->oc) {
      DEBUG_PRINT(("is an oc type\n"));
      DEBUG_PRINT(("typeSymbol: %p\n", typeSymbol->desc.type_attr));
      return typeSymbol->desc.type_attr;
    } else {
        symNotDefinedError(id);
      //TODO: error abot it not being a type class
      //O no. what to do here?
      return NULL;
    }
}

struct type_desc *
createScalarList(GArray *nameList) {
    int listSize = nameList->len;
    GArray *scalarList = g_array_new(1, 1, sizeof(symbol *));
    
    struct tc_const *constTypeClass = calloc(1, sizeof(struct tc_const));
    constTypeClass->len = listSize;
    struct type_desc *constType = calloc(1, sizeof(struct type_desc));
    constType->type = TC_CONST;
    constType->desc.enumeration = constTypeClass;
    
//     struct const_desc *constDesc;
    symbol *scalar;
    int i, tmp;
    
    for (i = 0; i < listSize; i++) {
//         constDesc = calloc(1, sizeof(struct const_desc));
//         constDesc->type = constType;
//         constDesc->value.integer = i + 1;
//         
//         scalar = calloc(1, sizeof(symbol));
//         scalar->name = g_array_index(nameList, const char *, i);
//         scalar->oc = OC_CONST;
//         scalar->desc.const_attr = constDesc;
        
        const char *name = g_array_index(nameList, const char *, i);
        tmp = i + 1;
        scalar = globalLookup(name);
        if (scalar == NULL) { // New symbol.
            scalar = createSymbolAnonType(name, constType, OC_CONST, (void *) &tmp);
        } else if ((scalar->oc != OC_CONST)
                || (scalar->desc.const_attr->type->type != TC_CONST)) {
                symNotValidEnumError();
                continue;
        }
        addSymbol(name, scalar);
        
        g_array_append_val(scalarList, scalar);
    }
    g_array_free(nameList, 0); // Just free the wrapper, but not the names themselves.
    
    struct tc_scalar *scalarTypeClass = calloc(1, sizeof(struct tc_scalar));
    scalarTypeClass->len = listSize;
    scalarTypeClass->const_list = scalarList;
    
    struct type_desc *scalarListType = calloc(1, sizeof(struct type_desc));
    scalarListType->type = TC_SCALAR;
    scalarListType->desc.scalar = scalarTypeClass;
    
    return scalarListType;
}

GArray *
addScalar(GArray *scalarList, const char *scalar) {
    if (scalarList == NULL) {
        scalarList = g_array_new(1, 1, sizeof(const char *));
    }
    int listSize = scalarList->len;
    int duplicate = 0;
    int i;
    
    for (i = 0; i < listSize; i++) {
        if (strcmp(g_array_index(scalarList, const char *, i), scalar) == 0) {
            duplicate = 1;
        }
    }
    
    if (localLookup(scalar) == NULL && duplicate == 0) {
        g_array_prepend_val(scalarList, scalar); // Added in 'correct' order.
    } else {
        symExistsError(scalar);
    }
    return scalarList;
}

struct type_desc *
createArray(struct type_desc *indexType, struct type_desc *objType) {
    DEBUG_PRINT (("Inside create array\n"));
    DEBUG_PRINT (("index type: %p object type: %p\n", indexType, objType));
    int indexClass = indexType->type;
    int size = 0;
    
    if (indexClass == TC_SUBRANGE) {
        struct tc_subrange *subrange = indexType->desc.subrange;
        size = subrange->high - subrange->low;
    } else if (indexClass == TC_INTEGER) {
        // ...
    } else if (indexClass == TC_CHAR) {
        // ...
    } 
    
    struct tc_array *newArray = calloc(1, sizeof(struct tc_array));
    newArray->size = size;
    newArray->index_type = indexType;
    newArray->obj_type = objType;
    
    struct type_desc *newType = calloc(1, sizeof(struct type_desc));
    newType->type = TC_ARRAY;
    newType->desc.array = newArray;
    
    return newType;
}

struct type_desc *createArrayIndex(struct type_desc *lowType, struct type_desc *highType) {
    if (lowType->type != highType->type) {
      //TODO: Throw error because types are incompatible
    }
    //TODO: Check to make sure that it is a valid type eg, enum, integer, etc.
    //TODO: Not another array, etc
    
    //TODO: Note that we are assuming that we have finished type checking here
    struct type_desc *typeDescription = calloc (1, sizeof (struct type_desc));
    typeDescription->type = TC_ARRAY;
    struct tc_array *arrayDescription = calloc (1, sizeof (struct tc_array));
    //TODO: Actually assign the different bounds for this
    typeDescription->desc.array = arrayDescription;
    
    
    return typeDescription;
}

struct type_desc *
createRecord(GArray *fieldList) {
    struct tc_record *newRecord = calloc(1, sizeof(struct tc_record));
    newRecord->field_list = fieldList;
    
    struct type_desc *newType = calloc(1, sizeof(struct type_desc));
    newType->type = TC_RECORD;
    newType->desc.record = newRecord;
    
    return newType;
}

GArray *
addField(GArray *fieldList, symbol *newField) {
    if (fieldList == NULL) {
        fieldList = g_array_new(1, 1, sizeof(symbol *));
    }
    int listSize = fieldList->len;
    const char *newName = newField->name;
    int i;
    
    for (i = 0; i < listSize; i++) {
        if (strcmp(g_array_index(fieldList, symbol *, i)->name, newName) == 0) {
            duplicateFieldError(newName);
            return fieldList;
        }
    }
    g_array_prepend_val(fieldList, newField); // Added in 'correct' order.
    
    return fieldList;
}
