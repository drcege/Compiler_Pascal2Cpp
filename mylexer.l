%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "propertylist.h"
#include "myparser.tab.h"

void info_copy(char * yytext, int yyleng);
%}
%option yylineno
  /*正规定义式*/
delim       [ \t\r\n]
ws              {delim}+
letter        [A-Za-z]
digit           [0-9]
digits        [0-9]+
id              {letter}({letter}|{digit})*
num         {digit}+\.{digit}+
errors          {digits}{id}+\,|{digits}{id}{delim}*|\,{digits}{id}+|{digits}{id}

%%
and       { info_copy(yytext,yyleng); return MULOP;}
array     {  info_copy(yytext,yyleng); return ARRAY;}
begin     { info_copy(yytext,yyleng); return BEGAN;}
boolean     { info_copy(yytext,yyleng); return BOOLEAN;}
do        { info_copy(yytext,yyleng); return DO;}
else      { info_copy(yytext,yyleng); return ELSE;}
end       { info_copy(yytext,yyleng); return END;}
false     { info_copy(yytext,yyleng); return FALSE;}
function    { info_copy(yytext,yyleng); return FUNCTION;}
if        { info_copy(yytext,yyleng); return IF;}
integer     { info_copy(yytext,yyleng); return INTEGER;}
mod       { info_copy(yytext,yyleng); return MULOP;}
not       { info_copy(yytext,yyleng); return NOT;}
of        { info_copy(yytext,yyleng); return OF;}
or        { info_copy(yytext,yyleng); return ADDOP;}
procedure   { info_copy(yytext,yyleng); return PROCEDURE;}
program     { info_copy(yytext,yyleng); return PROGRAM;}
read      { info_copy(yytext,yyleng); return READ;}
real      { info_copy(yytext,yyleng); return REAL;}
record      { info_copy(yytext,yyleng); return RECORD;}
then      { info_copy(yytext,yyleng); return THEN;}
true      { info_copy(yytext,yyleng); return TRUE;}
var       { info_copy(yytext,yyleng); return VAR;}
while     { info_copy(yytext,yyleng); return WHILE;}
write     { info_copy(yytext,yyleng); return WRITE;}
{id}            { info_copy(yytext,yyleng);  strcat(yylval.Symbol.ccode, "_"); ++(yylval.Symbol.len);  return ID;}
{digits}        {strcpy(yylval.digit_attr.ccode,yytext);
         yylval.digit_attr.num=atoi(yytext);
         yylval.digit_attr.len=yyleng;  return DIGITS;}
{num}         { info_copy(yytext,yyleng); return NUM;}
{errors}            {fprintf(stderr, "词法分析错误\n");}
{ws}            {}
("="|"<"|">"|"<="|"<>"|">=") { info_copy(yytext,yyleng); return RELOP; }
("+"|"-")   { info_copy(yytext,yyleng); return ADDOP; }
("*"|"/")   { info_copy(yytext,yyleng); return MULOP; }
":="      { info_copy(yytext,yyleng); return ASSIGNOP;}
(";"|","|"."|":"|"["|"]"|"("|")") { info_copy(yytext,yyleng); return *yytext;}
"(*"[^/*)]*"*)" {}
"{"[^}]*"}"   {}
"//"(.)*    {}
%%
void info_copy(char* yytext, int yyleng )//复制功能，由yytext,yyleng复制给YACC的全局变量yylval
{
    strcpy(yylval.Symbol.ccode,yytext);//匹配模式的文本存储在yytext这一变量中,由yytext复制给yylval

    yylval.Symbol.len=yyleng;//yyleng给出匹配模式的长度,由yyleng复制给yylval
    //fprintf(stderr, "lexer=%s\n", yytext);
}

int yywrap()
{
  return 1;
}
