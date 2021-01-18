module CompileDemo

import Compile;
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
	compile(atax);
}