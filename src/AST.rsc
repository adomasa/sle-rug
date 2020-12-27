module AST

/*
 * Abstract Syntax for QL
 */

data AForm(loc src = |tmp:///|)
	= form(str name, list[AQuestion] qs)
	;

data AQuestion(loc src = |tmp:///|)
	= question					(str label, AId ref, AType \type)
	| computedQuestion	(str label, AId ref, AType \type, AExpr expr)
	| ifThen						(AExpr cond, list[AQuestion] qs)
	| ifThenElse				(AExpr cond, list[AQuestion] thenQs, list[AQuestion] elseQs)
	;

data AExpr(loc src = |tmp:///|)
	= ref			(AId id)
	| \bool		(bool boolean)
	| \str	(str string)
	| \int		(int integer)
	| not			(AExpr expr)

	| mul			(AExpr lhs, AExpr rhs)
	| div			(AExpr lhs, AExpr rhs)
	| add			(AExpr lhs, AExpr rhs)
	| diff		(AExpr lhs, AExpr rhs)

	| gt			(AExpr lhs, AExpr rhs)
	| geq			(AExpr lhs, AExpr rhs)
	| lt			(AExpr lhs, AExpr rhs)
	| leq			(AExpr lhs, AExpr rhs)
	| eq			(AExpr lhs, AExpr rhs)
	| neq			(AExpr lhs, AExpr rhs)

	| and			(AExpr lhs, AExpr rhs)
	| or			(AExpr lhs, AExpr rhs)
	;

data AId(loc src = |tmp:///|)
	= id(str val)
	;

data AType(loc src = |tmp:///|)
	= boolean()
	| string()
	| integer()
	;
