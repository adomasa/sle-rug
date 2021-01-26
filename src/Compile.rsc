module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM;
import List;

/*
 * A compiler for QL to HTML and Javascript
 * 	we assume the form is type- and name-correct
 */

/* - use string templates to generate Javascript
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - if needed, use the name analysis to link uses to definitions
 */
void compile(AForm f) {
	writeFile(f.src[extension="js"].top, ast2js(f));
	writeFile(f.src[extension="html"].top, toString(ast2html(f)));
}

HTML5Node ast2html(AForm f) {
	return
		html(
			head(
				title(f.name),
				script(src("https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js")),
				script(src("<f.src[extension="js"].file>"))
			),
			body(
				h1(f.name),
				br(),
				ast2html(f.qs)
			)
	);
}

HTML5Node ast2html(list[AQuestion] qs) {
	HTML5Node form = form();
	form.kids += [ast2html(q)|q <- qs];
	form.kids += [input(
								\type("Submit"),
								\value("Submit")
							)];
	return form;
}


HTML5Node ast2html(AQuestion q) {
	switch (q) {
		case question(str label, AId ref, AType t):
			return div(label,
							br(),
							id("<ref.val>"),
							resolveInputFields(t, label, ref),
							br(),
							br()
						);

		case computedQuestion(str label, AId ref, AType t, AExpr expr):
			return div(label,
							br(),
							id("<ref.val>"),
							resolveInputFields(t, label, ref, computed=true),
							br(),
							br()
						);

		case i: ifThen(AExpr cond, list[AQuestion] thenQs): {
			str ref = resolveQuestionContainerId(i);
			HTML5Node container = div(id(ref));
			container.kids += [resolveQuestionContainer(ref + "-then", thenQs)];

			return container;
		}

		case i: ifThenElse(AExpr cond, list[AQuestion] thenQs, list[AQuestion] elseQs): {
			str ref = resolveQuestionContainerId(i);
			HTML5Node container = div(id(ref));

			container.kids += [resolveQuestionContainer(ref + "-then", thenQs),
												resolveQuestionContainer(ref + "-else", elseQs)];

			return container;
		}
		default:
			throw "Unhandled question: <q>";
	}
}

HTML5Node resolveQuestionContainer(str ref, list[AQuestion] qs) {
	HTML5Node container = div(hidden("true"),
														id(ref));
	container.kids += [ast2html(q)|q <- qs];
	return container;
}

str resolveQuestionContainerId(AQuestion i) {
	return "<i.src.offset>";
}

HTML5Node resolveInputFields(AType t, str label, AId ref, bool computed=false) {
	switch (t) {
		case boolean(): {
			inputField = select(
							required("true"),
							id("<ref.val>-input"),
							name(label),
							option(
								\value(""),
								selected(""),
								disabled(""),
								hidden(""),
								computed ? "Computed output" : "Choose an answer"
							),
							option(
								\value("true"),
								"Yes"
							),
							option(
								\value("false"),
								"No"
							)
						);
					if (computed) inputField.kids += [disabled("")];
					return inputField;
		}
		case string(): {
			inputField = input(
							\type("text"),
							id("<ref.val>-input"),
							name(label),
							placeholder(computed ? "Computed output" : "Enter text")
						);
			if (computed) inputField.kids += [disabled("")];
			return inputField;
		}
		case integer(): {
			inputField = input(
						\type("number"),
						id("<ref.val>-input"),
						name(label),
						placeholder(computed ? "Computed output" : "Enter number")
					);
			if (computed) inputField.kids += [disabled("")];
			return inputField;
		}
	}
	
}

// -----------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------

