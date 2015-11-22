/***********************************************************************

SPL, the Shakespeare Programming Language

Copyright (C) 2001 Karl Hasselstr�m and Jon �slund

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
USA.

***********************************************************************/

%{
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <glib.h>

#include "helper.h"
#include "strutils.h"
#include "telma.h"

#define COMMENT_COLUMN   40     //
#define INDENTATION_SIZE 2      // number of spaces to indent output C code
#define BUF_SIZE         1024   // size of input buffer(s)

/* ERROR CODES */
#define ERROR_OUT_OF_MEM   10
#define ERROR_NO_STACK     11
#define ERROR_NOT_ON_STAGE 12

/* macro to create indentation space */
#define INDENT (strpad(newstr(""), INDENTATION_SIZE, ' '))

/* Global variables local to this file */
GHashTable *CHARACTERS;
GHashTable *ON_STAGE;
static char *current_act      = NULL;
static char *current_scene    = NULL;
static int num_errors;           // error counter
static int num_warnings;         // warning counter
static int i;                    // all-purpose counter
static character *first_person     = NULL;
static character *second_person    = NULL;
%}

%union {
  char *str;
  int num;
  struct {
    int num;
    char **list;
  } stringlist;
}

%token <str> ARTICLE
%token <str> BE
%token <str> CHARACTER
%token <str> FIRST_PERSON
%token <str> FIRST_PERSON_POSSESSIVE
%token <str> FIRST_PERSON_REFLEXIVE
%token <str> NEGATIVE_ADJECTIVE
%token <str> NEGATIVE_COMPARATIVE
%token <str> NEGATIVE_NOUN
%token <str> NEUTRAL_ADJECTIVE
%token <str> NEUTRAL_NOUN
%token <str> NOTHING
%token <str> POSITIVE_ADJECTIVE
%token <str> POSITIVE_COMPARATIVE
%token <str> POSITIVE_NOUN
%token <str> SECOND_PERSON
%token <str> SECOND_PERSON_POSSESSIVE
%token <str> SECOND_PERSON_REFLEXIVE
%token <str> THIRD_PERSON_POSSESSIVE

%token <str> COLON
%token <str> COMMA
%token <str> EXCLAMATION_MARK
%token <str> LEFT_BRACKET
%token <str> PERIOD
%token <str> QUESTION_MARK
%token <str> RIGHT_BRACKET

%token <str> AND
%token <str> AS
%token <str> ENTER
%token <str> EXEUNT
%token <str> EXIT
%token <str> HEART
%token <str> IF_NOT
%token <str> IF_SO
%token <str> LESS
%token <str> LET_US
%token <str> LISTEN_TO
%token <str> MIND
%token <str> MORE
%token <str> NOT
%token <str> OPEN
%token <str> PROCEED_TO
%token <str> RECALL
%token <str> REMEMBER
%token <str> RETURN_TO
%token <str> SPEAK
%token <str> THAN
%token <str> THE_CUBE_OF
%token <str> THE_DIFFERENCE_BETWEEN
%token <str> THE_FACTORIAL_OF
%token <str> THE_PRODUCT_OF
%token <str> THE_QUOTIENT_BETWEEN
%token <str> THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN
%token <str> THE_SQUARE_OF
%token <str> THE_SQUARE_ROOT_OF
%token <str> THE_SUM_OF
%token <str> TWICE
%token <str> WE_MUST
%token <str> WE_SHALL

%token <str> ACT_ROMAN
%token <str> SCENE_ROMAN
%token <str> ROMAN_NUMBER

%token <str> NONMATCH


%type <character>  CharacterDeclaration
%type <charlist>   CharacterDeclarationList
%type <CHARACTERLIST> CharacterList
%type <str>        Comment
%type <str>        EnterExit
%type <str>        StatementSymbol
%type <str>        String
%type <str>        StringSymbol
%type <num>        Value
%type <str>        StartSymbol
%type <str>        EndSymbol
%type <str>        QuestionSymbol
%type <num>        Recall
%type <str>        Remember
%type <num>        Constant
%type <num>        UnarticulatedConstant
%type <num>        PositiveConstant
%type <num>        NegativeConstant
%type <str>        PositiveNoun
%type <str>        NegativeNoun
%type <character>  Pronoun
%type <str>        BinaryOperator

