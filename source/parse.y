%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdbool.h>

// symbol table
#include "../include/symtab/symtab.h"

// for logging
#include <time.h>


/* ------ Function declaration ------ */
int yylex(void);
void yyerror(char*);
extern FILE* yyin;


/* ------ Auxiliar function declaration ------ */
void print_iden(char*, atributs);
void print_expr(atributs);
bool is_numeric(atributs, atributs);
bool is_string(atributs, atributs);
bool is_bool(atributs, atributs);
int num_types(atributs, atributs);


/* ------ Auxiliar variables ------ */
FILE* fp; // pointer to the log file created each execution
int line = 1; // run-time line counter
atributs aux;
char* name;
bool err; // error flag


//TODO: check if logs can get types and operations 
%}


%union{
  //int type;
  atributs attrs;
}


%token T_INT T_FLOAT T_STRING T_IDEN T_BOOL

%token ASSIG

%token SYM_OB SYM_CB

%token OP_ADD OP_SUB OP_MUL OP_DIV OP_MOD OP_POW

%token OP_LT OP_LE OP_GT OP_GE OP_EQ OP_INEQ 

%token BOOL_OP_NOT BOOL_OP_AND BOOL_OP_OR

%token CONST_PI

%token EOL CMD_EXIT

 
%type<attrs> T_INT T_FLOAT T_STRING T_IDEN T_BOOL assignment factor pow unary term arith relexpr bool_not bool_and expr statement line 

%%

start: 
     | start line
;

line: EOL 				{ line++; err = false; }
    | statement EOL 			{ line++; err = false; }
    | CMD_EXIT				{ exit(0); }
;

statement: expr				{ if(!err) print_expr($1); }
	 | assignment			{ if(!err) print_iden(name, $1); }
;

expr: bool_and				{ $$ = $1; }
    | expr BOOL_OP_OR bool_and		{	if(!err){ 
							bool res = is_bool($1, $3);
							if(res && ($1.type == $3.type)){
								$$.boolean = $1.boolean || $3.boolean ? true : false;
								$$.type = 3;

								fprintf(fp, "%s reduced by the rule: expr -> expr || bool_and\n", $$.boolean ? "true" : "false");
							}
							else{
								yyerror("semantic error: cannot compute logical and on non-boolean values");
								err = true;
							}
						}
    					}
;

bool_and: bool_not			{ $$ = $1; }
	| bool_and BOOL_OP_AND bool_not	{ 	if(!err){
							bool res = is_bool($1, $3);
							if(res && ($1.type == $3.type)){
								$$.boolean = $1.boolean && $3.boolean ? true : false;
								$$.type = 3;

								fprintf(fp, "%s reduced by the rule: bool_and -> bool_and && bool_not\n", $$.boolean ? "true" : "false");
						}
							else{
								yyerror("semantic error: cannot compute logical and on non-boolean values");
								err = true;
							}
						}
 					}
;
	
bool_not: BOOL_OP_NOT relexpr		{ 	if(!err){
							if($2.type == 3){
								$$.boolean = $2.boolean ? false : true;
								$$.type = 3;

								fprintf(fp, "%s reduced by the rule: bool_not -> ! relexpr\n", $$.boolean ? "true" : "false");
							}
							else{
								yyerror("semantic error: cannot compute logical not on non-boolean values");
								err = true;
							}
						}
					}	
	| relexpr			{ $$ = $1; }
;

