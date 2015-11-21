/***********************************************************************

SPL, the Shakespeare Programming Language

Copyright (C) 2001 Karl Hasselström and Jon Åslund

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
#include <stdio.h>
#include <stdlib.h>

#include <libspl.c>
#include <spl.h>  
#include "strutils.h"
#include "telma.h"

#define COMMENT_COLUMN   40  // 
#define INDENTATION_SIZE 2   // number of spaces to indent output C code

/* macro to create indentation space */
#define INDENT (strpad(newstr(""), INDENTATION_SIZE, ' '))

/* Local function prototypes */
static void report_error(const char *expected_symbol);
static void report_warning(const char *expected_symbol);

/* Global variables local to this file */
static char *current_act = NULL;
static char *current_scene = NULL;
static int num_errors = 0;           // error counter
static int num_warnings = 0;         // warning counter
static int i;                        // all-purpose counter
static bool truth_flag;
static int comp1;
static int comp2;
%}

%union {
  char *str;
  char chr;
  int num;
  bool boolean;
  CHARACTER* character;
  CHARACTER** charlist;
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


%type <str>        Act
%type <str>        ActHeader
%type <str>        Adjective
%type <chr>        BinaryOperator
%type <character>  CharacterDeclaration
%type <charlist>   CharacterDeclarationList
%type <stringlist> CharacterList
%type <str>        Comment
%type <str>        Comparative
%type <boolean>    Comparison
%type <boolean>    Conditional
%type <num>        Constant
%type <str>        EndSymbol
%type <str>        EnterExit
%type <boolean>    Equality
%type <boolean>    Inequality
%type <str>        InOut
%type <str>        Jump
%type <str>        JumpPhrase
%type <str>        JumpPhraseBeginning
%type <str>        JumpPhraseEnd
%type <str>        Line
%type <str>        NegativeComparative
%type <num>        NegativeConstant
%type <num>        NegativeNoun
%type <str>        NonnegatedComparison
%type <str>        OpenYour
%type <str>        Play
%type <str>        PositiveComparative
%type <num>        PositiveConstant
%type <num>        PositiveNoun
%type <str>        Pronoun
%type <str>        Question
%type <str>        QuestionSymbol
%type <str>        Recall
%type <str>        Remember
%type <str>        Scene
%type <str>        SceneContents
%type <str>        SceneHeader
%type <str>        Sentence
%type <str>        SentenceList
%type <str>        StartSymbol
%type <str>        Statement
%type <str>        StatementSymbol
%type <str>        String
%type <str>        StringSymbol
%type <data>       Title
%type <num>        UnarticulatedConstant
%type <num>        UnaryOperator
%type <str>        UnconditionalSentence
%type <num>        Value


%start StartSymbol

%%

CharacterDeclaration:
CHARACTER COMMA Comment EndSymbol {
  $$ = initialize_character($1);
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
  $$ = (CHARACTER **) malloc(sizeof(CHARACTER **));
  $$[0] = $1;
}|
CharacterDeclarationList CharacterDeclaration {
  $$ = (CHARACTER **) malloc(sizeof($1)+sizeof(CHARACTER**));
  
  int i;

  for(i = 0; i < sizeof($1) / sizeof(CHARACTER**); i++)
  {
    $$[i] = $1[i];
  }

  $$[i] = $2;

  free($2.list);
};

CharacterList:
CHARACTER AND CHARACTER {
  $$.list = (char **) malloc(2*sizeof(char **));
  $$.list[0] = $1;
  $$.list[1] = $3;
  $$.num = 2;
  free($2);
}|
CHARACTER COMMA CharacterList {
  $$.num = $3.num + 1;
  $$.list = realloc($3.list, $$.num*sizeof(char **));
  $$.list[$$.num - 1] = $1;
  free($2);
};

Comment:
String {
  $$ = cat3(newstr("/* "), $1, newstr(" */"));
}|
error {
  report_warning("comment");
  $$ = newstr("/* NO COMMENT FOUND */");
};

EnterExit:
LEFT_BRACKET ENTER CHARACTER RIGHT_BRACKET {
  $$ = cat5(newstr("\nenter_scene("), int2str(yylineno), newstr(", "), str2varname($3), newstr(");\n"));
  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET ENTER CharacterList RIGHT_BRACKET {
  $$ = newstr("\n");
  for (i = 0; i < $3.num; i++) {
    $$ = cat6($$, newstr("enter_scene("), int2str(yylineno), newstr(", "),
	      str2varname($3.list[i]), newstr(");\n"));
  }
  free($3.list);
  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXIT CHARACTER RIGHT_BRACKET {
  $$ = cat5(newstr("\nexit_scene("), int2str(yylineno), newstr(", "), str2varname($3), newstr(");\n"));
  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXEUNT CharacterList RIGHT_BRACKET {
  $$ = newstr("\n");
  for (i = 0; i < $3.num; i++) {
    $$ = cat6($$, newstr("exit_scene("), int2str(yylineno), newstr(", "),
	      str2varname($3.list[i]), newstr(");\n"));
  }
  free($3.list);
  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXEUNT RIGHT_BRACKET {
  $$ = cat3(newstr("\nexit_scene_all("), int2str(yylineno), newstr(");\n"));
  free($1);
  free($2);
  free($3);
}|
LEFT_BRACKET ENTER error RIGHT_BRACKET {
  report_error("character or character list");
  $$ = newstr("");
  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXIT error RIGHT_BRACKET {
  report_error("character");
  $$ = newstr("");
  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET EXEUNT error RIGHT_BRACKET {
  report_error("character list or nothing");
  $$ = newstr("");
  free($1);
  free($2);
  free($4);
}|
LEFT_BRACKET error RIGHT_BRACKET {
  report_error("'enter', 'exit' or 'exeunt'");
  $$ = newstr("");
  free($1);
  free($3);
};

Line:
CHARACTER COLON SentenceList {
  $$ = cat6(newstr("\nactivate_character("), int2str(yylineno), newstr(", "), str2varname($1),
	    newstr(");\n"), $3);
  free($2);
}|
CHARACTER COLON error {
  report_error("sentence list");
  $$ = newstr("");
  free($1);
  free($2);
}|
CHARACTER error SentenceList {
  report_error("colon");
  $$ = newstr("");
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
  $$ = cat2(str2varname($1), newstr("->value"));
};

%%

int yyerror(char *s)
{
  /* Don't do anything special here. */
  return 0;
}

void report_error(const char *expected_symbol)
{
  fprintf(stderr, "Error at line %d: %s expected\n", yylineno, expected_symbol);
  num_errors++;
}

void report_warning(const char *expected_symbol)
{
  fprintf(stderr, "Warning at line %d: %s expected\n", yylineno, expected_symbol);
  num_warnings++;
}

int main(void)
{
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
