# Over5 Makefile for Linux
# simply calls src/Over5/Makefile

all::
	cd src/Over5; $(MAKE) 
	cp src/Over5/over5 bin
	
# eof

