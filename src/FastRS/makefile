#

FastRS:			FastRS.asm
  @FlexRev FastRS_rev IR
	dasm FastRS.asm -oFastRS -DPAL -DC64
	copy FastRS /64bin/
	dasm FastRS.asm -oFastRS_NTSC -DNTSC -DC64 
	copy FastRS_NTSC /64bin/
	dasm FastRS.asm -oFastRS20 -DPAL -DVIC20
	copy FastRS20 /20bin/FastRS
	dasm FastRS.asm -oFastRS20_NTSC -DNTSC -DVIC20
	copy FastRS20_NTSC /20bin/FastRS_NTSC

#
