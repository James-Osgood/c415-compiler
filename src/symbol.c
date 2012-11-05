/**
 * Author: Daniel Chui
 * Implementation of Symbol table
 * Uses Glib library
 */
 
 
#include <glib.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>

#include "builtin.h"  //separate builtins initalization from rest of this

#include "symbol.h"

GQueue* symbol_table = NULL;
int level = -1;

int func_counter = 1;

/**
addSymbol always adds the symbol to the topmost level
*/

symbol *addSymbol (char const *identifier, symbol *symbol) {
  GHashTable *table = g_queue_peek_head (symbol_table);
  g_hash_table_insert (table, identifier, symbol);

}
symbol *localLookup (char const *identifier) {
  GHashTable *table = g_queue_peek_head (symbol_table);
  symbol *returnedSymbol = g_hash_table_lookup (table, identifier);
  return returnedSymbol;
}
symbol *globalLookup (char const *identifier) {
  
  int numLevels = g_queue_get_length(symbol_table);
  symbol *returnedSymbol = NULL;
  while (numLevels > 0) {
    GHashTable *table = g_queue_peek_head (symbol_table);
    returnedSymbol = g_hash_table_lookup (table, identifier);
    if (returnedSymbol != NULL) {
      return returnedSymbol;
    }
    numLevels--;

  }
  return returnedSymbol;
}

void showAllSymbols() {
}

/**
Create a symbol with parameters: identifier, int type, int level, 
pointer * value
*/
symbol *createSymbol (char const *identifier, int type, 
int level , void * value) {
}

/**
 Our symbol table will need multiple levels, so we will
 need to add and remove levels as a new scope is defined
*/
void pushLevel () {
  level++;
  GHashTable *table = createNewTable (level);
  g_queue_push_head (symbol_table, table);

  

}


void popLevel () {
  g_queue_pop_head (symbol_table);
  level--;
}


/** 
Called to initialize the symbol table
*/
void init_table () {
  GQueue* table_stack = g_queue_new();
  GHashTable *builtin_table = createNewTable(level);
  //q_queue_push_tail (table_stack, builtin_table);
  
  //Add all the builtins here: call builtins function
  symbol_table = table_stack;
  
  
}

GHashTable *createNewTable(int level) {
  GHashTable *table = g_hash_table_new (g_str_hash, g_str_equal);
  return table;
}
