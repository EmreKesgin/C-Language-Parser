%{
	#include <stdio.h>
	#include <iostream>
	#include <string>
	#include <map>
	using namespace std;
	#include "y.tab.h"
	extern FILE *yyin;
	extern int yylex();
	void yyerror(string s);
	extern int linenum;// use variable linenum from the lex file
	int indent = 0;
	map<string,string> defValue;
	map<string,string> map1;
	string finalOutput;
	string	function_info;
	void printTab()
	{
		for(int i=0;i<indent;i++)
			finalOutput+="\t";
	}

%}
%union{
	char * str;
	int number;
}

%token <str> ANDOR IDENTIFIER INTEGER COMP OPERATIONS
%token IFRKW WHILERKW SEMICOLON OP CP OCB CCB  EQ EQSMALLER EQLARGER DEFINERSW INT VOID COMMA
%type<str> operand condition_block  comparison_block  comparison assignment declaration statements void

%%
statements:
	statements statement 
	|

	;

statement:
	condition_op condition_block openCurly statements closeCurly
	{
		indent--;
		printTab();
		finalOutput+="}\n";
		function_info +="}\n";
	}
	|
	condition_op condition_block statements closeCurly
	{
		 cout<<"missing { in the code"<<endl;
		 exit(1);
	}
	|
	condition_op condition_block openCurly statements
	{
		 cout<<"missing } in the code"<<endl;
		 exit(1);
	}
	|
	DEFINERSW IDENTIFIER INTEGER
	{
		finalOutput += "#define "+ string($2) +" "+ string($3) + "\n";
		function_info += "#define "+ string($2) +" "+ string($3) + "\n";
		defValue[string($2)]=$3;
	}
	|
	IDENTIFIER EQ assignment SEMICOLON
	{
		//assignment
		finalOutput += string($1) + " = " + string($3) + ";" + "\n";
		function_info += string($1) + " = " + string($3) + ";" + "\n";
	}
	|
	INT declaration SEMICOLON
	{
		//declaration
		finalOutput += "int " + string($2) + ";" + "\n";
		function_info += "int " + string($2) + ";" + "\n";
	}
	|
	void statements CCB
	{
		//Fonksiyon kuralı
		finalOutput += "}\n";
		function_info += "}\n";
		map1[string($1)] =	function_info;
		function_info.clear();
	}
	|
	IDENTIFIER OP CP SEMICOLON
	{
		//Fonksiyon çağırma kuralı
		if(map1.find(string($1)) != map1.end()){
			finalOutput += "{\n" + map1[string($1)] + "\n";
			function_info += "{\n" + map1[string($1)] + "\n";
		}
		else{
			cout<<"error: function "<< string($1) <<" does not exists"<<endl;
			exit(0);
		}
	}
	
	;
void:
	VOID IDENTIFIER OP CP OCB{
		$$ = strdup($2);
		finalOutput += "void " + string($2) + "(" + ")" + "\n" + "{" + "\n";
	}
	;
	
assignment:
	INTEGER{
		$$ = strdup($1);
	}
	|
	IDENTIFIER{
		$$ = strdup($1);
	}
	|
	IDENTIFIER OPERATIONS assignment{
		string tmp;
		tmp += string($1) + string($2) + string($3);
		$$ = strdup(tmp.c_str());
	}
	|
	INTEGER OPERATIONS assignment{
	}
	;
declaration:
	IDENTIFIER{
		$$ = strdup($1);
	}
	|
	IDENTIFIER COMMA declaration{
		string tmp;
		tmp += string($1) + "," + string($3);
		$$ = strdup(tmp.c_str());
	}
	;

condition_block:
	OP comparison_block CP
	{
		finalOutput += "( "+ string($2) + " )\n";
		function_info += "( "+ string($2) + " )\n";
		printTab();
		finalOutput += "{\n";
		function_info += "{\n";

	}
	;

comparison_block:
	comparison_block ANDOR comparison
	{
		string combined = string($1)+ string($2) + string($3);
		$$ = strdup(combined.c_str());
	}
	|
	comparison
	{
		$$ = strdup($1);
	}
	;

comparison:
	operand COMP operand;
	{
		string combined = string($1) +" "+ string($2) +" "+ string($3);
		$$ = strdup(combined.c_str());
	}
;
condition_op:
	IFRKW {
		printTab();
		finalOutput += "if";
		function_info += "if";
	}
	|
	WHILERKW{
		printTab();
		finalOutput += "while";
		function_info += "while";
	}
	;
operand:
	IDENTIFIER {
  	if (defValue.find(string($1)) != defValue.end())
			$$=strdup((defValue[string($1)]).c_str());
		else
			$$=strdup($1);
	}
	|
	INTEGER {$$=strdup($1);}
	;

openCurly:
	OCB {indent++;}
	;
closeCurly:
	CCB
	;
%%
void yyerror(string s){

		cerr<<"Error at line: "<<linenum<<endl;
}
int yywrap(){
	return 1;
}
int main(int argc, char *argv[])
{
    yyin=fopen(argv[1],"r");
    yyparse();
    fclose(yyin);
	finalOutput = finalOutput.substr(finalOutput.find("void main"));
	cout<<finalOutput<<endl;
    return 0;
}