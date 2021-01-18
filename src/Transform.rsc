module Transform

import Syntax;
import AST;
import Resolve;
import ParseTree;
import List;
import ParseTree;
/*
 * Transforming QL forms
 */


/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int;
 *     if (a) {
 *        if (b) {
 *          q1: "" int;
 *        }
 *        q2: "" int;
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */

 AForm flatten(AForm f) {
	return form(f.name, ([] | it + flatten(q, [])| AQuestion q <- f.qs));
}

list[AQuestion] flatten(AQuestion q, list[AExpr] conds) {
	if (q has label) {
		return [ifThen(merge(conds), [q])];
	}
	
	list[AQuestion] qs = [];
	if (q has thenQs) {
		qs = (qs | it + flatten(tq, conds + [q.cond]) | tq <- q.thenQs);
	}
	if (q has elseQs) {
		qs = (qs | it + flatten(eq, conds + [not(q.cond)]) | eq <- q.elseQs);
	}
	
	return qs;

}
AExpr merge(list[AExpr] conds) {
	AExpr expr = \bool(true);

	for(cond <- conds) {
		expr = and(expr, cond);
	}
	return expr;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDefs) {
	newId = parseIdName(newName, f);
	instances = findInstances(useOrDef, useDefs);

 return visit (f) {
		case (Question) `<Str s> <Id oldId>: <Type t>`
				=> (Question) `<Str s> <Id newId> : <Type t>`
			when oldId@\loc in instances
		case (Question) `<Str s> <Id oldId> : <Type t> = <Expr e>`
				=> (Question) `<Str s> <Id newId> : <Type t> = <Expr e>`
			when oldId@\loc in instances
		case (Expr) `<Id oldId>`
				=> (Expr) `<Id newId>`
			when oldId@\loc in instances
	};
}

set[loc] findInstances(loc target, UseDef useDefs) {
	if (<target, def> <- useDefs) { //ref instance
		return target + {def} + { use | <use, def> <- useDefs };
	}

	if (<_, target> <- useDefs) { // def instance
		return target + { use | <use, target> <- useDefs };
	}
	
	return {target};
}

Id parseIdName(str refName, start[Form] f) {
	if (/Id id := f, id == refName) {
		throw "<refName> name is already in use";
	}
	return parse(#Id, refName);
}
