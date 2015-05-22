my: mylexer.l myparser.y propertylist.c
	bison -d myparser.y
	flex mylexer.l
	cc -o $@ myparser.tab.c lex.yy.c propertylist.c -lfl