// Manual write code to implement parser,
// Not considered use a tool to generate parser.
// So not all statements are valid grammer definition
grammar kitty;

program
    : module_declartion import_declaration* class_declaration*
    ;

import_declaration
    : 'import' (Identifier |'{' (Identifier | (',' Identifier)*) '}') 'from' String ';'?
    ;

module_declartion
    : 'module' String ';'?
    ;

class_declaration
    : 'class' Identifier ('extends' Identifier)? '{'  class_method* '}'
    ;

class_method
    :'static'? method_declartion
    ;
    
method_declartion
    : 'func' Identifier method_signature (block_statement | '=>' lambda_body)
    ;

method_signature
    : '(' ')'
	| '(' method_parameter_list ')'
    ;
       
method_invocation
	: '(' method_parameter_list? ')'
	;

method_argument_list
    : method_parameter (',' method_argument)*
    ;

method_argument
    : expression
    ;

lambda_expression
	: lambda_method_signature '=>' lambda_body
	;

lambda_method_signature
	: method_signature
	| Identifier
	;

lambda_body
	: expression
	| block_statement
	;

method_parameter_list
    : method_parameter (',' method_parameter)*  (',' method_var_argument)?
    | method_var_argument
    ;

method_parameter
    : Identifier
    ;

method_var_argument
    : '...'  method_parameter
    ;
    
statement_list
	: statement+
	;

statement
    : labeled_Statement			                                   
	| local_variable_declaration ';'?                    
	| common_statement                                            
	;

labeled_Statement
	: Identifier ':' statement  
	;

block_statement
    : '{' statement_list? '}'
    ;

common_statement
	: ';'        
    | block_statement
	| expression ';'?    
	| 'if' '(' expression ')' common_statement ('else' common_statement)             
    | 'switch' '(' expression ')' '{' switch_section* '}'          
	| 'while' '(' expression ')' common_statement                                      
	| 'for' '(' for_initializer? ';' expression? ';' for_iterator? ')' common_statement  
	| 'foreach' '(''var' Identifier 'in' expression ')' common_statement   
	| 'break' ';'?                                         
	| 'continue' ';'?                                              
	| 'goto' Identifier ';'?                                       
	| 'return' expression? ';'?                                  
	;

local_variable_declaration
	: 'var' local_variable_declarator ( ','  local_variable_declarator)*
	;

local_variable_declarator
	: Identifier ('=' local_variable_initializer)?
	;

local_variable_initializer
	: expression
	;

switch_section
	: switch_label+ statement_list
	;

switch_label
	: 'case' expression ':'
	| 'default' ':'
	;

for_initializer
	: local_variable_declaration
	| expression (','  expression)*
	;

for_iterator
	: expression (','  expression)*
	;

expression
    : assign_expression
    | 'func' lambda_expression
    | expression_or
	;

assign_expression
    : expression_primary ('=' | '+=' | '-=' | '*=' | '/=' | '%=' | '&=' | '|=' | '^=' | '<<=' | '>>=') expression
    ;

expression_condition_or
	: expression_condition_and (('||'|'or') expression_condition_and)*
	;

expression_condition_and
	: expression_bit_or (('&&'|'and') expression_bit_or)*
	;

expression_bit_or
	: expression_bit_xor ('|' expression_bit_xor)*
	;

expression_bit_xor
	: expression_bit_and ('^' expression_bit_and)*
	;

expression_bit_and
	: expression_condition_equality ('&' expression_condition_equality)*
	;

expression_condition_equality
	: expression_relational (('==' | '!=')  expression_relational)*
	;

expression_relational
	: expression_bit_shift (('<' | '>' | '<=' | '>=') expression_bit_shift | 'is' Identifier)*
	;

expression_bit_shift
	: expression_additive (('<<' | '>>')  expression_additive)*
	;

expression_additive
	: expression_multiplicative (('+' | '-')  expression_multiplicative)*
	;

expression_multiplicative
	: expression_unary (('*' | '/' | '%')  expression_unary)*
	;

expression_unary
	: expression_primary
	| '+' expression_unary
	| '-' expression_unary
	| '!' expression_unary
	| '~' expression_unary
	;

expression_primary  
	:expression_primary_prefix ((member_access | method_invocation) member_access*)*
	;

expression_primary_prefix
	: 'true'
    | 'false'
    | 'null'      
    | 'undfined'
    | String
    | Number
	| Identifier
	| '(' expression ')'                                             
	| 'this'                                                          
	| 'super'
	| 'new' expression method_invocation
	;

member_access
	: '.' Identifier
    | '[' expression ']'
	;
 
fragment NumberChar
    :[0-9]
    ;

 Number
    :NumberChar* ('.'? NumberChar*)*
    ;
 
 Identifier
    :[A-Za-z_]
    ;

 String
    :Identifier
    ; 