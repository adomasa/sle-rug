module Syntax

extend lang::std::Layout;

/*
 * Concrete syntax of QL
 */

start syntax Form
	= "form" Id name "{" Question* qs "}"
	;

syntax Question
	= question: Str label Id ref ":" Type
	| computed_question: Str label Id ref ":" Type "=" Expr
	| if_then: "if" "(" Expr cond ")" Block
	| if_then_else: "if" "(" Expr cond ")" Block "else" Block
	;

syntax Block
	= "{"Question* qs"}"
	;

/* Operator precedence follows Java ruleset
 *(https://introcs.cs.princeton.edu/java/11precedence/)
 */
syntax Expr
	= ref: Id
	| \str: Str
	| \int: Int
	| \bool: Bool
	| left brackets: "(" Expr ")"
	> right not: "!" Expr
	> left (
			mul: Expr lhs "*" Expr rhs
		|	div: Expr lhs "/" Expr rhs
	)
	> left (
			add: Expr lhs "+" Expr rhs
		|	diff: Expr lhs "-" Expr rhs
	)
	// No defined behavior when used in sequence
	> non-assoc (
			gt: Expr lhs "\>" Expr rhs
		|	geq: Expr lhs "\>=" Expr rhs
		|	lt: Expr lhs "\<" Expr rhs
		|	leq: Expr lhs "\<=" Expr rhs
	)
	> non-assoc (
			eql: Expr lhs "==" Expr rhs
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

keyword Reserved
	= "true"
	| "false"
	| "boolean"
	| "integer"
	| "string"
	| "if"
	| "else"
	| "form"
	;

lexical Id
	= ([a-zA-Z] !<< // look behind restriction
		[a-zA-Z][a-zA-Z0-9_]* // character classes
		!>> [a-zA-Z0-9_] // lookahead restriction
		)
	\ Reserved
	;

lexical Str
	= [\"]![\"]*[\"]
	;

lexical Int
	= [0]
	| [\-]?[1-9][0-9]*
	;

lexical Bool
	= "true"
	| "false"
	;