#

DiskSlave:   ds_main.asm pr_FileTransfer.asm pr_Support.asm pr_RawDisktransfer.asm \
             dsk_Disk.asm dsk_Diskturbo.asm dsk_disksector.asm dsk_pitchtrack.asm \
             bl_Block.asm
  @FlexRev ds_rev IR
	dasm ds_main.asm -oDiskSlave -DPAL 
	copy DiskSlave /64bin/
	dasm ds_main.asm -oDiskSlave_NTSC -DNTSC 
	copy DiskSlave_NTSC /64bin/

MemSlave:     ms_main.asm pr_MemTransfer.asm pr_Support.asm \
              bl_Block.asm 

  @FlexRev ms_rev IR
	dasm ms_main.asm -oMemSlave -DPAL -DAT0801
	copy MemSlave /64bin/
	dasm ms_main.asm -oMemSlave_NTSC -DNTSC -DAT0801
	copy MemSlave_NTSC /64bin/
	dasm ms_main.asm -oMemSlaveC800 -DPAL -DATC800
	copy MemSlaveC800 /64bin/
	dasm ms_main.asm -oMemSlaveC800_NTSC -DNTSC -DATC800 
	copy MemSlaveC800_NTSC /64bin/

CartSlave:   cs_main.asm pr_MemTransfer.asm pr_FileTransfer.asm pr_Support.asm pr_SerFile.asm\
             pr_RawdiskTransfer.asm \
             dsk_Disk.asm dsk_Diskturbo.asm dsk_disksector.asm dsk_pitchtrack.asm \
             bl_Block.asm
  @FlexRev cs_rev IR
	dasm cs_main.asm -oCartSlave -DPAL 
	copy CartSlave /64bin/
	dasm cs_main.asm -oCartSlave_NTSC -DNTSC 
	copy CartSlave_NTSC /64bin/

SerFile:     sf_main.asm pr_SerFile.asm pr_Support.asm \
             bl_Block.asm
  @FlexRev sf_rev IR
	dasm sf_main.asm -oSerFile -DPAL 
	copy SerFile /64bin/
	dasm sf_main.asm -oSerFile_NTSC -DNTSC 
	copy SerFile_NTSC /64bin/

#