%start StartSymbol

%%

StartSymbol:
CharacterDeclarationList {

}


EndSymbol:
QuestionSymbol {
   $$ = $1;
}|
StatementSymbol {
   $$ = $1;
};
QuestionSymbol:
QUESTION_MARK {
     $$ = $1;
};

Recall:
RECALL String StatementSymbol {
  $$ = pop(second_person);
  free($1);
  free($2);
  free($3);
}|
RECALL error StatementSymbol {
  report_warning("string");
  $$ = pop(second_person);
  free($1);
  free($3);
}|
RECALL String error {
  report_warning("period or exclamation mark");
  $$ = pop(second_person);
  free($1);
  free($2);
};

Remember:
REMEMBER Value StatementSymbol {
  push(second_person, $2);
  free($1);
  free($3);
}|
REMEMBER error StatementSymbol {
  report_error("value");
  free($1);
  free($3);
}|
REMEMBER Value error {
  report_warning("period or exclamation mark");
  push(second_person, $2);
  free($1);
};

CharacterDeclaration:
CHARACTER COMMA Comment EndSymbol {
  initialize_character($1);
  free($2);
  free($4);
}|
error COMMA Comment EndSymbol {
  report_error("character name");
}|
CHARACTER error Comment EndSymbol {
  report_error("comma");
};

CharacterDeclarationList:
CharacterDeclaration {

}|
CharacterDeclarationList CharacterDeclaration {

};

CharacterList:
CHARACTER AND CHARACTER {
   CHARACTERLIST *s1 = (CHARACTERLIST*)malloc(sizeof(CHARACTERLIST));
   s1 -> name = $1;
   s1 -> next = NULL;

   CHARACTERLIST *s2 = (CHARACTERLIST*)malloc(sizeof(CHARACTERLIST));
   s2 -> name = $3;
   s2 -> next = s1;
   
   $$ = s2;
}|
CHARACTER COMMA CharacterList {
  CHARACTERLIST *s = (CHARACTERLIST*)malloc(sizeof(CHARACTERLIST));
  s -> name = $1;
  s -> next = $3;
  

  free($2);

   $$ = s;
};

Comment:
String {
  $$ = cat3(newstr("/* "), $1, newstr(" */"));
}|
error {
  report_warning("comment");
  $$ = newstr("/* NO COMMENT FOUND */");
};

Line:
CHARACTER COLON SentenceList {
  activate_character($1);
  free($2);
}|
CHARACTER COLON error {
  report_error("sentence list");
  free($1);
  free($2);
}|
CHARACTER error SentenceList {
  report_error("colon");
  free($1);
};

InOut:
OpenYour HEART StatementSymbol {
  printf("%d", second_person->num);
  free($2);
  free($3);
}|
SPEAK SECOND_PERSON_POSSESSIVE MIND StatementSymbol {
  putc(second_person->num, stdout);
  free($1);
  free($2);
  free($3);
  free($4);
}|
LISTEN_TO SECOND_PERSON_POSSESSIVE HEART StatementSymbol {
  second_person->num = int_input();
  free($1);
  free($2);
  free($3);
  free($4);
}|
OpenYour MIND StatementSymbol {
  second_person->num = getc(stdin);
  if (second_person->num == EOF) {
    second_person->num = -1;
  }
  free($2);
  free($3);
}|
OpenYour error StatementSymbol {
  report_error("'mind' or 'heart'");
  free($3);
}|
SPEAK error MIND StatementSymbol {
  report_warning("possessive pronoun, second person");
  putc(second_person->num, stdout);
  free($1);
  free($3);
  free($4);
}|
LISTEN_TO error HEART StatementSymbol {
  report_warning("possessive pronoun, second person");
  second_person->num = int_input();
  free($1);
  free($3);
  free($4);
}|
SPEAK SECOND_PERSON_POSSESSIVE error StatementSymbol {
  report_warning("'mind'");
  putc(second_person->num, stdout);
  free($1);
  free($2);
  free($4);
}|
LISTEN_TO SECOND_PERSON_POSSESSIVE error StatementSymbol {
  report_warning("'heart'");
  second_person->num = int_input();
  free($1);
  free($2);
  free($4);
}|
OpenYour HEART error {
  report_warning("period or exclamation mark");
  printf("%d", second_person->num);
  free($2);
}|
SPEAK SECOND_PERSON_POSSESSIVE MIND error {
  report_warning("period or exclamation mark");
  putc(second_person->num, stdout);
  free($1);
  free($2);
  free($3);
}|
LISTEN_TO SECOND_PERSON_POSSESSIVE HEART error {
  report_warning("period or exclamation mark");
  second_person->num = int_input();
  free($1);
  free($2);
  free($3);
}|
OpenYour MIND error {
  report_warning("period or exclamation mark");
  second_person->num = getc(stdin);
  if (second_person->num == EOF) {
    second_person->num = -1;
  }
  free($2);
};

