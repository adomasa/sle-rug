module Resolve

import AST;

/*
 * Name resolution for QL
 */


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
	Use uses,
	Def defs,
	UseDef useDef
];

RefGraph resolve(AForm f) = <us, ds, us o ds>
	when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
	return { <ref.src, ref.val> | /ref(AId ref)  := f }; // expressions
}

Def defs(AForm f) {
	return { <ref.val, ref.src> | /computedQuestion(_, AId ref, _, _) := f } +
				 { <ref.val, ref.src> | /question(_, AId ref, _) := f };
}