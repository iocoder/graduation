/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> Device Filesystem Driver.                        | |
 *        | +------------------------------------------------------+ |
 *        +----------------------------------------------------------+
 *
 * This file is part of Quafios 2.0.1 source code.
 * Copyright (C) 2015  Mostafa Abd El-Aziz Mohamed.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Quafios.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Visit http://www.quafios.com/ for contact information.
 *
 */

#include <arch/type.h>
#include <lib/string.h>
#include <sys/mm.h>
#include <sys/fs.h>
#include <fs/tmpfs.h>

super_block_t *devfs_sb = NULL;

typedef struct devfs_file {
    struct devfs_file *next;
    char *filename;
    int32_t devid;
} devfs_file_t;

static devfs_file_t *staging = NULL;

/***************************************************************************/
/*                              read_super                                 */
/***************************************************************************/

super_block_t *devfs_read_super(device_t *dev) {
    if (devfs_sb)
        return devfs_sb;
    else {
        int32_t i;
        inode_t *root;
        /* mount devfs for the first time */
        devfs_sb = (super_block_t *) tmpfs_read_super(dev);
        devfs_sb->fsdriver = &devfs_t;
        /* create device files */
        root = (inode_t *) iget(devfs_sb, devfs_sb->root_ino);
        while (staging) {
            devfs_file_t *df = staging;
            staging = staging->next;
            tmpfs_mknod(root, df->filename, FT_SPECIAL, df->devid);
            kfree(df->filename);
            kfree(df);
        }
        iput(root);
        return devfs_sb;
    }
}

/***************************************************************************/
/*                              write_super                                */
/***************************************************************************/

int32_t devfs_write_super(super_block_t *sb) {
    return tmpfs_write_super(sb);
}

/***************************************************************************/
/*                               put_super                                 */
/***************************************************************************/

int32_t devfs_put_super(super_block_t *sb) {
    return ESUCCESS;
}

/***************************************************************************/
/*                              read_inode()                               */
/***************************************************************************/

int32_t devfs_read_inode(inode_t *inode) {
    return tmpfs_read_inode(inode);
}

/***************************************************************************/
/*                             update_inode()                              */
/***************************************************************************/

int32_t devfs_update_inode(inode_t *inode) {
    return tmpfs_update_inode(inode);
}

/***************************************************************************/
/*                              put_inode()                                */
/***************************************************************************/

int32_t devfs_put_inode(inode_t *inode) {
    return tmpfs_put_inode(inode);
}

/***************************************************************************/
/*                                lookup()                                 */
/***************************************************************************/

int32_t devfs_lookup(inode_t *dir, char *name, inode_t **ret) {
    return tmpfs_lookup(dir, name, ret);
}

/***************************************************************************/
/*                                 mknod()                                 */
/***************************************************************************/

int32_t devfs_mknod(inode_t *dir, char *name, int32_t mode, int32_t devid) {
    return tmpfs_mknod(dir, name, mode, devid);
}

/***************************************************************************/
/*                                link()                                   */
/***************************************************************************/

int32_t devfs_link(inode_t *inode, inode_t *dir, char *name) {
    return tmpfs_link(inode, dir, name);
}

/***************************************************************************/
/*                               unlink()                                  */
/***************************************************************************/

int32_t devfs_unlink(inode_t *dir, char *name) {
    return tmpfs_unlink(dir, name);
}

/***************************************************************************/
/*                                mkdir()                                  */
/***************************************************************************/

int32_t devfs_mkdir(inode_t *dir, char *name, int32_t mode) {
    return tmpfs_mkdir(dir, name, mode);
}

/***************************************************************************/
/*                                rmdir()                                  */
/***************************************************************************/

int32_t devfs_rmdir(inode_t *dir, char *name) {
    return tmpfs_rmdir(dir, name);
}

/***************************************************************************/
/*                               truncate()                                */
/***************************************************************************/

int32_t devfs_truncate(inode_t *inode, pos_t length) {
    return tmpfs_truncate(inode, length);
}

/***************************************************************************/
/*                                 open()                                 */
/***************************************************************************/

