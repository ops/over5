
/*************************************************************************
**
** o5protocol.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

#ifndef _O5PROTOCOL_H
#define _O5PROTOCOL_H

#include <sys/types.h>

#define HEADER_FILENAMELEN  24
#define TIMEOUT_FILEWAIT  360

struct o_header {
    u_int8_t ohd_type;
    u_int8_t ohd_subtype;
};


/**************************************************************************
**
** MEMORY TRANSFER
**
** - WRITEMEM
** 1. SEND WMHD
** 2. WAIT FOR RESPONSE
** 3. SEND BODY (channel 1)
** 4. WAIT FOR RESPONSE
**
** - READMEM
** 1. SEND RMHD
** 2. WAIT FOR RESPONSE
** 3. RECEIVE BODY (channel 1)
** 4. SEND OK
**
** - SYS
** 1. SEND SYHD
** 2. WAIT FOR RESPONSE
**
** - RUN
** 1. SEND RUHD
** 2. WAIT FOR RESPONSE
**
******/
#define TYPE_MEMTRANSFER  0x01

#define SUB_MT_WRITEMEM   0x01
#define SUB_MT_READMEM    0x02
#define SUB_MT_SYS        0x03
#define SUB_MT_RUN        0x04

struct wm_header {
    u_int8_t wmhd_type;
    u_int8_t wmhd_subtype;
    u_int8_t wmhd_start_l;
    u_int8_t wmhd_start_h;
    u_int8_t wmhd_end_l;
    u_int8_t wmhd_end_h;
};

struct rm_header {
    u_int8_t rmhd_type;
    u_int8_t rmhd_subtype;
    u_int8_t rmhd_start_l;
    u_int8_t rmhd_start_h;
    u_int8_t rmhd_end_l;
    u_int8_t rmhd_end_h;
};

struct sy_header {
    u_int8_t syhd_type;
    u_int8_t syhd_subtype;
    u_int8_t syhd_pc_l;
    u_int8_t syhd_pc_h;
    u_int8_t syhd_memory;
    u_int8_t syhd_sr;
    u_int8_t syhd_ac;
    u_int8_t syhd_xr;
    u_int8_t syhd_yr;
    u_int8_t syhd_sp;
};

struct ru_header {
    u_int8_t ruhd_type;
    u_int8_t ruhd_subtype;
    u_int8_t ruhd_lowmem_l;
    u_int8_t ruhd_lowmem_h;
    u_int8_t ruhd_himem_l;
    u_int8_t ruhd_himem_h;
};

/**************************************************************************
**
** DISKCOMMAND
**
** - DIRECTORY
** 1. SEND DRHD
** 2. WAIT FOR RESPONSE
** 3. c64 LOADs FILE
** 4. WAIT FOR RESPONSE + FILESIZE (DRRS)
** 5. SEND OK
** 6. RECEIVE BODY (channel 1)
** 7. SEND OK
**
** - STATUS
** 1. SEND STHD
** 2. WAIT FOR RESPONSE
** 3. READ ONE BLOCK ON CHANNEL 1
** 4. SEND OK
**
** - COMMAND
** 1. SEND CMHD
** 2. WAIT FOR RESPONSE
** 3. SEND ONE BLOCK ON CHANNEL 1
** 4. WAIT FOR RESPONSE
**
******/
#define TYPE_DISKCOMMAND  0x03

#define SUB_DC_DIRECTORY  0x01
#define SUB_DC_STATUS     0x02
#define SUB_DC_COMMAND    0x03


struct dr_header {
    u_int8_t drhd_type;
    u_int8_t drhd_subtype;
    u_int8_t drhd_pad[2];
    u_int8_t drhd_device;
    u_int8_t drhd_filename[24];
};


struct dr_response {
    u_int8_t drrs_response;
    u_int8_t drrs_len_l;
    u_int8_t drrs_len_h;
};

