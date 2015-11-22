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

typedef struct CHARACTERLIST {
  char *name;
  struct CHARACTERLIST *next;
} CHARACTERLIST;

/* Local function prototypes */
static void report_error(const char *expected_symbol);
static void report_warning(const char *expected_symbol);
void initialize_character(const char *name);
character *get_character(const char *name);
void activate_character(const char *name);
void enter_stage(CHARACTERLIST *c);
void exit_stage(CHARACTERLIST *c);
void exeunt_stage(void);
bool is_on_stage(const char *name);
#endif
