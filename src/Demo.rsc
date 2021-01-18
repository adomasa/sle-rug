module Demo

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;
import IO;
import Set;
import Transform;
import Eval;
import Compile;


void compileDemo() {
	demo = parse(#start[Form], |project://sle-rug/examples/demo.myql|);
	ademo = cst2ast(demo);
	compile(ademo);
	//check source files manually
}

void renameDemo() {
	demo = parse(#start[Form], |project://sle-rug/examples/demo.myql|);
	ademo = cst2ast(demo);

	refGraph = resolve(ademo);
	useDef = refGraph.useDef;

	renameddemo = rename(demo, getSrc(demo.top.qs[2]), "newName", useDef);
	println(renameddemo);
	println("");

	// random ref rename
	use = uses(ademo);
	<a, b> = getOneFrom(use);
	renameddemo2 = rename(demo, a, "newName", useDef);
	println(renameddemo2);
	
	println(renameddemo2);
	println("");
}

void flattenDemo() {
	demo = parse(#start[Form], |project://sle-rug/examples/demo.myql|);
	ademo = cst2ast(demo);
	
	flat_ademo = flatten(ademo);
	println(flat_ademo);
}


void evalDemo() {
	demo = parse(#start[Form], |project://sle-rug/examples/demo.myql|);
	ademo = cst2ast(demo);
	eval(ademo, input("hasMaintLoan", vbool(false)), initialEnv(ademo));
}

loc getSrc(Question q) {
	switch (q) {
		case (Question) `<Str _> <Id ref> : <Type _>`:
			return ref@\loc;
		}
}