struct st_header {
    u_int8_t sthd_type;
    u_int8_t sthd_subtype;
    u_int8_t sthd_pad[2];
    u_int8_t sthd_device;
};
struct cm_header {
    u_int8_t cmhd_type;
    u_int8_t cmhd_subtype;
    u_int8_t cmhd_pad[2];
    u_int8_t cmhd_device;
};


/**************************************************************************
**
** FILE TRANSFER
**
** - WRITEFILE
** 1. SEND WFHD
** 2. WAIT FOR RESPONSE
** 3. SEND BODY (channel 1)
** 4. c64 SAVEs FILE
** 5. WAIT FOR RESPONSE
**
** - READFILE
** 1. SEND RFHD
** 2. WAIT FOR RESPONSE
** 3. c64 LOADs FILE
** 4. WAIT FOR RESPONSE + FILESIZE (RFRS)
** 5. SEND OK
** 6. RECEIVE BODY (channel 1)
** 7. SEND OK
**
******/
#define TYPE_FILETRANSFER 0x02

#define SUB_FT_WRITEFILE  0x01
#define SUB_FT_READFILE   0x02

struct wf_header {
    u_int8_t wfhd_type;
    u_int8_t wfhd_subtype;
    u_int8_t wfhd_len_l;
    u_int8_t wfhd_len_h;
    u_int8_t wfhd_device;
    u_int8_t wfhd_filename[24];
};

struct rf_header {
    u_int8_t rfhd_type;
    u_int8_t rfhd_subtype;
    u_int8_t rfhd_pad[2];
    u_int8_t rfhd_device;
    u_int8_t rfhd_filename[24];
};


struct rf_response {
    u_int8_t rfrs_response;
    u_int8_t rfrs_len_l;
    u_int8_t rfrs_len_h;
};


/**************************************************************************
**
** RAWDISKTRANSFER
**
** - WRITETRACK
** 1. SEND WTHD
** 2. WAIT FOR RESPONSE
** 3. SEND BODY (channel 1)
** 4. c64 WRITEs TRACK
** 5. WAIT FOR RESPONSE
**
** - READTRACK
** 1. SEND RTHD
** 2. WAIT FOR RESPONSE
** 3. c64 READs TRACK
** 4. WAIT FOR RESPONSE + NUM SECTORS (RTRS)
** 5. SEND OK
** 6. RECEIVE BODY (channel 1)
** 7. SEND OK
**
** - WRITESECTOR
** 1. SEND WSHD
** 2. WAIT FOR RESPONSE
** 3. SEND BODY (channel 1)
** 4. c64 WRITEs SECTOR
** 5. WAIT FOR RESPONSE
**
** - READSECTOR
** 1. SEND RSHD
** 2. WAIT FOR RESPONSE
** 3. c64 READs SECTOR
** 4. WAIT FOR RESPONSE
** 5. RECEIVE BODY (channel 1)
** 6. SEND OK
**
******/
#define TYPE_RAWDISKTRANSFER 0x06

#define SUB_RT_WRITETRACK 0x01
#define SUB_RT_READTRACK 0x02
#define SUB_RT_WRITESECTOR 0x03
#define SUB_RT_READSECTOR 0x04

struct wt_header {
    u_int8_t wthd_type;
    u_int8_t wthd_subtype;
    u_int8_t wthd_track;
    u_int8_t wthd_numtracks;
    u_int8_t wthd_device;
};


struct rt_header {
    u_int8_t rthd_type;
    u_int8_t rthd_subtype;
    u_int8_t rthd_track;
    u_int8_t rthd_numtracks;
    u_int8_t rthd_device;
};

struct rt_response {
    u_int8_t rtrs_response;
    u_int8_t rtrs_sectors;
};

struct ws_header {
    u_int8_t wshd_type;
    u_int8_t wshd_subtype;
    u_int8_t wshd_track;
    u_int8_t wshd_sector;
    u_int8_t wshd_device;
};

