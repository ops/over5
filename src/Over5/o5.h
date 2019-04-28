
/*************************************************************************
**
** o5.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

void o5_WriteFile(int argc, char **argv);
void o5_ReadFile(int argc, char **argv);
void o5_Copy(int argc, char **argv);
void o5_Dir(int argc, char **argv);
void o5_Status(int argc, char **argv);
void o5_Command(int argc, char **argv);

void o5_WriteDisk(int argc, char **argv);
void o5_WriteZip(int argc, char **argv);
void o5_ReadDisk(int argc, char **argv);
void o5_ReadZip(int argc, char **argv);

void o5_WriteMem(int argc, char **argv);
void o5_ReadMem(int argc, char **argv);
void o5_Sys(int argc, char **argv);
void o5_Run(int argc, char **argv);
void o5_Reset(int argc, char **argv);

void o5_SimpleWrite(int argc, char **argv);
void o5_SimpleRead(int argc, char **argv);
void o5_Boot(int argc, char **argv);
void o5_Test(int argc, char **argv);

void o5_Server(int argc, char **argv);
