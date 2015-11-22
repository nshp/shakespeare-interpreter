#ifndef HELPER_H
#define HELPER_H

/* Typedefs */
#define bool int
typedef struct _STACKNODE STACKNODE;
struct _STACKNODE {
	int num;
	STACKNODE *next;
};

typedef struct {
	int num;
	STACKNODE *stack;
} character;

typedef struct _CHARACTERLIST CHARACTERLIST;
struct _CHARACTERLIST {
  char *name;
  CHARACTERLIST *next;
};

/* Local function prototypes */
static void report_error(const char *expected_symbol);
static void report_warning(const char *expected_symbol);
void initialize_character(const char *name);
character *get_character(const char *name);
void enter_stage(CHARACTERLIST *c);
void exit_stage(CHARACTERLIST *c);
void exeunt_stage(void);

#endif