OpenYour:
OPEN SECOND_PERSON_POSSESSIVE {
  free($1);
  free($2);
}|
OPEN error {
  report_warning("possessive pronoun, second person");
  free($1);
};

SentenceList: Sentence | SentenceList Sentence;

/* TODO */
UnconditionalSentence: Recall | Remember;

/* TODO */
Sentence: UnconditionalSentence;

EnterExit:
LEFT_BRACKET ENTER CHARACTER RIGHT_BRACKET {
  CHARACTERLIST * c = malloc(sizeof(CHARACTERLIST));
  c -> name = $3;
  c -> next = NULL;

  enter_stage(c);
  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET ENTER CharacterList RIGHT_BRACKET {
  enter_stage($3);
  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXIT CHARACTER RIGHT_BRACKET {
  CHARACTERLIST * c = malloc(sizeof(CHARACTERLIST));
  c -> name = $3;
  c -> next = NULL;

  exit_stage(c);

  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXEUNT CharacterList RIGHT_BRACKET {
  exit_stage($3);

  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXEUNT RIGHT_BRACKET {
  exeunt_stage();

  free($1);
  free($2);
  free($3);
}|
LEFT_BRACKET ENTER error RIGHT_BRACKET {
  report_error("character or character list");

  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXIT error RIGHT_BRACKET {
  report_error("character");

  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXEUNT error RIGHT_BRACKET {
  report_error("character list or nothing");

  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET error RIGHT_BRACKET {
  report_error("'enter', 'exit' or 'exeunt'");

  free($1);
  free($3);
};

StatementSymbol:
EXCLAMATION_MARK {
  $$ = $1;
}|
PERIOD {
  $$ = $1;
};

String:
StringSymbol {
  $$ = $1;
}|
String StringSymbol {
  $$ = cat3($1, newstr(" "), $2);
};

StringSymbol: ARTICLE                                { $$ = $1; }
            | BE                                     { $$ = $1; }
            | CHARACTER                              { $$ = $1; }
            | FIRST_PERSON                           { $$ = $1; }
            | FIRST_PERSON_POSSESSIVE                { $$ = $1; }
            | FIRST_PERSON_REFLEXIVE                 { $$ = $1; }
            | NEGATIVE_ADJECTIVE                     { $$ = $1; }
            | NEGATIVE_COMPARATIVE                   { $$ = $1; }
            | NEGATIVE_NOUN                          { $$ = $1; }
            | NEUTRAL_ADJECTIVE                      { $$ = $1; }
            | NEUTRAL_NOUN                           { $$ = $1; }
            | NOTHING                                { $$ = $1; }
            | POSITIVE_ADJECTIVE                     { $$ = $1; }
            | POSITIVE_COMPARATIVE                   { $$ = $1; }
            | POSITIVE_NOUN                          { $$ = $1; }
            | SECOND_PERSON                          { $$ = $1; }
            | SECOND_PERSON_POSSESSIVE               { $$ = $1; }
            | SECOND_PERSON_REFLEXIVE                { $$ = $1; }
            | THIRD_PERSON_POSSESSIVE                { $$ = $1; }

            | COMMA                                  { $$ = $1; }

            | AND                                    { $$ = $1; }
            | AS                                     { $$ = $1; }
            | ENTER                                  { $$ = $1; }
            | EXEUNT                                 { $$ = $1; }
            | EXIT                                   { $$ = $1; }
            | HEART                                  { $$ = $1; }
            | IF_NOT                                 { $$ = $1; }
            | IF_SO                                  { $$ = $1; }
            | LESS                                   { $$ = $1; }
            | LET_US                                 { $$ = $1; }
            | LISTEN_TO                              { $$ = $1; }
            | MIND                                   { $$ = $1; }
            | MORE                                   { $$ = $1; }
            | NOT                                    { $$ = $1; }
            | OPEN                                   { $$ = $1; }
            | PROCEED_TO                             { $$ = $1; }
            | RECALL                                 { $$ = $1; }
            | REMEMBER                               { $$ = $1; }
            | RETURN_TO                              { $$ = $1; }
            | SPEAK                                  { $$ = $1; }
            | THAN                                   { $$ = $1; }
            | THE_CUBE_OF                            { $$ = $1; }
            | THE_DIFFERENCE_BETWEEN                 { $$ = $1; }
            | THE_FACTORIAL_OF                       { $$ = $1; }
            | THE_PRODUCT_OF                         { $$ = $1; }
            | THE_QUOTIENT_BETWEEN                   { $$ = $1; }
            | THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN  { $$ = $1; }
            | THE_SQUARE_OF                          { $$ = $1; }
            | THE_SQUARE_ROOT_OF                     { $$ = $1; }
            | THE_SUM_OF                             { $$ = $1; }
            | TWICE                                  { $$ = $1; }
            | WE_MUST                                { $$ = $1; }
            | WE_SHALL                               { $$ = $1; }

            | ACT_ROMAN                              { $$ = $1; }
            | SCENE_ROMAN                            { $$ = $1; }
            | ROMAN_NUMBER                           { $$ = $1; }

            | NONMATCH                               { $$ = $1; }
            ;
Value:
CHARACTER {
  $$ = ($1)->num;
}|
Constant {
  $$ = $1;
}|
Pronoun {
  $$ = ($1) -> num;
}|
BinaryOperator Value AND Value {
     $$ = cat5($1.list[0], $2, $1.list[1], $4, $1.list[2]);
       free($1.list);
         free($3);
};

Constant:
ARTICLE UnarticulatedConstant {
  $$ = $2;
  free($1);
}|
FIRST_PERSON_POSSESSIVE UnarticulatedConstant {
  $$ = $2;
  free($1);
}|
SECOND_PERSON_POSSESSIVE UnarticulatedConstant {
  $$ = $2;
  free($1);
}|
THIRD_PERSON_POSSESSIVE UnarticulatedConstant {
  $$ = $2;
  free($1);
}|
NOTHING {
  $$ = 0;
  free($1);
};

Pronoun:
FIRST_PERSON {
   $$ = first_person;
}|
FIRST_PERSON_REFLEXIVE {
   $$ = first_person;
}|
SECOND_PERSON {
   $$ = second_person;
}|
SECOND_PERSON_REFLEXIVE {
   $$ = second_person;
};

UnarticulatedConstant:
PositiveConstant {
     $$ = $1;
}|
NegativeConstant {
     $$ = $1;
};

PositiveConstant:
PositiveNoun {
    $$ = 1;
    free($1);
}|
POSITIVE_ADJECTIVE PositiveConstant {
    $$ = 2*$2;
    free($1);
}|
NEUTRAL_ADJECTIVE PositiveConstant {
    $$ = 2*$2;
    free($1);
};

PositiveNoun:
NEUTRAL_NOUN {
     $$ = $1;
}|
POSITIVE_NOUN {
     $$ = $1;
};

NegativeConstant:
NegativeNoun {
    $$ = (-1);
    free($1);
}|
NEGATIVE_ADJECTIVE NegativeConstant {
    $$ = 2*$2;
    free($1);
}|
NEUTRAL_ADJECTIVE NegativeConstant {
    $$ = 2*$2;
    free($1);
};

NegativeNoun:
NEGATIVE_NOUN {
    $$ = $1;
};

BinaryOperator:
THE_DIFFERENCE_BETWEEN {
   $$ = "-";
   free($1);
}|
THE_PRODUCT_OF {
   $$ = "*";
   free($1);
}|
THE_QUOTIENT_BETWEEN {
   $$ = "/";
   free($1);
}|
THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN {
   $$ = "%";
   free($1);
}|
THE_SUM_OF {
   $$ = "+";
   free($1);
};

%%

void push(character * c, int i)
{
  STACKNODE *s = (STACKNODE *) malloc(sizeof(STACKNODE));
  if (!s) exit(ERROR_OUT_OF_MEM);
  s -> num = i;
  s -> next = c -> stack;
  c -> stack = s;
}

int pop(character * c)
{
  int i;
  STACKNODE *next;
  if (c->stack != NULL) {
    i = c->stack->num;
    next = c->stack->next;
    free(c->stack);
    c->stack = next;
    return i;
  }
  exit(ERROR_NO_STACK);
}

int int_input(void) {
  char buf[BUF_SIZE];
  long lval;

  fgets(buf, BUF_SIZE, stdin);

  errno = 0;
  lval = strtol(buf, NULL, 10);
  if (lval == 0) {
    switch (errno) {
    case EINVAL:
      report_error("heart whispered something that was not a valid integer.");
      break;
    case ERANGE:
      report_error("heart whispered an integer that was way out of range.");
      break;
    default:
      break;
    }
  }

  if (lval < INT_MIN || lval > INT_MAX) {
    report_error("heart whispered an integer that was out of range.");
  }

  return (int) lval;
}

int yyerror(char *s)
{
  /* Don't do anything special here. */
  return 0;
}

void report_error(const char *expected_symbol)
{
  fprintf(stderr, "Error at line %d: %s\n", yylineno, expected_symbol);
  exit(1);
}

void report_warning(const char *expected_symbol)
{
  fprintf(stderr, "Warning at line %d: %s expected\n", yylineno, expected_symbol);
  num_warnings++;
}

void initialize_character(const char *name)
{
	character *c = (character*)malloc(sizeof(character));
  c->num       = 0;
  c->stack     = NULL;
	g_hash_table_insert(CHARACTERS, name, c);
}

character *get_character(const char *name)
{
  character *c = g_hash_table_lookup(CHARACTERS, name);
  if (!c) report_error(strcat(name, " does not exist"));
  return c;
}

void enter_stage(CHARACTERLIST *c)
{
  if (!ON_STAGE)
    ON_STAGE = g_hash_table_new(g_str_hash, g_str_equal);

  CHARACTERLIST *curr;
  while (c != NULL) {
    curr = c;
    g_hash_table_insert(ON_STAGE, curr->name, get_character(curr->name));
    c = c->next;
    free(curr);
    
  }
}

void exit_stage(CHARACTERLIST *c)
{
  CHARACTERLIST *curr;
  while(c != NULL) {
    curr = c;
    g_hash_table_remove(ON_STAGE, curr->name);
    c = c->next;
    free(curr);
  }
}

void exeunt_stage(void)
{
  g_hash_table_destroy(ON_STAGE);
}

bool is_on_stage(const char *name)
{
  return !g_hash_table_lookup(ON_STAGE, name);
}

void activate_character(const char *name)
{
  GList *names;
  if (!is_on_stage(name)) report_error(strcat(name, " is not on stage."));
  first_person = name;
  if (num_on_stage == 2) {
    names = g_hash_table_get_keys(ON_STAGE);
    
  }
}
  
int main(void)
{
  CHARACTERS = g_hash_table_new(g_str_hash, g_str_equal);
  ON_STAGE   = g_hash_table_new(g_str_hash, g_str_equal);
#if(YYDEBUG == 1)
  yydebug = 1;
#endif
  if (yyparse() == 0) {
    if (num_errors > 0) {
      fprintf(stderr, "%d errors and %d warnings found. No code output.\n", num_errors, num_warnings);
      exit(1);
    } else if (num_warnings > 0) {
      fprintf(stderr, "%d warnings found. Code may be defective.\n", num_warnings);
    }
  } else {
      fprintf(stderr, "Unrecognized error encountered. No code output.\n");
      exit(1);
  }
  return 0;
}
