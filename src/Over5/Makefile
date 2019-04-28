# Over5 Makefile for Linux
# Mostly copied straight from the win32 one by Martin.

#
# Compiler command definitions
#
CC          = gcc
LD          = gcc
RM          = rm -f

# use these flags for release
CFLAGS      = -Wall -Wno-format -Wno-unused -O2
CPPFLAGS    = -DLINUX_VERSION -I.
LDFLAGS     = -liberty

# use these flags for debugging 
#CFLAGS      = -Wall -Wno-format -Wno-unused -g
#CPPFLAGS    = -DLINUX_VERSION -I. -DPRINTF_DEBUG -DECHO_FUNCTION_CALL
#LDFLAGS     = -g -liberty

OBJDIR       = ./o

#
# Pattern rules to make the .o files end up in directory o
#
$(OBJDIR)/%.o : %.c
	$(CC) -c $(CPPFLAGS) $(CFLAGS) -o $(OBJDIR)/$*.o $*.c
$(OBJDIR)/%.o : %.s
	$(AS) $(ASFLAGS) -o $(OBJDIR)/$*.o $*.s

#
# 
#
TARGET = over5
OBJS =	$(OBJDIR)/bl_block.o \
	$(OBJDIR)/bl_serial.o \
	$(OBJDIR)/cbm_directory.o \
	$(OBJDIR)/cbm_zipcode.o \
	$(OBJDIR)/config.o \
	$(OBJDIR)/convert.o \
	$(OBJDIR)/mach.o \
	$(OBJDIR)/main.o \
	$(OBJDIR)/o5_disk.o \
	$(OBJDIR)/o5_file.o \
	$(OBJDIR)/o5_memory.o \
	$(OBJDIR)/o5_server.o \
	$(OBJDIR)/o5_simple.o \
	$(OBJDIR)/pr_protocol.o \
	$(OBJDIR)/pr_server.o \
	$(OBJDIR)/pr_simple.o \
	$(OBJDIR)/pr_support.o \
	$(OBJDIR)/rdargs.o

## fixa!
HEADERS = block.h booter.h cbm.h config.h convert.h copytail64.h \
	mach.h mach_include.h main.h main_rev.h o5.h o5protocol.h \
	protocol.h rdargs.h

#
# Build executable
#
$(TARGET): $(OBJS) Makefile
	$(LD) -o $(TARGET) $(OBJS) $(LDFLAGS)

#
# Rules for the object files
#
$(OBJDIR)/bl_block.o:           bl_block.c	$(HEADERS)
$(OBJDIR)/bl_serial.o:          bl_serial.c	$(HEADERS)
$(OBJDIR)/cbm_directory.o:      cbm_directory.c $(HEADERS)
$(OBJDIR)/cbm_zipcode.o:        cbm_zipcode.c	$(HEADERS)
$(OBJDIR)/config.o:             config.c	$(HEADERS)
$(OBJDIR)/convert.o:            convert.c	$(HEADERS)
$(OBJDIR)/mach.o:               mach.c		$(HEADERS)
$(OBJDIR)/main.o:               main.c		$(HEADERS)
$(OBJDIR)/o5_disk.o:            o5_disk.c	$(HEADERS)
$(OBJDIR)/o5_file.o:            o5_file.c	$(HEADERS)
$(OBJDIR)/o5_memory.o:          o5_memory.c	$(HEADERS)
$(OBJDIR)/o5_server.o:          o5_server.c	$(HEADERS)
$(OBJDIR)/o5_simple.o:          o5_simple.c	$(HEADERS)
$(OBJDIR)/pr_protocol.o:        pr_protocol.c	$(HEADERS)
$(OBJDIR)/pr_server.o:          pr_server.c	$(HEADERS)
$(OBJDIR)/pr_simple.o:          pr_simple.c	$(HEADERS)
$(OBJDIR)/pr_support.o:         pr_support.c	$(HEADERS)
$(OBJDIR)/rdargs.o:		rdargs.c	$(HEADERS)

#
# Remove executables and object files and backup files
#
clean:
	$(RM) $(OBJDIR)/*.o *~
clobber:
	$(RM) $(TARGET) $(OBJDIR)/*.o *~

all:	$(TARGET)

install: $(TARGET)
	strip $(TARGET)
	mv $(TARGET) ../bin
