#ifndef HELPER_H
#define HELPER_H

typedef struct _STACKNODE STACKNODE;
struct _STACKNODE {
	int num;
	STACKNODE *next;
};

typedef struct {
	int num;
	STACKNODE *stack;
} character;

#endif
