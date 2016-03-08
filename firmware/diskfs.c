#include "vga.h"
#include "disk.h"
#include "diskfs.h"

diskfs_sb_t *sb = (diskfs_sb_t *) 0x80004000;
static uint8_t *buffer = (uint8_t *) 0x80005000; /* temporary buffer... */
static int diskid, diskfirst;

int32_t strcmp(const char *str1, const char *str2) {
    uint32_t i = 0;
    while (str1[i] == str2[i] && str1[i]) i++;
    if (str1[i] > str2[i]) return 1;
    else if (str1[i] < str2[i]) return -1;
    else return 0;
}

void read_cluster(diskfs_sb_t *sb, diskfs_pos_t clus, void *dest) {
    disk_readsects(diskid,
                   (int32_t)(diskfirst+(clus*sb->block_size/512)+2),
                   (int32_t)sb->block_size/512,
                   dest);
}

void read_inode(diskfs_sb_t *disksb, diskfs_inode_t *inode, diskfs_ino_t ino) {

    int32_t i;

    /* calculate the location of the cluster that
     * contains the desired inode.
     */
    uint32_t inodes_per_cluster = disksb->block_size/sizeof(diskfs_inode_t);
    diskfs_blk_t cluster = ino/inodes_per_cluster+disksb->inode_start;

    /* read the cluster into memory: */
    read_cluster(disksb, cluster, buffer);

    /* do the read! */
    for (i = 0; i < sizeof(diskfs_inode_t); i ++)
        ((uint8_t *) inode)[i] = buffer[(ino%inodes_per_cluster)*
                                 sizeof(diskfs_inode_t)+i];

}

diskfs_blk_t get_file_block(diskfs_sb_t *sb,
                            diskfs_inode_t *inode,
                            diskfs_blk_t blk_off) {

    /* convert blk_off (which is relative to file)
     * to a block number relative to the beginning
     * of the filesystem.
     */

    diskfs_lvl_t lvl = diskfs_blk_to_lvl(sb, blk_off);
    diskfs_blk_t blk;
    diskfs_blk_t *ptr;
    int32_t i;

    for (i = 0; i <= lvl.level; i++) {

        /* load the table into memory: */
        if (!i) {
            ptr = inode->ptr;
        } else {
            read_cluster(sb, blk, buffer);
            ptr = (diskfs_blk_t *) buffer;
        }

        /* get pointer for next level (if there isn't): */
        if (!(blk = ptr[lvl.ptr[i]])) {
            break; /* exit the loop. */
        }
    }

    /* done */
    return blk;

}

void read_file_block(diskfs_sb_t *sb,
                     diskfs_inode_t *inode,
                     diskfs_blk_t blk_off,
                     void *buf) {

    diskfs_blk_t blk = get_file_block(sb, inode, blk_off);
    if (!blk) {
        int32_t i;
        for(i = 0; i < sb->block_size; i++)
            ((uint8_t *) buf)[i] = 0;
    } else {
        read_cluster(sb, blk, buf);
    }
}

diskfs_ino_t lookup(diskfs_sb_t *sb, diskfs_inode_t *inode, char *name) {

    diskfs_dirent_t *dirents = (diskfs_dirent_t *) buffer;
    int32_t dirents_per_block = sb->block_size/sizeof(diskfs_dirent_t);
    int32_t i = 0; /* counter for blocks. */
    int32_t j = 0; /* counter for dirents per block. */

    /* loop on dirents. */
    while(1) {
        /* beginning of a new block? */
        if (j == 0)
            read_file_block(sb, inode, i++, buffer);

        /* done? */
        if (dirents[j].ino == 0)
            return 0;

        /* name matching? */
        if (dirents[j].ino > 1 && !strcmp(dirents[j].name, name))
            return dirents[j].ino;

        /* next dirent: */
        if (++j == dirents_per_block)
            j = 0;
    }

}

void diskfs_getuuid(char *uuid) {
    int32_t i = 0;
    /*printf("uuid: ");*/
    for (i = 0; i < 17; i++) {
        /*print_fmt("%c%c", "0123456789ABCDEF"[(sb->uuid[i]>>4)&0xF],
                          "0123456789ABCDEF"[(sb->uuid[i]>>0)&0xF]);*/
        uuid[i] = sb->uuid[i];
    }
}

int diskfs_loadfile(int id, int firstsect, char *path, uint32_t base) {

    /* counter */
    int32_t i = 0, j = 0;

    /* root inode: */
    diskfs_ino_t ino = DISKFS_ROOT_INO;
    diskfs_inode_t inode;

    /* store disk info */
    diskid = id;
    diskfirst = firstsect;

    /* get superblock */
    disk_readsects(diskid, diskfirst+2, 1, sb);

    /* loop on path components */
    while (path[i]) {

        /* Read name: */
        char name[32] = {0};
        j = 0;

        while (path[i] == '/')
            i++; /* skip slash. */

        while (path[i] != 0 && path[i] != '/')
            name[j++] = path[i++];

        if (name[0] == 0)
            continue;

        /* look for the name inside the hierarchy: */
        read_inode(sb, &inode, ino);
        if (!(ino = lookup(sb, &inode, name))) {
            /* not found! */
            //print_fmt("<%d:%d>/%s is missing.\n", id, firstsect, path);
            return -1;
        }

    }

    /* load file */
    fmt_attr = 0x0B;
    print_fmt("Loading %s (inode %d) to 0x%x...", path, ino, base);
    read_inode(sb, &inode, ino);
    for (i = 0; i < inode.blocks; i++) {
        uint8_t *dest=(uint8_t*)(base+i*sb->block_size);
        read_file_block(sb,&inode, i, buffer);
        for (j = 0; j < sb->block_size; j++)
            dest[j] = buffer[j];
    }
    print_fmt(" done\n");
    fmt_attr = 0x0F;

    /* done */
    return 0;

}