str ast2js(AForm f) {
	list[str] initialComputations = [];
	str content = "";
	// Map of def: uses, by using string representations
	map[str, list[str]] defUses = ( () |it + (ref: []) | <_, ref> <- uses(f) );
	
	for (/computedQuestion(str label, AId ref, AType t, AExpr expr) := f) {
		exprRefs = [x | /ref(id(str x)) := expr];
		
		// If there is no references in computed expression
		// We will precompute the result
		if (isEmpty(exprRefs)) {
			initialComputations += ref.val;
		} else {
			for (str exprRef <- exprRefs) {
				defUses[exprRef] += [ref.val];
			}
		}
		
		content += "function compute_<ref.val>() {\n"
			+ validateDependentFieldValues(exprRefs)
			// We use select for boolean questions
			+ "\t$(\"#<ref.val>-input\").val(<thisOrWrappedBool(expr2js(expr), t)>);\n}\n\n";
	}
	

	for (/AQuestion q := f, q has thenQs) {
		// gather refs from condition expr
		exprRefs = [ x | /ref(id(str x)) := q.cond];
		for (exprRef <- exprRefs) {
			defUses[exprRef] += "<q.src.offset>";
		}
		
		if (isEmpty(exprRefs)) initialComputations += "<q.src.offset>";
		
		// conditional question blocks
		// since no id is defined for then/else blocks
		// we use src offset as an id
		content += "function compute_<q.src.offset>() {\n"
			+ validateDependentFieldValues(exprRefs)
			+ "\tif (<expr2js(q.cond)>) {\n"
 			+ "\t\t$(\"#<q.src.offset>-then\").show(); \n\t\t$(\"#<q.src.offset>-else\").hide() \n\t}\n"
			+ "\telse {\n\t\t$(\"#<q.src.offset>-else\").show(); \n"
			+ "\t\t$(\"#<q.src.offset>-then\").hide();\n\t}\n}\n\n";
	}
	
	content += boolValueConversionFunction();
	// initial function	
	content += "$(function () {\n";
	
	// initial computations
	for (ref <- initialComputations) {
		content += "\tcompute_<ref>();\n";
	}
	
		// add event listeners
	for (ref <- defUses, !isEmpty(defUses[ref])) {
		content += "\n$(\"#<ref>-input\").change(function() {\n";
		
		for (use <- defUses[ref]) {
			content += "\tcompute_<use>();\n";
		}
		
		content += "});\n\n";
	}
	
	content += "});\n\n\n";
	
	return content;
}

str getEventListeners(defUses, ref) {
	str eventListeners = "";
	for (ref <- defUses, !isEmpty(defUses[ref])) {
		eventListeners += "\n$(\"#<ref>-input\").change(function() {\n";
		
		for (use <- defUses[ref]) {
			eventListeners += "\tcompute_<use>();\n";
		}
		eventListeners += "});\n\n";
	}
	return eventListeners;
}

str boolValueConversionFunction() {
		return "function thisOrConvertedBool(val) {\n"
			+ "\tif (val === \'true\') return true;\n"
 			+ "\tif (val === \'false\') return false;\n"
 			+ "\treturn val; \n}\n\n";
}

// Every computation function has a precondition:
// References should have a defined value
str validateDependentFieldValues(list[str] refs){
	if (isEmpty(refs)) return "";
	
	// If value is undefined, null, "", terminate function
	str js_content = "\tif (";
	for (ref <- refs) {
		js_content += "!$(\"#<ref>-input\").val() <(ref != last(refs)) ? "||" : ")">";
	}
	return js_content + " return;\n";;
}

// Make bool value compatible with select html element
str thisOrWrappedBool(str result, AType t) {
	return t := boolean() ? "(<result>).toString()" : result;
}

str expr2js(AExpr e) {
	switch (e) {
		case ref(id(str x)): {
			return "thisOrConvertedBool($(\'#<x>-input\').val())";
		}
			
		case \bool(bool b):
			return "<b>";
		case \str(str s):
			return "\"<s>\"";
		case \int(int i):
			return "<i>";

		case not(AExpr expr):
			return "!(<expr2js(expr)>)";

		case mul(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> * <expr2js(rhs)>)";
		case div(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> / <expr2js(rhs)>)";
		case add(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> + <expr2js(rhs)>)";
		case diff(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> - <expr2js(rhs)>)";

		case gt(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> \> <expr2js(rhs)>)";
		case geq(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> \>= <expr2js(rhs)>)";
		case lt(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> \< <expr2js(rhs)>)";
		case leq(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> \<= <expr2js(rhs)>)";

		case eql(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)>) == (<expr2js(rhs)>)";

		case neq(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)>) != (<expr2js(rhs)>)";

		case and(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> && <expr2js(rhs)>)";
		case or(AExpr lhs, AExpr rhs):
			return "(<expr2js(lhs)> || <expr2js(rhs)>)";
	}
}