struct rs_header {
    u_int8_t rshd_type;
    u_int8_t rshd_subtype;
    u_int8_t rshd_track;
    u_int8_t rshd_sector;
    u_int8_t rshd_device;
};


/**************************************************************************
**
** TEST COMMAND
**
******/
#define TYPE_TESTCOMMAND  0x04

#define SUB_TC_BLOCKTEST  0x01
#define SUB_TC_FILETEST   0x02

struct bt_header {
    u_int8_t bthd_type;
    u_int8_t bthd_subtype;
};

struct ft_header {
    u_int8_t fthd_type;
    u_int8_t fthd_subtype;
    u_int8_t fthd_len_l;
    u_int8_t fthd_len_h;
};
struct ft_response {
    u_int8_t ftrs_response;
    u_int8_t ftrs_len_l;
    u_int8_t ftrs_len_h;
};




/**************************************************************************
**
** SERVER PROTOCOL
**
** - LOAD
** 1. GOT SRVLDHD
** 2. SEND RESPONSE (OK, NOTSUPPORTED, STRING)+ filelen
** 3. WAIT FOR RESPONSE + newstart (srvldrs2)
** 4. SEND BODY (channel 1)
** 5. WAIT FOR RESPONSE
**
** - SAVE
** 1. GOT SRVSVHD
** 2. SEND RESPONSE (OK, NOTSUPPORTED, STRING)
** 3. RECEIVE BODY (channel 1)
** 4. SEND RESPONSE (OK, NOTSUPPORTED, STRING)
**
** - COMMAND
** 1. GOT SRVCMHD
** 2. SEND RESPONSE (OK, NOTSUPPORTED, STRING)
**
** - READSTRING
** 1. GOT SRVRSHD
** 2. SEND RESPONSE (OK, NOTSUPPORTED, STRING)+ rows
** 3. WAIT FOR OK
** 4. SEND BODY (channel 1)
**
******/
#define TYPE_SERVER 0x05

#define SUB_SRV_LOAD 0x01
#define SUB_SRV_SAVE 0x02
#define SUB_SRV_COMMAND 0x03
#define SUB_SRV_READSTRING 0x04

struct srvld_header {
    u_int8_t srvldhd_type;
    u_int8_t srvldhd_subtype;
    u_int8_t srvldhd_pad[4];
    u_int8_t srvldhd_filename[64];
};

struct srvld_response {
    u_int8_t srvldrs_response;
    u_int8_t srvldrs_start_l;
    u_int8_t srvldrs_start_h;
    u_int8_t srvldrs_end_l;
    u_int8_t srvldrs_end_h;
};

struct srvld_response2 {
    u_int8_t srvldrs2_response;
    u_int8_t srvldrs2_start_l;
    u_int8_t srvldrs2_start_h;
};

struct srvsv_header {
    u_int8_t srvsvhd_type;
    u_int8_t srvsvhd_subtype;
    u_int8_t srvsvhd_start_l;
    u_int8_t srvsvhd_start_h;
    u_int8_t srvsvhd_end_l;
    u_int8_t srvsvhd_end_h;
    u_int8_t srvsvhd_filename[64];
};


struct srvcm_header {
    u_int8_t srvcmhd_type;
    u_int8_t srvcmhd_subtype;
    u_int8_t srvcmhd_pad[4];
    u_int8_t srvcmhd_command[64];
};


struct srvrs_header {
    u_int8_t srvrshd_type;
    u_int8_t srvrshd_subtype;
    u_int8_t srvrshd_width;
    u_int8_t srvrshd_height;
};

struct srvrs_response {
    u_int8_t srvrsrs_response;
    u_int8_t srvrsrs_rows;
};

#define SRVRS_MOREMASK  0x80

/**************************************************************************
**
** RESPONSE CODES
**
******/
#define RESP_OK           0x80
#define RESP_NOTSUPPORTED 0x81
#define RESP_ERROR        0x82
#define RESP_STRING       0x83

#endif /* _O5PROTOCOL_H */
/* eof */