relexpr: arith				{ $$ = $1; }
	| relexpr OP_GT arith		{	if(!err){
							bool numeric = is_numeric($1, $3);

							if(numeric){
								int type_expr = num_types($1, $3);
								switch(type_expr){
									case 0: $$.boolean = $1.integer > $3.integer ? true : false;
										break;
									case 1: $$.boolean = $1.integer > $3.floating ? true : false;
										break;
									case 2: $$.boolean = $1.floating > $3.integer ? true : false;
										break;
									case 3: $$.boolean = $1.floating > $3.floating ? true : false;
										break;
								}
								$$.type = 3;

								fprintf(fp, "%s reduced by the rule: relexpr -> relexpr > arith\n", $$.boolean ? "true" : "false");
							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compare a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compare a boolean value");
								}
								err = true;
							}
						}
					}
	| relexpr OP_GE arith		{
						if(!err){
							bool numeric = is_numeric($1, $3);

							if(numeric){
								int type_expr = num_types($1, $3);
								switch(type_expr){
									case 0: $$.boolean = $1.integer >= $3.integer ? true : false;
										break;
									case 1: $$.boolean = $1.integer >= $3.floating ? true : false;
										break;
									case 2: $$.boolean = $1.floating >= $3.integer ? true : false;
										break;
									case 3: $$.boolean = $1.floating >= $3.floating ? true : false;
										break;
								}
								$$.type = 3;

								fprintf(fp, "%s reduced by the rule: relexpr -> relexpr >= arith\n", $$.boolean ? "true" : "false");
							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compare a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compare a boolean value");
								}
								err = true;
							}
						}
					}
	| relexpr OP_LT arith		{
						if(!err){
							bool numeric = is_numeric($1, $3);

							if(numeric){
								int type_expr = num_types($1, $3);
								switch(type_expr){
									case 0: $$.boolean = $1.integer < $3.integer ? true : false;
										break;
									case 1: $$.boolean = $1.integer < $3.floating ? true : false;
										break;
									case 2: $$.boolean = $1.floating < $3.integer ? true : false;
										break;
									case 3: $$.boolean = $1.floating < $3.floating ? true : false;
										break;
								}
								$$.type = 3;

								fprintf(fp, "%s reduced by the rule: relexpr -> relexpr < arith\n", $$.boolean ? "true" : "false");
							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compare a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compare a boolean value");
								}
								err = true;
							}
						}
					}
	| relexpr OP_LE arith		{
						if(!err){
							bool numeric = is_numeric($1, $3);

							if(numeric){
								int type_expr = num_types($1, $3);
								switch(type_expr){
									case 0: $$.boolean = $1.integer <= $3.integer ? true : false;
										break;
									case 1: $$.boolean = $1.integer <= $3.floating ? true : false;
										break;
									case 2: $$.boolean = $1.floating <= $3.integer ? true : false;
										break;
									case 3: $$.boolean = $1.floating <= $3.floating	? true : false;
										break;
								}
								$$.type = 3;

								fprintf(fp, "%s reduced by the rule: relexpr -> relexpr <= arith\n", $$.boolean ? "true" : "false");
							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compare a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compare a boolean value");
								}
								err = true;
							}
						}
					}
	| relexpr OP_EQ arith		{
						if(!err){
							bool numeric = is_numeric($1, $3);

							if(numeric){
								int type_expr = num_types($1, $3);
								switch(type_expr){
									case 0: $$.boolean = $1.integer == $3.integer ? true : false;
										break;
									case 1: $$.boolean = $1.integer == $3.floating ? true : false;
										break;
									case 2: $$.boolean = $1.floating == $3.integer ? true : false;
										break;
									case 3: $$.boolean = $1.floating == $3.floating ? true : false;
										break;
								}
								$$.type = 3;

								fprintf(fp, "%s reduced by the rule: relexpr -> relexpr == arith\n", $$.boolean ? "true" : "false");
							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compare a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compare a boolean value");
								}
								err = true;
							}
						}
					}
	| relexpr OP_INEQ arith		{ 	if(!err){
							bool numeric = is_numeric($1, $3);

							if(numeric){
								int type_expr = num_types($1, $3);
								switch(type_expr){
									case 0: $$.boolean = $1.integer != $3.integer ? true : false;
										break;
									case 1: $$.boolean = $1.integer != $3.floating ? true : false;
										break;
									case 2: $$.boolean = $1.floating != $3.integer ? true : false;
										break;
									case 3: $$.boolean = $1.floating != $3.floating ? true : false;
										break;
								}
								$$.type = 3;

								fprintf(fp, "%s reduced by the rule: relexpr -> relexpr <= arith\n", $$.boolean ? "true" : "false");
							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compare a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compare a boolean value");
								}
								err = true;
							}
						}
					}	
