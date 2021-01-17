module TransformDemo

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;
import IO;
import Resolve;
import Set;
import Transform;

 
 void main() {
  tax = parse(#start[Form], |project://sle-rug/examples/tax.myql|);
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