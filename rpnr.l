%{
#include <stdio.h>
#include <stdlib.h>
#define HANDLE_FATAL(x) do { if(!(x)) { fputs("A fatal error occured.\n", stderr); abort(); } } while (0) /* Simple error handling */
/* Global stack */
size_t stack_size = 0;
size_t stack_length = 0;
char **stack = NULL;
/* Function prototypes */
void push(const char *);
void do_message(const char *);
%}
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
		HANDLE_FATAL(s = malloc((strlen(item)+1+1)*sizeof(*s)));
		s[0] = ':';
		s[1] = '\0';
	} else {
		HANDLE_FATAL(s = malloc((strlen(item)+1)*sizeof(*s)));
		s[0] = '\0';
	}
	strcat(s, item);
	if(stack_length == stack_size) { /* Stack is full, enlarge */
		stack_size = (stack_size+1)*2;
		HANDLE_FATAL(stack = realloc(stack, stack_size*sizeof(*stack)));
	}
	stack[stack_length++] = s; /* Push s on as new last element */
}

/* Pop element off the global stack */
char *pop() {
	return stack[--stack_length];
}

/* Process a "message" by popping top two elements and pushing the result */
void do_message(const char *message) {
	if(stack_length < 2) {
		fputs("Syntax error.\n", stderr);
		exit(EXIT_FAILURE);
	}
	char *arg = pop();
	char *obj = pop();
	if(strcmp(message, "=") == 0 || strcmp(message, ":=") == 0) { /* Assignment (special case) */
		HANDLE_FATAL(obj = realloc(obj, (strlen(obj)+strlen("=()")+strlen(arg)+1)*sizeof(*obj)));
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
		HANDLE_FATAL(obj = realloc(obj, (strlen(obj)+strlen("lambda{ }")+strlen(arg)+1)*sizeof(*obj)));
		memmove(obj+strlen("lambda{")-(obj[0] == ':'), obj, strlen(obj));
		strcpy(obj, "lambda");
		obj[6] = '{';
		strcat(obj, " ");
		strcat(obj, arg);
		strcat(obj, "}");
		push(obj);
	} else {
		HANDLE_FATAL(obj = realloc(obj, (strlen(obj)+strlen("().magic_send(,())")+strlen(":''")+strlen(message)+strlen(arg)+1)*sizeof(*obj)));
		memmove(obj+1, obj, strlen(obj));
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
