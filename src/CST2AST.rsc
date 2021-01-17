module CST2AST

import Syntax;
import AST;

import ParseTree;
import Boolean;
import String;

/*
 * A mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 */

AForm cst2ast(start[Form] sf) {
	return cst2ast(sf.top); // remove layout before and after form
}

AForm cst2ast(Form f) {
	if ((Form) `form <Id x> { <Question* qs> }` := f)
		return form("<x>",
								[cst2ast(q) | q <- qs],
								src=f@\loc);
	
	throw "Unhandled form: <f>";
}

AQuestion cst2ast(Question q) {
	switch (q) {
		case (Question) `<Str label> <Id ref> : <Type t>`:
			return question("<label>" [1..-1], // eliminate quotes
											id("<ref>", src=ref@\loc),
											cst2ast(t),
											src=q@\loc);

		case (Question) `<Str label> <Id ref> : <Type t> = <Expr e>`:
			return computedQuestion("<label>"[1..-1], // eliminate quotes
															id("<ref>", src=ref@\loc),
															cst2ast(t),
															cst2ast(e),
															src=q@\loc);

		case (Question) `if (<Expr cond>) {<Question* thenQs>}`:
			return ifThen(cst2ast(cond),
										[cst2ast(q) | Question q <- thenQs],
										src=q@\loc);

		case (Question) `if (<Expr cond>) {<Question* thenQs>} else {<Question* elseQs>}`:
			return ifThenElse(cst2ast(cond),
												[cst2ast(q) | Question q <- thenQs],
												[cst2ast(q) | Question q <- elseQs],
												src=q@\loc);
		default:
			throw "Unhandled question: <q>";
	}
}

AExpr cst2ast(Expr e) {
	switch (e) {
		case (Expr) `<Id x>`:
			return ref(id("<x>", src=x@\loc), src=e@\loc);
		case (Expr) `<Str s>`:
			return \str("<s>"[1..-1], src=e@\loc); // eliminate quotes
		case (Expr) `<Int i>`:
			return \int(toInt("<i>"), src=e@\loc);
		case (Expr) `<Bool b>`:
			return \bool(fromString("<b>"), src=e@\loc);

		case (Expr) `(<Expr e>)`:
			return cst2ast(e);
		case (Expr) `!<Expr e>`:
			return not(cst2ast(e), src=e@\loc);

		case (Expr) `<Expr lhs> * <Expr rhs>`:
			return mul(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
		case (Expr) `<Expr lhs> / <Expr rhs>`:
			return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
		case (Expr) `<Expr lhs> + <Expr rhs>`:
			return add(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
		case (Expr) `<Expr lhs> - <Expr rhs>`:
			return diff(cst2ast(lhs), cst2ast(rhs), src=e@\loc);

		case (Expr) `<Expr lhs> \> <Expr rhs>`:
			return gt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
		case (Expr) `<Expr lhs> \>= <Expr rhs>`:
			return geq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
		case (Expr) `<Expr lhs> \< <Expr rhs>`:
			return lt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
		case (Expr) `<Expr lhs> \<= <Expr rhs>`:
			return leq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
		case (Expr) `<Expr lhs> == <Expr rhs>`:
			return eq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
		case (Expr) `<Expr lhs> != <Expr rhs>`:
			return neq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);

		case (Expr) `<Expr lhs> && <Expr rhs>`:
			return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
		case (Expr) `<Expr lhs> || <Expr rhs>`:
			return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);

		default:
			throw "Unhandled expression: <e>";
	}
}

AType cst2ast(Type t) {
	switch (t) {
		case (Type) `string`:
			return string(src = t@\loc);
		case (Type) `integer`:
			return integer(src = t@\loc);
		case (Type) `boolean`:
			return boolean(src = t@\loc);
		default:
			throw "Unhandled type: <t>";
	}
}

