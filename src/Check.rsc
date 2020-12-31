module Check

import AST;
import Resolve;
import Message;

import Location;

data Type
	= tint()
	| tbool()
	| tstr()
	| tunknown()
	;

alias TEnv = rel[loc def, str name, str label, Type \type];

TEnv collect(AForm f) {
	return {<ref.src, ref.val, label, getType(t)> | /question(str label,  AId ref, AType t) := f}
		+ {<ref.src, ref.val, label, getType(t)> | /computedQuestion(str label,  AId ref, AType t, _) := f};
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	for (/AQuestion q := f) {
		msgs += check(q, tenv, useDef);
	}
	
	for (/AExpr e := f) {
		msgs += check(e, tenv, useDef);
	}

	return msgs;
}

set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	// For duplicates, errrors/warnings are shown on all except first instances
	switch (q) {
		case question(label, id(refName, src = loc refSrc), t): {
			msgs += { warning("Duplicate question label", q.src)
							| <loc refSrc2, _, label, _> <- tenv, isBefore(refSrc2, refSrc)
							};
			msgs += { warning("Duplicate question with different label", q.src)
							| <loc refSrc2, refName, label2, _> <- tenv, label2 != label && isBefore(refSrc2, refSrc)
							};
			msgs += { error("Duplicate question name with different type", q.src)
							| <loc refSrc2, refName, _, t2> <- tenv, getType(t) != t2 && isBefore(refSrc2, refSrc)
							};
			}
		case computedQuestion(label, id(refName, src = loc refSrc), t, expr): {
			msgs += { warning("Duplicate question label", q.src)
							| <loc refSrc2, _, label, _> <- tenv, isBefore(refSrc2, refSrc)
							};
			msgs += { warning("Duplicate question with different label", q.src)
							| <loc refSrc2, refName, label2, _> <- tenv, label2 != label && isBefore(refSrc2, refSrc)
							};
			msgs += { error("Duplicate question name with different type", q.src)
							| <loc refSrc2, refName, _, t2> <- tenv, getType(t) != t2 && isBefore(refSrc2, refSrc)
							};
			msgs += { error("Expression\'s return value has to match question\'s type ", expr.src)
							| typeOf(expr, tenv, useDef) != getType(t)
							};
		}
		case ifThen(cond, qs):
			msgs += { error("Condition has to return boolean", cond.src)
					| typeOf(cond, tenv, useDef) != tbool()
					};
		case ifThenElse(cond, thenQs, elseQs):
				msgs += { error("Condition has to return boolean", cond.src)
						| typeOf(cond, tenv, useDef) != tbool()
						};
	}
	return msgs;
}

set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};

	switch (e) {
		case ref(AId x):
			msgs +=
				{ error("Undeclared question", x.src)
				| useDef[x.src] == {}
				};
		case not(AExpr e):
			msgs +=
				{ error("Operand of \"\"! should be a boolean", e.src)
				| tbool() != typeOf(e, tenv, useDef)
				};

		case mul(AExpr lhs, AExpr rhs):
			msgs +=
				{ error("Operands of \"*\" should be integers.", e.src)
				| tint() != typeOf(lhs, tenv, useDef) || tint() != typeOf(rhs, tenv, useDef)
				};
			
		case div(AExpr lhs, AExpr rhs):
			msgs +=
				{ error("Operands of \"/\" should be integers", e.src)
				| tint() != typeOf(lhs, tenv, useDef) || tint() != typeOf(rhs, tenv, useDef)
				};
		case add(AExpr lhs, AExpr rhs):
			msgs +=
				{ error("Operands of <typeOf(lhs, tenv, useDef)>\"+\" <typeOf(rhs, tenv, useDef)>should be integers", e.src)
				| tint() != typeOf(lhs, tenv, useDef) || tint() != typeOf(rhs, tenv, useDef)
				};
		case diff(AExpr lhs, AExpr rhs):
				msgs +=
				{ error("Operands of \"-\" should be integers", e.src)
				| tint() != typeOf(lhs, tenv, useDef) || tint() != typeOf(rhs, tenv, useDef)
				};

		case gt(AExpr lhs, AExpr rhs):
			msgs +=
				{ error("Operands of \"\>\" should be integers", e.src)
				| tint() != typeOf(lhs, tenv, useDef) && tint() != typeOf(rhs, tenv, useDef)
				};
			
		case geq(AExpr lhs, AExpr rhs):
			msgs +=
				{ error("Operands of \"\>=\" should be integers", e.src)
				| tint() != typeOf(lhs, tenv, useDef) && tint() != typeOf(rhs, tenv, useDef)
				};
		case lt(AExpr lhs, AExpr rhs):
			msgs +=
				{ error("Operands of \"\<\" should be integers", e.src)
				| tint() != typeOf(lhs, tenv, useDef) && tint() != typeOf(rhs, tenv, useDef)
				};
		case leq(AExpr lhs, AExpr rhs):
			msgs +=
				{ error("Operands of \"\<=\" should be integers", e.src)
				| tint() != typeOf(lhs, tenv, useDef) || tint() != typeOf(rhs, tenv, useDef)
				};
		case eq(AExpr lhs, AExpr rhs):
				msgs +=
				{ error("Operands of \"==\" should be of the same type", e.src)
				| typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef)
				};
		case neq(AExpr lhs, AExpr rhs):
				msgs +=
				{ error("Operands of \"!=\" should be of the same type", e.src)
				| typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef)
				};

		case or(AExpr lhs, AExpr rhs):
			msgs +=
				{ error("Operands of \"or\" should be of a boolean type", e.src)
				| tbool() != typeOf(lhs, tenv, useDef) || tbool() != typeOf(rhs, tenv, useDef)
				};
		case and(AExpr lhs, AExpr rhs):
			msgs +=
				{ error("Operands of \"and\" should be of a boolean type", e.src)
				| tbool() != typeOf(lhs, tenv, useDef) || tbool() != typeOf(rhs, tenv, useDef)
				};
		}

	return msgs;
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
	switch (e) {
		case ref(id(_, src = loc u)):
			if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
				return t;
			}

	case \bool(_):
		return tbool();
		case \str(_):
		return tstr();
		case \int(_):
			return tint();

		case mul(_, _):
			return tint();
		case div(_, _):
			return tint();
		case add(_, _):
			return tint();
		case diff(_, _):
			return tint();
			
		case not(_):
			return tbool();

		case gt(_, _):
			return tbool();
		case geq(_, _):
			return tbool();
		case lt(_, _):
			return tbool();
		case leq(_, _):
			return tbool();
		case eq(_, _):
			return tbool();
		case neq(_, _):
			return tbool();

		case and(_, _):
			return tbool();
		case or(_, _):
			return tbool();
	}

	return tunknown();
}

Type getType(AType t) {
	switch (t) {
		case boolean(): return tbool();
		case string(): return tstr();
		case integer(): return tint();
	}
}
