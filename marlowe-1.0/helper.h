#ifndef HELPER_H
#define HELPER_H

/* Typedefs */
#define bool int
typedef struct _STACKNODE STACKNODE;
struct _STACKNODE {
	int num;
	STACKNODE *next;
};

typedef struct CHARACTER {
	int num;
	STACKNODE *stack;
} character;

typedef struct CHARACTERLIST {
  char *name;
  struct CHARACTERLIST *next;
} CHARACTERLIST;

typedef struct _SCENE SCENE;
typedef struct _SCENE {
  int    num;
  char  *code;
  SCENE *next;
  SCENE *prev;
};

typedef struct _ACT ACT;
typedef struct _ACT {
  int num;
  SCENE *scenes;
  ACT   *next;
  ACT   *prev;
};

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
