#include "disk.h"
#include "mbr.h"

typedef struct partent {
    unsigned char status;
    unsigned char first_chs[3];
    unsigned char parttype;
    unsigned char last_chs[3];
    unsigned int  first_lba;
    unsigned int  sectcount;
} __attribute__((packed)) partent_t;

typedef struct mbr {
    unsigned char  bootloader[446];
    partent_t      partents[4];
    unsigned short signature;
} __attribute__((packed, aligned(512))) mbr_t;

mbr_t mbr;

#define READ_UNALIGNED_INT(n)    ((((unsigned char *) &n)[0]<< 0) | \
                                  (((unsigned char *) &n)[1]<< 8) | \
                                  (((unsigned char *) &n)[2]<<16) | \
                                  (((unsigned char *) &n)[3]<<24))

#define READ_UNALIGNED_SHORT(n)  ((((unsigned char *) &n)[0]<< 0) | \
                                  (((unsigned char *) &n)[1]<< 8))

int find_boot_part(int id) {
    /* find boot partition in MBR disk (id) */
    int i;
    /* MBR */
    disk_readsect(id, 0, (char *) &mbr);
    /* make sure signature is valid */
    if (READ_UNALIGNED_SHORT(mbr.signature) == 0xAA55) {
        /* loop over partition entries */
        for (i = 0; i < 4; i++) {
            /* partition existing and bootable? */
            if (mbr.partents[i].parttype && mbr.partents[i].status == 0x80) {
                /* found boot partition */
                return READ_UNALIGNED_INT(mbr.partents[i].first_lba);
            }
        }
    }
    /* no boot partition found */
    return -1;
}