int32_t devfs_open(file_t *file) {
    return tmpfs_open(file);
}

/***************************************************************************/
/*                                release()                                */
/***************************************************************************/

int32_t devfs_release(file_t *file) {
    return tmpfs_release(file);
}

/***************************************************************************/
/*                                 read()                                  */
/***************************************************************************/

int32_t devfs_read(file_t *file, void *buf, int32_t size) {
    return tmpfs_read(file, buf, size);
}

/***************************************************************************/
/*                                 write()                                 */
/***************************************************************************/

int32_t devfs_write(file_t *file, void *buf, int32_t size) {
    return tmpfs_write(file, buf, size);
}

/***************************************************************************/
/*                                 seek()                                  */
/***************************************************************************/

int32_t devfs_seek(file_t *file, pos_t newpos) {
    return tmpfs_seek(file, (pos_t) newpos);
}

/***************************************************************************/
/*                                readdir()                                */
/***************************************************************************/

int32_t devfs_readdir(file_t *file, dirent_t *dirent) {
    return tmpfs_readdir(file, dirent);
}

/***************************************************************************/
/*                                 ioctl()                                 */
/***************************************************************************/

int32_t devfs_ioctl(file_t *file, int32_t cmd, void *arg) {
    return tmpfs_ioctl(file, cmd, arg);
}

/***************************************************************************/
/*                               fsdriver_t                                */
/***************************************************************************/

fsd_t devfs_t = {

    /* alias:        */ "devfs",
    /* flags:        */ 0,

    /* read_super:   */ devfs_read_super,
    /* write_super:  */ devfs_write_super,
    /* put_super:    */ devfs_put_super,
    /* read_inode:   */ devfs_read_inode,
    /* update_inode: */ devfs_update_inode,
    /* put_inode:    */ devfs_put_inode,

    /* lookup:       */ devfs_lookup,
    /* mknod:        */ devfs_mknod,
    /* link:         */ devfs_link,
    /* unlink:       */ devfs_unlink,
    /* mkdir:        */ devfs_mkdir,
    /* rmdir:        */ devfs_rmdir,
    /* truncate:     */ devfs_truncate,

    /* open:         */ devfs_open,
    /* release:      */ devfs_release,
    /* read:         */ devfs_read,
    /* write:        */ devfs_write,
    /* seek:         */ devfs_seek,
    /* readdir:      */ devfs_readdir,
    /* ioctl:        */ devfs_ioctl

};

/***************************************************************************/
/*                               devfs_reg()                               */
/***************************************************************************/

void devfs_reg(char *name, int32_t devid) {
    if (devfs_sb) {
        /* create node normally */
        inode_t *root = (inode_t *) iget(devfs_sb, devfs_sb->root_ino);
        tmpfs_mknod(root, name, FT_SPECIAL, devid);
        iput(root);
    } else {
        /* add to staging */
        devfs_file_t *cur = staging;
        devfs_file_t *devfs_file = kmalloc(sizeof(devfs_file_t));
        devfs_file->filename = kmalloc(strlen(name)+1);
        strcpy(devfs_file->filename, name);
        devfs_file->devid = devid;
        devfs_file->next = NULL;
        if (!staging) {
            staging = devfs_file;
        } else {
            while (cur->next) {
                cur = cur->next;
            }
            cur->next = devfs_file;
        }
    }
}

/***************************************************************************/
/*                              devfs_unreg()                              */
/***************************************************************************/

void devfs_unreg(char *name) {
    if (devfs_sb) {
        /* create node normally */
        inode_t *root = (inode_t *) iget(devfs_sb, devfs_sb->root_ino);
        tmpfs_unlink(root, name);
        iput(root);
    } else {
        /* remove from staging */
        devfs_file_t *prev = NULL;
        devfs_file_t *cur  = staging;
        while (cur) {
            if (!strcmp(cur->filename, name)) {
                if (!prev) {
                    staging = cur->next;
                } else {
                    prev->next = cur->next;
                }
                kfree(cur->filename);
                kfree(cur);
                break;
            }
            cur = cur->next;
        }
    }
}
