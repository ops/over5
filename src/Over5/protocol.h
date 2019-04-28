
/*************************************************************************
**
** Protocol.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

/* pr_protocol.c */
void bl_blocktest(void);
void bl_filetest(void);
void bl_sendfile(char *file,u_int8_t *buffer,u_int32_t len,int device);
void bl_recvfile(char *file,u_int8_t **buffer,u_int32_t *len,int device);
void bl_recvdir(char *file,u_int8_t **buffer,u_int32_t *len,int device);
void bl_recvstatus(u_int8_t **buffer,u_int32_t *len,int device);
void bl_sendcommand(u_int8_t *buffer,u_int32_t len,int device);
void bl_sendmem(u_int8_t *buffer,u_int32_t addr, u_int32_t len);
void bl_recvmem(u_int8_t *buffer,u_int32_t addr, u_int32_t len);
void bl_sys(u_int32_t pc, u_int8_t memory, u_int8_t sr, u_int8_t ac, u_int8_t xr, u_int8_t yr, u_int8_t sp);
void bl_run(u_int32_t lowmem, u_int32_t himem);
u_int8_t *bl_sendtrack(int track, int numtracks, u_int8_t *buffer,int device);
u_int8_t *bl_recvtrack(int track, int numtracks, u_int8_t *buffer,int device);

/* pr_Support.c */
void writeblock_err(u_int8_t *dataptr, u_int32_t datalen, int channel);
void readblock_err(u_int8_t *dataptr, u_int32_t *datalen, int *channel,int initialtimeout);
void receivebody_err(u_int8_t *dataptr, u_int32_t datalen);
void sendbody_err(u_int8_t *dataptr, u_int32_t datalen);
void checkresponse_err(u_int8_t *buf,u_int32_t len,int timeout);
void respond_err(u_int8_t status);
int receivebody(u_int8_t *dataptr, u_int32_t datalen);
int sendbody(u_int8_t *dataptr, u_int32_t datalen);
int checkresponse(u_int8_t *buf,u_int32_t len,int timeout);
int respond(u_int8_t status);

/* pr_Simple.c */
void slowsend(u_int8_t *buffer, u_int32_t len);
void slowsendnew(u_int8_t *buffer, u_int32_t len, int baudrate, char *name);
void sendfile(u_int8_t *buffer, u_int32_t len);
int receivefile(u_int8_t **buffer, u_int32_t *len);
void sendfile_old(u_int8_t *buffer, u_int32_t len);
int receivefile_old(u_int8_t **buffer, u_int32_t *len);

/* pr_Server.c */
int bl_server(void);
int bl_srvload(struct srvld_header *);
int bl_srvsave(struct srvsv_header *);
int bl_srvcommand(struct srvcm_header *);
int bl_srvreadstring(struct srvrs_header *);


#define PRERR_OK  0
#define PRERR_ERROR 1
#define PRERR_UNKNOWNERROR  0x20
#define PRERR_FORMAT  0x21
#define PRERR_UNEXPECTEDPACKET  0x22
#define PRERR_NOTSUPPORTED  0x23
#define PRERR_COMMANDFAILED 0x24

