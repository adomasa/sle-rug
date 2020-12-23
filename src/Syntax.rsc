module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
	= "form" Id \ ReservedKeywords "{" Question* "}"
	;

syntax Question
	= question: Str label Id name \ ReservedKeywords ":" Type type
	| computed_question: Str label Id \ ReservedKeywords ":" Type "=" Expr
	| if_then: "if" "(" Expr ")" Block
	| if_then_else: "if" "(" Expr ")" Block "else" Block
	; 

syntax Block
	= "{" Question* "}"
	;

syntax Expr 
	= ref: Id \ ReservedKeywords
	| Literal
	> brackets: "(" Expr ")"
	> right not: "!" Expr
	> left (
			mul: Expr lhs "*" Expr rhs
		|	div: Expr lhs "/" Expr rhs
	)
	> left (
			add: Expr lhs "+" Expr rhs
		|	sub: Expr lhs "-" Expr rhs
	)
	> non-assoc (
			gt: Expr lhs "\>" Expr rhs
		|	geq: Expr lhs "\>=" Expr rhs
		|	lt: Expr lhs "\<" Expr rhs
		|	leq: Expr lhs "\<=" Expr rhs
	)
	> non-assoc (
			eq: Expr lhs "==" Expr rhs
		|	neq: Expr lhs "!=" Expr rhs
	)
	> left and: Expr lhs "&&" Expr rhs
	> left or: Expr lhs "||" Expr rhs
	;

syntax Type 
	= "boolean"  
	| "integer" 
	| "string"
	; 

syntax Literal 
	= \bool: Bool
	| \str: Str 
	| \int: Int 
	; 

lexical Str
	= [\"]![\"]*[\"]
	;

lexical ReservedKeywords
	= Bool
	| Type
	| "if"
	| "else"
	| "form"
	;

lexical Int 
	= [0] 
	| [\-]?[1-9][0-9]*
	;

lexical Bool 
	= "true" 
	| "false"
	;
