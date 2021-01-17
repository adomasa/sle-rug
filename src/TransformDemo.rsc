module TransformDemo

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;
import IO;
import Resolve;
import Set;
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
 
 void main() {
  tax = parse(#Form, |project://sle-rug/examples/tax.myql|);
  atax = cst2ast(tax);
  println(flatten(atax));

	refGraph = resolve(atax);
	useDef = refGraph.useDef;
	use = uses(atax);
	println("");
  //println(rename(tax, getSrc(tax.qs[2]), "newName", useDef));
  <a, b> = getOneFrom(use);
  println(rename(tax, a, "newName", useDef));
}

loc getSrc(Question q) {
	switch (q) {
		case (Question) `<Str _> <Id ref> : <Type _>`:
			return ref@\loc;
		}
}


 AForm flatten(AForm f) {
	return form(f.name, ([] | it + flatten(q)| AQuestion q <- f.qs));
}

list[AQuestion] flatten(AQuestion q, list[AExpr] conds = [\bool(true)]) {
	if (q has label) {
		return [ifThen(merge(conds), [q])];
	}
	
	list[AQuestion] qs = [];
	if (q has thenQs) {
		qs = (qs | it + flatten(tq, conds = conds + [q.cond]) | tq <- q.thenQs);
	}
	if (q has elseQs) {
		qs = (qs | it + flatten(eq, conds = conds + [not(q.cond)]) | eq <- q.elseQs);
	}
	
	return qs;

}

AExpr merge(list[AExpr] conds) {
	return (last(conds) | and(it, conds[revNum]) | revNum <- [size(conds)-2..0]);
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
Form rename(Form f, loc useOrDef, str newName, UseDef useDefs) {
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

Id parseIdName(str refName, Form f) {
	if (/Id id := f, id == refName) {
		throw "<refName> name is already in use";
	}
	return parse(#Id, refName);
}