;


arith: term				{ $$ = $1; }
	| arith OP_ADD term		{ 	if(!err){
							bool numeric = is_numeric($1, $3);
							if(numeric){
								if($1.type == 0){
									if($3.type == 0){
										$$.integer = $1.integer + $3.integer;
										$$.type = 0;

										fprintf(fp, "%d reduced by the rule: arith -> arith + term\n", $$.integer); 
									}
									else{
										$$.floating = $1.integer + $3.floating;
										$$.type = 1;

										fprintf(fp, "%lf reduced by the rule: arith -> arith + term\n", $$.floating); 
									}
								}
								else{
									$$.floating = ($3.type == 0) ? $1.floating + $3.integer : $1.floating + $3.floating;
									$$.type = 1; 
									
									fprintf(fp, "%lf reduced by the rule: arith -> arith + term\n", $$.floating);
								}
							}
							else{
								// concatenation
								if(is_string($1, $3)){
									char* temp = strdup($1.string);
									char* aux = strdup($3.string);

									if(($1.type == 2) != ($3.type == 2)){
										if($1.type == 2){
											switch($3.type){
												case 0: asprintf(&aux, "%d", $3.integer);
													break;
												case 1: asprintf(&aux, "%lf", $3.floating);
													break;
												case 3: asprintf(&aux, "%s", $1.boolean ? "true" : "false");
													//aux = $3.boolean ? "true" : "false";
													break;
											}
										}
										else{
											switch($1.type){
												case 0: asprintf(&temp, "%d", $1.integer);
													break;
												case 1: asprintf(&temp, "%lf", $1.floating);
													break;
												case 3: asprintf(&temp, "%s", $1.boolean ? "true" : "false");
													//temp = $1.boolean ? "true" : "false";
													break;
											}
										}
									}
									strcat(temp, aux);
									$$.string = strdup(temp);
									$$.type = 2;	
									

									fprintf(fp, "%s reduced by the rule: arith -> arith + term\n", $$.string);

									// free all memory allocated
									free(temp);
									free(aux);
								}
								else{
									yyerror("semantic error: cannot compute addition of boolean values");
									err = true;
								}
							}
						}
					}
	| arith OP_SUB term		{	if(!err){
							// check types and make appropiate conversion if needed	
							bool numeric = is_numeric($1, $3);

							if(numeric){
								fprintf(fp, "term OP_SUB unary\n");
								
								int type_expr = num_types($1, $3);
								
								switch(type_expr){
									case 0: $$.integer = $1.integer - $3.integer;
										break;
									case 1: $$.floating = $1.integer - $3.floating;
										break;
									case 2: $$.floating = $1.floating - $3.integer;
										break;
									case 3: $$.floating = $1.floating - $3.floating;
										break;
								}
								
								$$.type = type_expr == 0 ? 0 : 1; 

							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compute the subtraction of a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compute the subtraction of a boolean value");
								}
								err = true;
							}
						}
					}
;

