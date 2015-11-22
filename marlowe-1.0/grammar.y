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
#include <string.h>

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
static GHashTable *CHARACTERS;
static GHashTable *ON_STAGE;
static char *current_act         = NULL;
static char *current_scene       = NULL;
static character *first_person   = NULL;
static character *second_person  = NULL;
static unsigned int num_on_stage = 0;
static int comp1;
static int comp2;
%}

%union {
  char *str;
  int num;
  struct {
    int num;
    char **list;
  } stringlist;
  struct CHARACTERLIST *charlist;
  struct CHARACTER *c;
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


/*%type <char>  CharacterDeclaration */
/*%type <charlist>   CharacterDeclarationList*/
%type <charlist> CharacterList
%type <str>        Comment
%type <str>        EnterExit
%type <str>        StatementSymbol
%type <str>        String
%type <str>        StringSymbol
%type <num>        Value
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
%type <c>          Pronoun
%type <num>        BinaryOperator
%type <num>        UnaryOperator
%type <num>        Equality
%type <num>        Conditional
%type <str>        Adjective
%type <str>        Title
%type <num>        NonnegatedComparison
%type <num>        Question
%type <num>        Comparison
%type <num>        Comparative
%type <num>        Inequality

%start Play

%%

Act: ActHeader Scene | Act Scene;

ActHeader: ACT_ROMAN COLON Comment EndSymbol {
  free($2);
  free($4);
}|
ACT_ROMAN COLON Comment error {
  report_warning("period or exclamation mark");
  free($2);
}|
ACT_ROMAN error Comment EndSymbol {
  report_warning("colon");
  free($4);
};

Play:
Title CharacterDeclarationList Act {
  //free($2.list);
}|
Play Act |
Title CharacterDeclarationList error {
  report_error("act");
  /*
  free($2.list[0]);
  free($2.list[1]);
  free($2.list);
  */
}|
Title error Act {
  report_error("character declaration list");
  free($1);
}|
error CharacterDeclarationList Act {
  report_warning("title");
  //free($2.list);
};

Scene: SceneHeader SceneContents;

SceneContents:  Line | EnterExit | SceneContents Line | SceneContents EnterExit;
SceneHeader:
SCENE_ROMAN COLON Comment EndSymbol |
SCENE_ROMAN COLON Comment error {
  report_warning("period or exclamation mark expected.");
}|
SCENE_ROMAN error Comment EndSymbol {
  report_warning("colon expected.");
};

Title:
String EndSymbol {
// TODO: put this somewhere?
  $$ = $1;
  free($2);
};

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

CharacterColon:
CHARACTER COLON {
  activate_character($1);
  free($2);
};

Line:
CharacterColon SentenceList {
}|
CharacterColon error {
  report_error("sentence list");
}|
CHARACTER error SentenceList {
  report_error("colon");
  free($1);
};

InOut:
OpenYour HEART StatementSymbol {
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
  assign_value(second_person, int_input());
  free($1);
  free($2);
  free($3);
  free($4);
}|
OpenYour MIND StatementSymbol {
  assign_value(second_person, getc(stdin));
  if (second_person->num == EOF) {
    assign_value(second_person, -1);
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
  assign_value(second_person, int_input());
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
  assign_value(second_person, int_input());
  free($1);
  free($2);
  free($4);
}|
OpenYour HEART error {
  report_warning("period or exclamation mark");
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
  assign_value(second_person->num, int_input());
  free($1);
  free($2);
  free($3);
}|
OpenYour MIND error {
  report_warning("period or exclamation mark");
  assign_value(second_person->num, getc(stdin));
  if (second_person->num == EOF) {
    assign_value(second_person->num, -1);
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
UnconditionalSentence: InOut | Recall | Remember | Statement;

/* TODO */
Sentence: UnconditionalSentence;

Conditional:
IF_SO {
  $$ = truth_flag;
  free($1);
}|
IF_NOT {
  truth_flag = !truth_flag;
  $$ = truth_flag;
  free($1);
};

EnterCharacter:
ENTER CHARACTER {
  CHARACTERLIST * c = malloc(sizeof(CHARACTERLIST));
  c -> name = $2;
  c -> next = NULL;

  enter_stage(c);
  free($1);
};

EnterCharacters:
ENTER CharacterList {
  enter_stage($2);
  free($1);
};

EnterExit:
LEFT_BRACKET EnterCharacter RIGHT_BRACKET {
  free($1);
  free($3);
}|
LEFT_BRACKET EnterCharacters RIGHT_BRACKET {
  free($1);
  free($3);
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
  report_error("[Enter <string>] requires either a character or a character list");

  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXIT error RIGHT_BRACKET {
  report_error("[Exit <string>] requires a character");

  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXEUNT error RIGHT_BRACKET {
  report_error("[Exeunt <string>] requires character list or nothing");

  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET error RIGHT_BRACKET {
  report_error("[<string>] requires either 'enter', 'exit' or 'exeunt'");

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
  $$ = get_character($1) -> num;
}|
Constant {
  $$ = $1;
}|
Pronoun {
  $$ = ($1) -> num;
}|
BinaryOperator Value AND Value {
   if($1 == 0)
   {
      $$ = $2 + $4;
   }
   else if($1 == 1)
   {
      $$ = $2 - $4;
   }
   else if($1 == 2)
   {
      $$ = $2 * $4;
   }
   else if($1 == 3)
   {
      if($4 == 0)
      {
         report_error("Integer division by zero");
      }
      $$ = $2 / $4;
   }
   else if($1 == 4)
   {
      if($4 == 0)
      {
         report_error("Integer division by zero");
      }
      $$ = $2 % $4;
   }
   free($3);
}|
UnaryOperator Value {
   if($1 == 0)
   {
      $$ = $2 * 2;
   }
   else if($1 == 1)
   {
      $$ = $2 * $2;
   }
   else if($1 == 2)
   {
      $$ = $2 * $2 * $2;
   }
   else if($1 == 3)
   {
      if($2 < 0)
      {
         report_error("Negative square root");
      }
      // TODO: Add sqrt function
      $$ = 0;
   }
   else if($1 == 4)
   {
      if($2 < 0)
      {
         report_error("Negative factorial");
      }
      // TODO: Add factorial function
      $$ = 0;
   } 
}|
BinaryOperator Value AND error {
     report_error("First value in binary operation is invalid");
}|
BinaryOperator Value error Value {
     report_warning("Invalid 'and' between values for binary operation");
}|
BinaryOperator error AND Value {
  report_error("First value in binary operation is invalid");
}|
UnaryOperator error {
report_error("Unary operators require a value");
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
 $$ = -1;
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
   $$ = 1;
   free($1);
}|
THE_PRODUCT_OF {
   $$ = 2;
   free($1);
}|
THE_QUOTIENT_BETWEEN {
   $$ = 3;
   free($1);
}|
THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN {
   $$ = 4;
   free($1);
}|
THE_SUM_OF {
   $$ = 0;
   free($1);
};

UnaryOperator:
THE_CUBE_OF {
   $$ = 2;
   free($1);
}|
THE_FACTORIAL_OF {
   $$ = 4;
   free($1);
}|
THE_SQUARE_OF {
   $$ = 1;
   free($1);
}|
THE_SQUARE_ROOT_OF {
   $$ = 3;
   free($1);
}|
TWICE {
   $$ = 0;
   free($1);
};

Statement:
SECOND_PERSON BE Constant StatementSymbol {
  assign_value(second_person, $3);
  free($1);
  free($2);
  free($4);
}|
SECOND_PERSON UnarticulatedConstant StatementSymbol {
  assign_value(second_person, $2);
  free($1);
  free($3);
}|
SECOND_PERSON BE Equality Value StatementSymbol {
  assign_value(second_person, $4);
  free($1);
  free($2);
  free($5);
}|
SECOND_PERSON BE Constant error {
  report_warning("Value statements require line ending character");
  assign_value(second_person, $3);
  free($1);
  free($2);
}|
SECOND_PERSON BE error StatementSymbol {
  report_error("Value statements require a value");

  free($1);
  free($2);
  free($4);
}|
SECOND_PERSON error Constant StatementSymbol {
  report_warning("Value statements require a 'be' word");

  assign_value(second_person, $3);

  free($1);
  free($4);
}|
SECOND_PERSON UnarticulatedConstant error {
  report_warning("Value statements require line ending character");

  assign_value(second_person, $2);

  free($1);
}|
SECOND_PERSON error StatementSymbol {
  report_error("Value statements require a 'be' word");

  free($1);
  free($3);
}|
SECOND_PERSON BE Equality Value error {
  report_warning("Value statements require line ending character");

  assign_value(second_person, $4);

  free($1);
  free($2);
  free($3);
}|
SECOND_PERSON BE Equality error StatementSymbol {
  report_error("Value statements require a value");

  free($1);
  free($2);
  free($3);
  free($5);
}|
SECOND_PERSON BE error Value StatementSymbol {
  report_warning("Value statements require a word that indicates equality");

  assign_value(second_person, $4);

  free($1);
  free($2);
  free($5);
}|
SECOND_PERSON error Equality Value StatementSymbol {
  report_warning("Value statements require a 'be' word");

  assign_value(second_person, $3);

  free($1);
  free($3);
  free($5);
};

Equality:
AS Adjective AS {
   $$ = (comp1 == comp2);

   free($1);
   free($2);
   free($3);
}|
AS error AS {
   report_error("Equality requires an adjective.");
}|
AS Adjective error {
   report_error("Equality requires second 'as'");
}|
error Adjective AS {
   report_error("Equality requires first 'as'");
};

Question:
BE Value Comparison Value QuestionSymbol {

   comp1 = $2;
   comp2 = $4;

   $$ = $3;

  free($1);
  free($5);
}|
BE error Comparison Value QuestionSymbol {
  report_error("value");
}|
BE Value error Value QuestionSymbol {
  report_error("comparison");
}|
BE Value Comparison error QuestionSymbol {
  report_error("value");
};

Comparison:
NOT NonnegatedComparison {
  $$ = (!$2);
  free($1);
}|
NonnegatedComparison {
  $$ = $1;
};

NonnegatedComparison:
Equality {
  $$ = $1;
}|
Inequality {
  $$ = $1;
};

Inequality:
Comparative THAN {
  $$ = $1;
  free($2);
}|
Comparative error {
  report_warning("Comparative statements require a 'than' statement");
  $$ = $1;
};

Comparative:
NegativeComparative {
  $$ = comp1 < comp2;
}|
PositiveComparative {
  $$ = comp1 > comp2;
};

PositiveComparative:
POSITIVE_COMPARATIVE
|
MORE POSITIVE_ADJECTIVE
|
LESS NEGATIVE_ADJECTIVE
;

NegativeComparative:
NEGATIVE_COMPARATIVE
|
MORE NEGATIVE_ADJECTIVE
|
LESS POSITIVE_ADJECTIVE
;

Adjective:
POSITIVE_ADJECTIVE {
  $$ = $1;
}|
NEUTRAL_ADJECTIVE {
  $$ = $1;
}|
NEGATIVE_ADJECTIVE {
  $$ = $1;
};


%%

void push(character * c, int i)
{
#ifdef DEBUG
  fprintf(stderr, "Pushing %d onto %s's stack.\n", i, c->name);
#endif
  STACKNODE *s = (STACKNODE *) malloc(sizeof(STACKNODE));
  if (!s) report_error("unable to allocate stack for character.");
  s -> num = i;
  s -> next = c -> stack;
  c -> stack = s;
}

int pop(character * c)
{
#ifdef DEBUG
  fprintf(stderr, "Attempting to pop a value off of %s's stack.\n", c->name);
#endif
  int i;
  STACKNODE *next;
  if (c->stack != NULL) {
    i = c->stack->num;
    next = c->stack->next;
    free(c->stack);
    c->stack = next;
    return i;
  }
  report_error("character has no stack.");
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
#ifdef DEBUG
  GList *names = g_hash_table_get_keys(CHARACTERS);
  GList *stage = g_hash_table_get_keys(ON_STAGE);
  while(names != NULL) {
    fprintf(stderr, "\t%s exists.\n", (char*)names->data);
    names = names->next;
  }
  fprintf(stderr, "Actors on the stage:\n");
  while(stage != NULL) {
    fprintf(stderr, "\t%s is on the stage.\n", (char*)stage->data);
    stage = stage->next;
  }
#endif
  exit(1);
}

void report_warning(const char *expected_symbol)
{
  fprintf(stderr, "Warning at line %d: %s expected\n", yylineno, expected_symbol);
}

void initialize_character(const char *name)
{
#ifdef DEBUG
  fprintf(stderr, "Initializing %s.\n", name);
#endif
	character *c = (character*)malloc(sizeof(character));
  c->num       = 0;
  c->stack     = NULL;
  c->name      = name;
	g_hash_table_insert(CHARACTERS, name, c);
}

character *get_character(const char *name)
{
#ifdef DEBUG
  fprintf(stderr, "Getting %s from the hash table.\n", name);
#endif
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
#ifdef DEBUG
    fprintf(stderr,"%s has entered the stage.\n", curr->name);
#endif
    g_hash_table_insert(ON_STAGE, curr->name, get_character(curr->name));
    c = c->next;
    free(curr);
  }
  num_on_stage = g_hash_table_size(ON_STAGE);
}

void exit_stage(CHARACTERLIST *c)
{
  CHARACTERLIST *curr;
  while(c != NULL) {
    curr = c;
#ifdef DEBUG
    fprintf(stderr,"%s has left the stage.\n", curr->name);
#endif
    g_hash_table_remove(ON_STAGE, curr->name);
    c = c->next;
    free(curr);
  }
  num_on_stage = g_hash_table_size(ON_STAGE);
}

void exeunt_stage(void)
{
#ifdef DEBUG
  fprintf(stderr, "Clearing the stage.\n");
#endif
  g_hash_table_destroy(ON_STAGE);
  ON_STAGE      = NULL;
  first_person  = NULL;
  second_person = NULL;
}

bool is_on_stage(const char *name)
{
  return (bool)g_hash_table_contains(ON_STAGE, name);
}

void activate_character(const char *name)
{
  GList *names;
#ifdef DEBUG
  fprintf(stderr, "Activating characters.\n");
#endif
  if (!is_on_stage(name)) report_error(strcat(name, " is not on stage."));
  first_person = name;
  if (num_on_stage == 2) {
    names = g_hash_table_get_keys(ON_STAGE);
    while(names != NULL) {
      if (strcmp((char*)names->data, name))
        second_person = get_character((char*)names->data);
      names = names->next;
    }
    if (!second_person) report_error("no second person on stage, yet 2 characters exist.");
  }
}

void assign_value(character *c, int num)
{
#ifdef DEBUG
  fprintf(stderr, "Attempting to assign %d to %s\n", num, c->name);
#endif
  if (!c) report_error("Tried to assign value to non-existent character.");
  c->num = num;
#ifdef DEBUG
  fprintf(stderr, "%s now has value %d\n", c->name, c->num);
#endif
}

int main(int argc, char **argv)
{
  CHARACTERS = g_hash_table_new(g_str_hash, g_str_equal);
  ON_STAGE   = g_hash_table_new(g_str_hash, g_str_equal);
#if(YYDEBUG == 1)
  yydebug = 1;
#endif
  if (argc > 1)
    yyin = fopen(argv[1],"r");
  else
    yyin = stdin;
  if (yyparse()) {
      fprintf(stderr, "Unrecognized error encountered. No code output.\n");
      exit(1);
  }
  return 0;
}
