%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
/* Global stack */
size_t stack_size = 0;
size_t stack_length = 0;
char **stack = NULL;
/* Function prototypes */
void push(const char *);
void do_message(const char *);
void *xmalloc(size_t);
void *xrealloc(void *, size_t);
%}

/*These (flex-only) avoid GCC warnings in the generated code.
  Removing them will not break anything.
*/
%option nounput
%option always-interactive

%%

^#.+$                                         ; /* ignore comments */
\/[^\/]*\/|'[^']*'|\"[^\"]*\"                 { push(yytext);       }
:[^ \t\r\n\(\)]+|[^0-9a-zA-Z \t\r\n\(\)]+     { do_message(yytext); }
[^ \t\r\n\(\)]+                               { push(yytext);       }
[ \t\r\n\(\)]                                 ; /* ignore whitespace */

%%
/* Push a string onto the global stack */
void push(const char *item) {
	char *s;
	if(item[0] == '\'') { /* symbol, prepend ':' */
		s = xmalloc((strlen(item)+1+1)*sizeof(*s));
		s[0] = ':';
		s[1] = '\0';
	} else {
		s = xmalloc((strlen(item)+1)*sizeof(*s));
		s[0] = '\0';
	}
	strcat(s, item);
	if(stack_length == stack_size) { /* Stack is full, enlarge */
		stack_size = (stack_size+1)*2;
		stack = xrealloc(stack, stack_size*sizeof(*stack));
	}
	stack[stack_length++] = s; /* Push s on as new last element */
}

/* Pop element off the global stack */
char *pop() {
	return stack[--stack_length];
}

/* Process a "message" by popping top two elements and pushing the result */
void do_message(const char *message) {
	char *arg,*obj;
	if(stack_length < 2) {
		fputs("Syntax error.\n", stderr);
		exit(EXIT_FAILURE);
	}
	arg = pop();
	obj = pop();
	if(strcmp(message, "=") == 0 || strcmp(message, ":=") == 0) { /* Assignment (special case) */
		obj = xrealloc(obj, (strlen(obj)+strlen("=()")+strlen(arg)+1)*sizeof(*obj));
		strcat(obj, "=(");
		strcat(obj, arg);
		strcat(obj, ")");
		push(obj);
	} else if(strcmp(message, ":lambda") == 0) { /* Lambda (special case) */
		if(obj[0] == ':') { /* Handle case where arguments are a symbol and push() has prepended : */
			obj[1] = '|';
		} else {
			obj[0] = '|';
		}
		obj[strlen(obj)-1] = '|';
		obj = xrealloc(obj, (strlen(obj)+strlen("lambda{ }")+strlen(arg)+1)*sizeof(*obj));
		memmove(obj+strlen("lambda{")-(obj[0] == ':'), obj, (strlen(obj)+1)*sizeof(*obj));
		strcpy(obj, "lambda");
		obj[6] = '{';
		strcat(obj, " ");
		strcat(obj, arg);
		strcat(obj, "}");
		push(obj);
	} else {
		obj = xrealloc(obj, (strlen(obj)+strlen("().magic_send(,())")+strlen(":''")+strlen(message)+strlen(arg)+1)*sizeof(*obj));
		memmove(obj+1, obj, (strlen(obj)+1)*sizeof(*obj));
		obj[0] = '(';
		strcat(obj, ").magic_send(");
		if(message[0] != ':') strcat(obj, ":'");
		strcat(obj, message);
		if(message[0] != ':') strcat(obj, "'");
		strcat(obj, ",(");
		strcat(obj, arg);
		strcat(obj, "))");
		free(arg);
		push(obj);
	}
}

int yywrap() { return 1; }

void *xmalloc(size_t sz) {
	void *ret = malloc(sz);
	if(ret == NULL) {
		perror("malloc");
		abort();
	}
	return ret;
}

void *xrealloc(void *p, size_t sz) {
	void *ret = realloc(p, sz);
	if(ret == NULL) {
		perror("realloc");
		abort();
	}
	return ret;
}

int main(void) {
	int r;
	size_t i;
	if((r = yylex())) {
		fputs("A lexing error occured.  Check your input.\n", stderr);
		return r;
	}
	puts("#!/usr/bin/ruby");
	puts("require 'rpnr-runtime'");
	for(i = 0; i < stack_length; i++) {
		puts(stack[i]);
		free(stack[i]);
	}
	free(stack);
	return r;
}