term: unary				{ $$ = $1; }
    | term OP_MUL unary			{ 	if(!err){
							// check types and make appropiate conversion if needed
							bool numeric = is_numeric($1, $3);

							if(numeric){
								fprintf(fp, "term OP_MUL unary\n");
								
								int type_expr = num_types($1, $3);
								
								switch(type_expr){
									case 0: $$.integer = $1.integer * $3.integer;
										break;
									case 1: $$.floating = $1.integer * $3.floating;
										break;
									case 2: $$.floating = $1.floating * $3.integer;
										break;
									case 3: $$.floating = $1.floating * $3.floating;
										break;
								}
								
								$$.type = type_expr == 0 ? 0 : 1; 

							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compute the division of a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compute the division of a boolean value");
								}
								err = true;
							}
						}
					}
    | term OP_DIV unary			{ 	if(!err){
							// check types and make appropiate conversion if needed
							bool numeric = is_numeric($1, $3);

							if(numeric){
								fprintf(fp, "term OP_DIV unary\n");
								// control division by 0
								if($3.type == 0){
									if($3.integer == 0){
										yyerror("semantic error: cannot divide by 0"); 
										err = true;
									}
								}
								else{
									if($3.floating == 0.0f){
										yyerror("semantic error: cannot divide by 0.0"); 
										err = true;
									}
								}

								if(!err){
									if($1.type == 0){
										$$.floating = ($3.type == 0) ? $1.integer / $3.integer : $1.integer / $3.floating;
									}
									else{
										$$.floating = ($3.type == 0) ? $1.floating / $3.integer : $1.floating / $3.floating;
									}
									$$.type = 1;
								}
							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compute the division of a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compute the division of a boolean value");
								}
								err = true;
							}
						}

					}
    | term OP_MOD unary			{ 	if(!err){
							// check types and make appropiate conversion if needed							
							bool numeric = is_numeric($1, $3);

							if(numeric){
								fprintf(fp, "term OP_MOD unary\n");
								
								int type_expr = num_types($1, $3);
								
								switch(type_expr){
									case 0: $$.integer = $1.integer % $3.integer;
										break;
									case 1: $$.floating = fmod($1.integer,$3.floating);
										break;
									case 2: $$.floating = fmod($1.floating, $3.integer);
										break;
									case 3: $$.floating = fmod($1.floating, $3.floating);
										break;
								}
								
								$$.type = type_expr == 0 ? 0 : 1; 

							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compute the division of a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compute the division of a boolean value");
								}
								err = true;
							}
						}	
					}
;

unary: OP_SUB unary			{ 	if(!err){
							if(($2.type == 0) || ($2.type == 1)){
								fprintf(fp, "OP_SUB unary\n");
								if($2.type == 0){
									$$.integer = -$2.integer;
									$$.type = 0;
								}
								else{
									$$.floating = -$2.floating;
									$$.type = 1;
								}
							}
							else{
								yyerror("semantic error: cannot negate non-numeric values");
								err = true;
							}
						}
					}
     | pow				{ $$ = $1; }
;

pow: factor OP_POW pow			{ 	if(!err){
							// check types and make appropiate conversion if needed
							bool numeric = is_numeric($1, $3);

							if(numeric){
								fprintf(fp, "factor OP_POW pow\n");

								int type_expr = num_types($1, $3);
								
								switch(type_expr){
									case 0: $$.integer = pow($1.integer, $3.integer);
										break;
									case 1: $$.floating = pow($1.integer, $3.floating);
										break;
									case 2: $$.floating = pow($1.floating, $3.integer);
										break;
									case 3: $$.floating = pow($1.floating, $3.floating);
										break;
								}

								$$.type = type_expr == 0 ? 0 : 1;

							}
							else{
								// string arguments are not valid
								if(is_string($1, $3)){
									yyerror("semantic error: cannot compute the power of a string argument");
								}
								// boolean arguments are not valid either
								else{
									yyerror("semantic error: cannot compute the power of a boolean value");
								}
								err = true;
							}
						}
					}
   | factor				{ $$ = $1; }
;



factor: T_IDEN				{	int found = sym_lookup($1.string, &aux);
      						if(found == 0){
							name = $1.string;
							$$ = aux;
						}
						else{
							yyerror("syntax error: undeclared identifier");
							err = true;
						}
					}
      | T_INT				{ fprintf(fp, "T_INT "); $$ = $1; $$.type = 0; }
      | T_FLOAT				{ fprintf(fp, "T_FLOAT "); $$ = $1; $$.type = 1; }
      | T_STRING			{ fprintf(fp, "T_STRING "); $$ = $1; $$.type = 2; }
      | T_BOOL				{ fprintf(fp, "T_BOOL "); $$ = $1; $$.type = 3; }
      | SYM_OB expr SYM_CB		{ fprintf(fp, "(expr) "); $$ = $2; /*TODO: check this pls*/}
