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
	return { <id.src, id.val> | /ref(AId id)  := f }; // expressions
}

Def defs(AForm f) {
	return { <id.val, id.src> | /question(_, AId id, _, _) := f } + // computed_question
				 { <id.val, id.src> | /question(_, AId id, _) := f }; // question
					
}