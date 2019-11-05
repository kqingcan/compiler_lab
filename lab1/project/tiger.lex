%{
#include <string.h>
#include "util.h"
#include "tokens.h"
#include "errormsg.h"

int charPos=1;

int yywrap(void)
{
 charPos=1;
 return 1;
}


void adjust(void)
{
 EM_tokPos=charPos;
 charPos+=yyleng;
}

int commentNestNum = 0;
char *charArr;
unsigned int capacity;
unsigned int stringPos = 0;

void init_charArr(void)
{
    capacity = 16;
    charArr = checked_malloc(capacity);
}

void check_if_full(int arrLen)
{
    if(arrLen == capacity){
        char *temp;
        capacity *= 2;
        temp = checked_malloc(capacity);
        memcpy(temp, charArr, capacity);
        free(charArr);
        charArr = temp;
    }
}

void add_char(char newChar)
{
    size_t length = strlen(charArr);
    check_if_full(length);
    charArr[length] = newChar;
}

%}

%x INNER_COMMENT INNER_STRING

%%
<INNER_COMMENT>{
    /* inner comment nest */
    "/*" {adjust();commentNestNum += 1;continue;}
    "*/" {adjust();commentNestNum -= 1;if (commentNestNum == 0) {BEGIN(INITIAL);}}
    <<EOF>> {EM_error(EM_tokPos, "Encounter EOF.");yyterminate();}
    \n  {adjust();EM_newline();continue;}
    . {adjust();}
}


<INNER_STRING>{
    \" {adjust(); yylval.sval = (charArr[0]=='\0') ? "(null)" : charArr; EM_tokPos = stringPos; BEGIN(INITIAL); return STRING;}
    \n {adjust();EM_error(EM_tokPos, "Unterminated string constant!"); yyterminate();}
    \\n {adjust();add_char('\n');}
    \\t {adjust();add_char('\t');}
    \\r {adjust();add_char('\r');}
    \\b {adjust();add_char('\b');}
    \\f {adjust();add_char('\f');}
    \\\" {adjust();add_char('"');}
    \\' {adjust();add_char('\'');}
    "\\/" {adjust();add_char('/');}
    \\\\ {adjust();add_char('\\');}
    <<EOF>> {EM_error(EM_tokPos, "Encounter EOF.");yyterminate();}
    . {adjust();char *yptr = yytext; while (*yptr) {add_char(*yptr++);}}
}



[ \r\t]	 {adjust(); continue;}
\n	 {adjust(); EM_newline(); continue;}

","	  {adjust(); return COMMA;}
":"   {adjust(); return COLON;}
";"   {adjust(); return SEMICOLON;}
"("   {adjust(); return LPAREN;}
")"   {adjust(); return RPAREN;}
"["   {adjust(); return LBRACK;}
"]"   {adjust(); return RBRACK;}
"{"   {adjust(); return LBRACE;}
"}"   {adjust(); return RBRACE;}
"."   {adjust(); return DOT;}
"+"   {adjust(); return PLUS;}
"-"   {adjust(); return MINUS;}
"*"   {adjust(); return TIMES;}
"/"   {adjust(); return DIVIDE;}
"="   {adjust(); return EQ;}
"<>"  {adjust(); return NEQ;}
"<"   {adjust(); return LT;}
"<="  {adjust(); return LE;}
">"   {adjust(); return GT;}
">="  {adjust(); return GE;}
"&"   {adjust(); return AND;}
"|"   {adjust(); return OR;}
":="  {adjust(); return ASSIGN;}


array    {adjust(); return ARRAY;}
if       {adjust(); return IF;}
then     {adjust(); return THEN;}
else     {adjust(); return ELSE;}
while    {adjust(); return WHILE;}
for  	 {adjust(); return FOR;}
to       {adjust(); return TO;}
do       {adjust(); return DO;}
let      {adjust(); return LET;}
in       {adjust(); return IN;}
end      {adjust(); return END;}
of       {adjust(); return OF;}
break    {adjust(); return BREAK;}
nil      {adjust(); return NIL;}
function {adjust(); return FUNCTION;}
var      {adjust(); return VAR;}
type     {adjust(); return TYPE;}



[0-9]+	 {adjust(); yylval.ival=atoi(yytext); return INT;}
[a-z|A-Z]+[a-z|A-Z|0-9|_]*  {adjust(); yylval.sval = yytext; return ID;}
\"  {adjust();init_charArr();stringPos = charPos - 1;BEGIN(INNER_STRING);}
"/*" {adjust();commentNestNum += 1;BEGIN(INNER_COMMENT);}
"*/" {adjust();EM_error(EM_tokPos, "Comment not open!");yyterminate();}
.	 {adjust();EM_error(EM_tokPos,"illegal token");}






