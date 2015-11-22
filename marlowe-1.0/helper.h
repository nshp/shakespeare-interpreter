#ifndef HELPER_H
#define HELPER_H

/* Typedefs */
#define bool int
typedef struct STACKNODE {
	int num;
	struct STACKNODE *next;
} STACKNODE;

typedef struct CHARACTER {
	int num;
	STACKNODE *stack;
} character;

typedef struct CHARACTERLIST {
  char *name;
  struct CHARACTERLIST *next;
} CHARACTERLIST;

typedef struct SCENE {
  int    num;
  char  *code;
  struct SCENE *next;
  struct SCENE *prev;
} SCENE;

typedef struct ACT {
  int num;
  SCENE *scenes;
  struct ACT *next;
  struct ACT *prev;
} ACT;

/* Local function prototypes */
static void report_error(const char *expected_symbol);
static void report_warning(const char *expected_symbol);
void initialize_character(const char *name);
character *get_character(const char *name);
void push(character * c, int i);
int pop(character * c);
void activate_character(const char *name);
void enter_stage(CHARACTERLIST *c);
void exit_stage(CHARACTERLIST *c);
void exeunt_stage(void);
bool is_on_stage(const char *name);

#endif