;



assignment: T_IDEN ASSIG expr		{ 	if(!err){ // check if there were any errors in the calculations of the expr to be assigned
							name = $1.string;
							int found = sym_lookup(name, &aux); // 1. search identifier
						
							// check whether the identifier was found or not
							if(found == 0){
								// if types are compatible then change var value

								// for assignments, compatibility depends only if types
								// are the same for both the identifier found and the value to be saved
								if(aux.type == $3.type){
									aux = $3;
									sym_enter(name, &aux);
								}
								// if types aren't compatible then there's a semantic error
								else{
									yyerror("semantic error: identifier and expression type missmatch"); 
									err = true;
								}
							}
							else{
								// if identifier doesn't exist then we have to create a new entry
								if(found == 2){
									aux = $3;
									sym_add(name, &aux);
								}
							}

							// if the assignment succeeded log grammar production
							if(!err) {
								fprintf(fp, "reducido por T_IDEN ASSIG expr\n"); // TODO: change log message to something more meaningful
								$$ = $3;
							}
						}
					}
;

%%

void yyerror(char *str)
{
  fprintf(stderr, "Compiler error:%d: %s.\n", line, str);
}

int main(int argc, char **argv)
{ 
  // get current date and time 
  time_t t = time(NULL); 
  struct tm tm = *localtime(&t);

  // set log file name
  char* path;
  if(0 > asprintf(&path, "log/%d-%02d-%02d_%02d:%02d:%02d.log",
        tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour,
        tm.tm_min, tm.tm_sec)) {
		fprintf(stderr, "Couldn't create log file...");
		return 1;
  }
  
  // create log file
  fp = fopen(path, "w");
  free(path);

  yyparse();

  fclose(fp);
  return 0;
}


/*-----------------------------------------------------*/
/*----------------- Auxiliar functions ----------------*/
/*-----------------------------------------------------*/

/* 
*  Checks if passed variables are of a numeric type or not 
*/
bool is_numeric(atributs a, atributs b){
	return (((a.type == 0) || (a.type == 1)) && ((b.type == 0) || (b.type == 1)));
}

bool is_string(atributs a, atributs b){
	return (a.type == 2) || (b.type == 2);
}

bool is_bool(atributs a, atributs b){
	return (a.type == 3) || (b.type == 3);
}

/* 
*  Returns the kind of numeric expression we've encountered.
*  Must only be used after 'is_numeric' succeeded, otherwise errors might happen.
*
*  0 -> both integers
*  1 -> a int, b float
*  2 -> a float, b int
*  3 -> both floats
*
*/
int num_types(atributs a, atributs b){
  if((a.type == 0) && (b.type == 0)){
  	return 0;
  }
  else{
  	if((a.type == 1) && (b.type == 1)){
		return 3;
	}
	else{
		if(a.type == 0){
			return 1;
		}
		else{
			return 2;
		}
	}
  }
}

void print_iden(char* name, atributs assig){
  switch(assig.type){
	case 0: printf("Assignment name: %s\ttype: int\tvalue: %d\n", name, assig.integer); 
		break;
	case 1: printf("Assignment name: %s\ttype: float\tvalue: %lf\n", name, assig.floating); 
		break;
	case 2: printf("Assignment name: %s\ttype: string\tvalue: '%s'\n", name, assig.string); 
		break;
	case 3: printf("Assignment name: %s\ttype: boolean\tvalue: %s\n", name, assig.boolean ? "true" : "false"); 
		break;
  }
}

void print_expr(atributs expr){ 
  switch(expr.type){
	case 0: printf("Expression of type: int\tvalue: %d\n", expr.integer); 
		break;
	case 1: printf("Expression of type: float\tvalue: %lf\n", expr.floating); 
		break;
	case 2: printf("Expression of type: string\tvalue: '%s'\n", expr.string); 
		break;
	case 3: printf("Expression of type: boolean\tvalue: %s\n", expr.boolean ? "true" : "false"); 
		break;
  }
}