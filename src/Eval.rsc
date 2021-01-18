module Eval

import AST;
import Resolve;

import Syntax;
import ParseTree;
import CST2AST;
import IO;
/*
 * Big-step semantics for QL
 * Eval assumes the form is type- and name-correct
 */

// Semantic domain for expressions (values)
data Value
	= vint(int i)
	| vbool(bool b)
	| vstr(str s)
	;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
	= input(str question, Value \value);

VEnv initialEnv(AForm f) {
	VEnv venv = ();
	for (/AQuestion q := f, q has label) {
		switch(q.\type) {
			case boolean():
				venv += (q.ref.val: vbool(false));
			case string():
				venv += (q.ref.val: vstr(""));
			case integer():
				venv += (q.ref.val: vint(0));
			default: throw "Unsupported question type <q.\type>";
		}
	}
	return venv;
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
	return solve (venv) {
		venv = evalOnce(f, inp, venv);
	}
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
	for (q <- f.qs) venv = eval(q, inp, venv);
	return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
	// evaluate conditions for branching,
	// evaluate inp and computed questions to return updated VEnv
	switch (q) {
		case question(_, ref, _):
			if (ref.val == inp.question)
				venv[ref.val] = inp.\value;
		case computedQuestion(_, ref, _, expr):
			venv[ref.val] = eval(expr, venv);
		case ifThen(cond, qs):
			if (eval(cond, venv).b)
				for (AQuestion q <- qs)
					venv = eval(q, inp, venv);
		case ifThenElse(cond, thenQs, elseQs):
			for (AQuestion q <- (eval(cond, venv).b ? thenQs : elseQs))
				venv = eval(q, inp, venv);
	}
	return venv;
}

Value eval(AExpr e, VEnv venv) {
	switch (e) {
		case ref(id(str x)):
			return venv[x];
		case \bool(bool b):
			return vbool(b);
		case \str(str s):
			return vstr(s);
		case \int(int i):
			return vint(i);
		case not(AExpr e):
			return vbool(!(eval(e, venv).b));

		case mul(AExpr lhs, AExpr rhs):
			return vint(eval(lhs, venv).i * eval(rhs, venv).i);
		case div(AExpr lhs, AExpr rhs):
			return vint(eval(lhs, venv).i / eval(rhs, venv).i);
		case add(AExpr lhs, AExpr rhs):
			return vint(eval(lhs, venv).i + eval(rhs, venv).i);
		case diff(AExpr lhs, AExpr rhs):
			return vint(eval(lhs, venv).i - eval(rhs, venv).i);

		case gt(AExpr lhs, AExpr rhs):
			return vbool(eval(lhs, venv).i > eval(rhs, venv).i);
		case geq(AExpr lhs, AExpr rhs):
			return vbool(eval(lhs, venv).i >= eval(rhs, venv).i);
		case lt(AExpr lhs, AExpr rhs):
			return vbool(eval(lhs, venv).i < eval(rhs, venv).i);
		case leq(AExpr lhs, AExpr rhs):
			return vbool(eval(lhs, venv).i <= eval(rhs, venv).i);
		case eql(AExpr lhs, AExpr rhs): {
			lval = eval(lhs, venv);
			rval = eval(rhs, venv);
			// Under correct type assumption
			switch(lval) {
				case vint(_):
					return vbool(lval.i == rval.i);
				case vbool(_):
					return vbool(lval.b == rval.b);
				case vstr(_):
					return vbool(lval.s == rval.s);
			}
		}
		case neq(AExpr lhs, AExpr rhs):
			return not(eq(lhs, rhs, venv));

		case and(AExpr lhs, AExpr rhs):
			return vbool(eval(lhs, venv).b && vbool(eval(lhs, venv).b));
		case or(AExpr lhs, AExpr rhs):
			return vbool(eval(lhs, venv).b || vbool(eval(lhs, venv).b));

		default: throw "Unsupported expression <e>";
	}
}