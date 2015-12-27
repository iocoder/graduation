/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> Temporary Filesystem Driver.                     | |
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

/* temporarily in this version of tmpfs, the index of an inode
 * is the same value of its memory address.
 */

/***************************************************************************/
/*                              read_super                                 */
/***************************************************************************/

super_block_t *tmpfs_read_super(device_t *dev) {

    /* local variables */
    super_block_t *sb;
    tmpfs_inode_t *tmpfs_inode;
    tmpfs_dentry_t *dot;
    tmpfs_dentry_t *dotdot;

    /* allocate memory for superblock: */
    sb = kmalloc(sizeof(super_block_t));
    if (!sb)
        return NULL;

    /* initialize superblock: */
    sb->fsdriver = &tmpfs_t;
    sb->dev = dev;
    sb->icount = 0;
    sb->mounts = 1;

    /* allocate root inode: */
    tmpfs_inode = kmalloc(sizeof(tmpfs_inode_t));
    if (!tmpfs_inode) {
        kfree(sb);
        return NULL;
    }

    /* initialize the inode: */
    tmpfs_inode->ref   = 1;
    tmpfs_inode->mode  = FT_DIR;
    tmpfs_inode->size  = 0;
    tmpfs_inode->devid = 0;
    linkedlist_init(&(tmpfs_inode->u.blocks));

    /* create <.> directory entry: */
    dot = kmalloc(sizeof(tmpfs_dentry_t));
    if (!dot) {
        kfree(tmpfs_inode);
        kfree(sb);
        return NULL;
    }
    dot->inode = (ino_t) tmpfs_inode;
    dot->name  = kmalloc(2);
    if (!(dot->name)) {
        kfree(dot);
        kfree(tmpfs_inode);
        kfree(sb);
        return NULL;
    }
    dot->name[0] = '.';
    dot->name[1] = 0;
    linkedlist_addlast(&(tmpfs_inode->u.dentries), dot);

    /* create <..> entry: */
    dotdot = kmalloc(sizeof(tmpfs_dentry_t));
    if (!dotdot) {
        kfree(dot->name);
        kfree(dot);
        kfree(tmpfs_inode);
        kfree(sb);
        return NULL;
    }
    dotdot->inode = (ino_t) tmpfs_inode;
    dotdot->name  = kmalloc(3);
    if (!(dotdot->name)) {
        kfree(dotdot);
        kfree(dot->name);
        kfree(dot);
        kfree(tmpfs_inode);
        kfree(sb);
        return NULL;
    }
    dotdot->name[0] = '.';
    dotdot->name[1] = '.';
    dotdot->name[2] = 0;
    linkedlist_addlast(&(tmpfs_inode->u.dentries), dotdot);

    /* Update super block: */
    sb->root_ino = (ino_t) tmpfs_inode;

    /* done: */
    return sb;

}

/***************************************************************************/
/*                              write_super                                */
/***************************************************************************/

int32_t tmpfs_write_super(super_block_t *sb) {

    /* nothing to do here */
    return ESUCCESS;

}

/***************************************************************************/
/*                               put_super                                 */
/***************************************************************************/

int32_t tmpfs_put_super(super_block_t *sb) {

    /* all file descriptors must be closed first: */
    if (sb->icount)
        return EBUSY;

    /* unallocate the tree: */
    /* TODO: FREE RESOURCES RECURSIVELY */

    /* unallocate super block: */
    kfree(sb);

    /* done: */
    return ESUCCESS;
}


/***************************************************************************/
/*                              read_inode()                               */
/***************************************************************************/

int32_t tmpfs_read_inode(inode_t *inode) {

    /* load the tmpfs node: */
    tmpfs_inode_t *tmpfs_inode = (tmpfs_inode_t *) inode->ino;

    /* load data from the tmpfs node to inode: */
    inode->ref     = tmpfs_inode->ref;
    inode->mode    = tmpfs_inode->mode;
    inode->devid   = tmpfs_inode->devid;
    inode->size    = tmpfs_inode->size;
    inode->blksize = BLOCK_SIZE;
    inode->blocks  = (tmpfs_inode->size / BLOCK_SIZE) +
                     ((tmpfs_inode->size % BLOCK_SIZE) ? 1 : 0);
    return ESUCCESS;

}

/***************************************************************************/
/*                             update_inode()                              */
/***************************************************************************/

int32_t tmpfs_update_inode(inode_t *inode) {

    /* load the tmpfs node: */
    tmpfs_inode_t *tmpfs_inode = (tmpfs_inode_t *) inode->ino;

    /* write data from the memory inode to tmpfs: */
    tmpfs_inode->ref   = inode->ref;
    tmpfs_inode->mode  = inode->mode;
    tmpfs_inode->devid = inode->devid;
    tmpfs_inode->size  = inode->size;

    return ESUCCESS;
}

/***************************************************************************/
/*                              put_inode()                                */
/***************************************************************************/

int32_t tmpfs_put_inode(inode_t *inode) {

    /* local variables */
    tmpfs_inode_t *node;
    tmpfs_block_t *p;
    tmpfs_block_t *next;

    /* inode is still referenced? */
    if (inode->icount || inode->ref)
        return ESUCCESS;

    /* erases a tmpfs inode from memory: */
    node = (tmpfs_inode_t *) inode->ino;

    /* if there are data blocks, deallocate them: */
    if ((node->mode & FT_MASK) == FT_REGULAR) {
        p = node->u.blocks.first;
        while (p) {
            next = p->next;
            kfree(p->data);
            kfree(p);
            p = next;
        }
    }

    /* if directory, delete . && .. */
    if ((node->mode & FT_MASK) == FT_DIR) {
        if (node->u.dentries.count > 2)
            return ENOTEMPTY;
        kfree(node->u.dentries.first);
        kfree(node->u.dentries.last);
    }

    /* deallocate the node: */
    kfree(node);

    /* done: */
    return ESUCCESS;

}

/***************************************************************************/
/*                                lookup()                                 */
/***************************************************************************/

int32_t tmpfs_lookup(inode_t *dir, char *name, inode_t **ret) {

    /* local variables */
    tmpfs_inode_t *tmpfs_inode = (tmpfs_inode_t *) dir->ino;
    tmpfs_dentry_t *p;

    /* inode must be a directory. */
    if ((dir->mode & FT_MASK) != FT_DIR)
        return ENOTDIR;

    /* compare "name" with all directory entries in inode: */
    p = tmpfs_inode->u.dentries.first;
    while(p && ((p->inode <= 1) || strcmp(name, p->name)))
        p = p->next;

    /* found? */
    if (!p)
        return ENOENT; /* not found! */

    /* get inode: */
    if (ret) {
        *ret = (inode_t *) iget(dir->sb, p->inode);
        if (!(*ret))
            return ENOMEM;
    }

    /* done: */
    return ESUCCESS;

}

/***************************************************************************/
/*                                 mknod()                                 */
/***************************************************************************/

int32_t tmpfs_mknod(inode_t *dir, char *name, int32_t mode, int32_t devid) {

    /* local variables */
    int32_t err;
    tmpfs_ino_t ino;
    inode_t *inode;
    tmpfs_inode_t *dir_tmpfs_inode = (tmpfs_inode_t *) dir->ino;
    tmpfs_inode_t *nod_tmpfs_inode;
    char *fsname;
    tmpfs_dentry_t *p;

    /* parent must be a directory. */
    if ((dir->mode & FT_MASK) != FT_DIR)
        return ENOTDIR;

    /* parent is already deleted? */
    if (!(dir->ref))
        return ENOENT;

    /* name shouldn't exist. */
    err = tmpfs_lookup(dir, name, NULL);
    if (!err) {
        return EEXIST;
    } else if (err != ENOENT) {
        return err;
    }

    /* allocate a new inode: */
    ino = (tmpfs_ino_t) kmalloc(sizeof(tmpfs_inode_t));
    if (!ino)
        return ENOSPC;
    nod_tmpfs_inode = (tmpfs_inode_t *) ino;
    linkedlist_init(&(nod_tmpfs_inode->u.blocks));

    /* get the inode: */
    inode = (inode_t *) iget(dir->sb, ino);

    /* initialize the inode: */
    inode->ref   = 1;
    inode->mode  = mode;
    inode->size  = 0;
    inode->devid = devid;
    tmpfs_update_inode(inode);

    /* put the inode: */
    iput(inode);

    /* allocate space for name: */
    fsname = kmalloc(strlen(name)+1);
    if (!fsname)
        return ENOMEM;
    strcpy(fsname, name);

    /* look up for an empty entry */
    p = dir_tmpfs_inode->u.dentries.first;
    while(p && (p->inode > 1))
        p = p->next;

    /* no empty entry? allocate a new one! */
    if (!p) {
        if (!(p = kmalloc(sizeof(tmpfs_dentry_t)))) {
            kfree(fsname);
            return ENOMEM;
        }
        linkedlist_addlast(&(dir_tmpfs_inode->u.dentries), p);
        tmpfs_update_inode(dir);
    }

    /* fill in the entry: */
    p->inode = ino;
    p->name  = fsname;

    /* done */
    return ESUCCESS;

}

/***************************************************************************/
/*                                link()                                   */
/***************************************************************************/

int32_t tmpfs_link(inode_t *inode, inode_t *dir, char *name) {

    /* local variables */
    int32_t err;
    tmpfs_inode_t *dir_tmpfs_inode = (tmpfs_inode_t *) dir->ino;
    char *fsname;
    tmpfs_dentry_t *p;

    /* parent must be a directory. */
    if ((dir->mode & FT_MASK) != FT_DIR)
        return ENOTDIR;

    /* parent is already deleted? */
    if (!(dir->ref))
        return ENOENT;

    /* name shouldn't exist. */
    err = tmpfs_lookup(dir, name, NULL);
    if (!err) {
        return EEXIST;
    } else if (err != ENOENT) {
        return err;
    }

    /* inode should not be directory: */
    if ((inode->mode & FT_MASK) == FT_DIR)
        return EISDIR;

    /* increase references count: */
    inode->ref++;
    tmpfs_update_inode(inode);

    /* allocate space for name: */
    fsname = kmalloc(strlen(name)+1);
    if (!fsname)
        return ENOMEM;
    strcpy(fsname, name);

    /* look up for an empty entry */
    p = dir_tmpfs_inode->u.dentries.first;
    while(p && (p->inode > 1))
        p = p->next;

    /* no empty entry? allocate a new one! */
    if (!p) {
        if (!(p = kmalloc(sizeof(tmpfs_dentry_t)))) {
            kfree(fsname);
            return ENOMEM;
        }
        linkedlist_addlast(&(dir_tmpfs_inode->u.dentries), p);
        tmpfs_update_inode(dir);
    }

    /* fill in the entry: */
    p->inode = inode->ino;
    p->name  = fsname;

    /* done */
    return ESUCCESS;

}

/***************************************************************************/
/*                               unlink()                                  */
/***************************************************************************/

int32_t tmpfs_unlink(inode_t *dir, char *name) {

    /* local variables */
    int32_t err;
    tmpfs_inode_t *dir_tmpfs_inode = (tmpfs_inode_t *) dir->ino;
    tmpfs_dentry_t *p;
    inode_t *inode;

    /* parent must be a directory. */
    if ((dir->mode & FT_MASK) != FT_DIR)
        return ENOTDIR;

    /* parent is already deleted? */
    if (!(dir->ref))
        return ENOENT;

    /* look up for the matching entry: */
    p = dir_tmpfs_inode->u.dentries.first;
    while(p && (p->inode==0 || p->inode==1 || strcmp(name, p->name)))
        p = p->next;

    /* found? */
    if (!p)
        return ENOENT; /* not found! */

    /* get the inode */
    inode = (inode_t *) iget(dir->sb, p->inode);

    /* directory? */
    if ((inode->mode & FT_MASK) == FT_DIR) {
        iput(inode);
        return EISDIR;
    }

    /* decrease references: */
    inode->ref--;
    tmpfs_update_inode(inode);

    /* put the inode */
    iput(inode);

    /* remove entry */
    p->inode = 1;
    kfree(p->name);

    /* done: */
    return ESUCCESS;

}

/***************************************************************************/
/*                                mkdir()                                  */
/***************************************************************************/

int32_t tmpfs_mkdir(inode_t *dir, char *name, int32_t mode) {

    /* local variables */
    int32_t err;
    tmpfs_inode_t *dir_tmpfs_inode = (tmpfs_inode_t *) dir->ino;
    tmpfs_inode_t *nod_tmpfs_inode;
    tmpfs_ino_t ino;
    inode_t *inode;
    char *fsname;
    tmpfs_dentry_t *p, *dot, *dotdot;

    /* parent must be a directory. */
    if ((dir->mode & FT_MASK) != FT_DIR)
        return ENOTDIR;

    /* parent is already deleted? */
    if (!(dir->ref))
        return ENOENT;

    /* name shouldn't exist. */
    err = tmpfs_lookup(dir, name, NULL);
    if (!err) {
        return EEXIST;
    } else if (err != ENOENT) {
        return err;
    }

    /* allocate a new inode: */
    ino = (tmpfs_ino_t) kmalloc(sizeof(tmpfs_inode_t));
    if (!ino)
        return ENOSPC;
    nod_tmpfs_inode = (tmpfs_inode_t *) ino;
    linkedlist_init(&(nod_tmpfs_inode->u.blocks));

    /* get the inode: */
    inode = (inode_t *) iget(dir->sb, ino);

    /* initialize the inode: */
    inode->ref   = 1;
    inode->mode  = mode;
    inode->size  = 0;
    inode->devid = 0;
    tmpfs_update_inode(inode);

    /* put the inode: */
    iput(inode);

    /* create <.> directory entry: */
    dot = kmalloc(sizeof(tmpfs_dentry_t));
    if (!dot) {
        return ENOMEM;
    }
    dot->inode = (ino_t) nod_tmpfs_inode;
    dot->name  = kmalloc(2);
    if (!(dot->name)) {
        kfree(dot);
        return ENOMEM;
    }
    dot->name[0] = '.';
    dot->name[1] = 0;
    linkedlist_addlast(&(nod_tmpfs_inode->u.dentries), dot);

    /* create <..> entry: */
    dotdot = kmalloc(sizeof(tmpfs_dentry_t));
    if (!dotdot) {
        return ENOMEM;
    }
    dotdot->inode = (ino_t) dir_tmpfs_inode;
    dotdot->name  = kmalloc(3);
    if (!(dotdot->name)) {
        kfree(dotdot);
        return ENOMEM;
    }
    dotdot->name[0] = '.';
    dotdot->name[1] = '.';
    dotdot->name[2] = 0;
    linkedlist_addlast(&(nod_tmpfs_inode->u.dentries), dotdot);

    /* allocate space for name of the directory: */
    fsname = kmalloc(strlen(name)+1);
    if (!fsname)
        return ENOMEM;
    strcpy(fsname, name);

    /* look up for an empty entry in the parent */
    p = dir_tmpfs_inode->u.dentries.first;
    while(p && (p->inode > 1))
        p = p->next;

    /* no empty entry? allocate a new one! */
    if (!p) {
        if (!(p = kmalloc(sizeof(tmpfs_dentry_t)))) {
            kfree(fsname);
            return ENOMEM;
        }
        linkedlist_addlast(&(dir_tmpfs_inode->u.dentries), p);
        tmpfs_update_inode(dir);
    }

    /* fill in the entry: */
    p->inode = ino;
    p->name  = fsname;

    /* done */
    return ESUCCESS;

}

/***************************************************************************/
/*                                rmdir()                                  */
/***************************************************************************/

int32_t tmpfs_rmdir(inode_t *dir, char *name) {

    /* local variables */
    int32_t err;
    tmpfs_inode_t *dir_tmpfs_inode = (tmpfs_inode_t *) dir->ino;
    tmpfs_inode_t *nod_tmpfs_inode;
    tmpfs_dentry_t *p, *pp;
    inode_t *inode;
    pos_t entcount = 0;

    /* parent must be a directory. */
    if ((dir->mode & FT_MASK) != FT_DIR)
        return ENOTDIR;

    /* parent is already deleted? */
    if (!(dir->ref))
        return ENOENT;

    /* look up for the matching entry: */
    p = dir_tmpfs_inode->u.dentries.first;
    while(p && (p->inode==0 || p->inode==1 || strcmp(name, p->name)))
        p = p->next;

    /* found? */
    if (!p)
        return ENOENT; /* not found! */

    /* get the inode */
    inode = (inode_t *) iget(dir->sb, p->inode);

    /* file must be a directory */
    if ((inode->mode & FT_MASK) != FT_DIR) {
        iput(inode);
        return ENOTDIR;
    }

    /* get count of entries in the target: */
    nod_tmpfs_inode = (tmpfs_inode_t *) inode->ino;
    pp = nod_tmpfs_inode->u.dentries.first;
    while (pp) {
        if (pp->inode != 0 && pp->inode != 1)
            entcount++;
        pp = pp->next;
    }

    /* directory is not empty? */
    if (entcount > 2) {
        iput(inode);
        return ENOTEMPTY;
    }

    /* decrease references: */
    inode->ref--;
    tmpfs_update_inode(inode);

    /* put the inode */
    iput(inode);

    /* remove entry from parent directory */
    p->inode = 1;
    kfree(p->name);

    /* done: */
    return ESUCCESS;

}

/***************************************************************************/
/*                               truncate()                                */
/***************************************************************************/

int32_t tmpfs_truncate(inode_t *inode, pos_t length) {

    tmpfs_inode_t *tmpfs_inode = (tmpfs_inode_t *) inode->ino;
    tmpfs_block_t *prev = NULL;
    tmpfs_block_t *blk;
    pos_t off = 0;
    pos_t blkcount;
    int32_t i;

    /* must be regular file */
    if ((inode->mode & FT_MASK) != FT_REGULAR) {
        /* not regular */
        return EINVAL;
    }

    /* count of the blocks in the new file */
    blkcount = length/inode->blksize + ((length%inode->blksize)?1:0);

    /* shrink if the file is larger */
    while (tmpfs_inode->u.blocks.count > blkcount) {
        /* remove from tail */
        blk = tmpfs_inode->u.blocks.last;
        linkedlist_aremove(&(tmpfs_inode->u.blocks), blk);
        kfree(blk->data);
        kfree(blk);
    }

    /* expand if the file is smaller */
    while (tmpfs_inode->u.blocks.count < blkcount) {
        /* add to tail */
        blk = kmalloc(sizeof(tmpfs_block_t));
        blk->data = kmalloc(inode->blksize);
        linkedlist_addlast(&(tmpfs_inode->u.blocks), blk);
        for (i = 0; i < inode->blksize; i++)
            blk->data[i] = 0;
    }

    /* update file size... */
    inode->size = length;
    inode->blocks = blkcount;
    tmpfs_update_inode(inode);

    /* done */
    return ESUCCESS;

}

/***************************************************************************/
/*                                 open()                                 */
/***************************************************************************/

int32_t tmpfs_open(file_t *file) {

    /* get inode of the file */
    inode_t *inode = file->inode;

    /* get tmpfs inode of the file */
    tmpfs_inode_t *tmpfs_inode = (tmpfs_inode_t *) inode->ino;

    /* seek the first block */
    file->info.tmpfs.curblk  = tmpfs_inode->u.blocks.first;
    file->info.tmpfs.curdent = tmpfs_inode->u.dentries.first;
    file->info.tmpfs.off = 0;

    /* done */
    return ESUCCESS;

}

/***************************************************************************/
/*                                release()                                */
/***************************************************************************/

int32_t tmpfs_release(file_t *file) {

    /* nothing to do here */
    return ESUCCESS;

}


/***************************************************************************/
/*                                 read()                                  */
/***************************************************************************/

int32_t tmpfs_read(file_t *file, void *buf, int32_t size) {

    pos_t off = file->pos;
    int32_t rem = size; /* remaining */
    int32_t blksize = file->inode->blksize;
    tmpfs_inode_t *nod_tmpfs_inode = (tmpfs_inode_t *) file->inode->ino;
    int32_t i, j;
    pos_t tsize;

    /* size should be a valid number */
    if (size <= 0)
        return EINVAL;

    /* EOF? */
    if (off >= file->inode->size)
        return 0;

    /* decrease rem if off + rem skips EOF */
    if (off + rem > file->inode->size)
        rem = file->inode->size - off;

    /* read block by block.. */
    while (rem) {

        /* try to not skip current block. */
        if ((tsize = blksize-off%blksize) > rem)
            tsize = rem;

        /* do the read! */
        for (i=off%blksize,j=0; i<off%blksize+tsize; i++,j++) {
            ((uint8_t *) buf)[j] = file->info.tmpfs.curblk->data[i];
        }

        /* update remaining: */
        rem -= tsize;
        off += tsize;
        buf = ((uint8_t *) buf) + tsize;

        /* move to next block */
        if (!(off % blksize))
            file->info.tmpfs.curblk = file->info.tmpfs.curblk->next;

    }

    /* update file position */
    file->pos = off;

    /* done */
    return ESUCCESS;

}

/***************************************************************************/
/*                                 write()                                 */
/***************************************************************************/

int32_t tmpfs_write(file_t *file, void *buf, int32_t size) {

    pos_t off = file->pos;
    int32_t rem = size; /* remaining */
    int32_t blksize = file->inode->blksize;
    tmpfs_inode_t *nod_tmpfs_inode = (tmpfs_inode_t *) file->inode->ino;
    int32_t i, j;
    pos_t tsize;

    /* size should be a valid number */
    if (size <= 0)
        return EINVAL;

    /* update file size... */
    if (off + rem > file->inode->size) {
        file->inode->size   = off+rem;
        file->inode->blocks = (file->inode->size/blksize) +
                              ((file->inode->size%blksize) ? 1:0);
        tmpfs_update_inode(file->inode);
    }

    /* write block by block.. */
    while (rem) {

        /* try to not skip current block. */
        if ((tsize = blksize-off%blksize) > rem)
            tsize = rem;

        /* if block is empty, allocate */
        if (!file->info.tmpfs.curblk) {
            /* allocate new block */
            tmpfs_block_t *tmpfs_block = kmalloc(sizeof(tmpfs_block_t));
            tmpfs_block->data = kmalloc(blksize);
            linkedlist_addlast(&(nod_tmpfs_inode->u.blocks), tmpfs_block);
            file->info.tmpfs.curblk = tmpfs_block;
        }

        /* do the write! */
        for (i=off%blksize,j=0; i<off%blksize+tsize; i++,j++) {
            file->info.tmpfs.curblk->data[i] = ((uint8_t *) buf)[j];
        }

        /* update remaining: */
        rem -= tsize;
        off += tsize;
        buf = ((uint8_t *) buf) + tsize;

        /* move to next block */
        if (!(off % blksize))
            file->info.tmpfs.curblk = file->info.tmpfs.curblk->next;

    }

    /* update file position */
    file->pos = off;

    /* done */
    return ESUCCESS;

}

/***************************************************************************/
/*                                 seek()                                  */
/***************************************************************************/

int32_t tmpfs_seek(file_t *file, pos_t newpos) {

    tmpfs_inode_t *tmpfs_inode = (tmpfs_inode_t *) file->inode->ino;

    /* truncate if seek goes past EOF */
    if (newpos > file->inode->size) {
        /*tmpfs_truncate(file->inode, newpos);*/
        return EINVAL;
    }

    /* seek the first block */
    file->info.tmpfs.curblk = tmpfs_inode->u.blocks.first;
    file->info.tmpfs.off = 0;

    /* loop over blocks of the file until we reach the block we want */
    while (file->info.tmpfs.curblk) {

        if (file->info.tmpfs.off + file->inode->blksize > newpos) {
            /* we are done */
            file->info.tmpfs.off = newpos;
            break;
        }

        file->info.tmpfs.off += file->inode->blksize;
        file->info.tmpfs.curblk = file->info.tmpfs.curblk->next;
    }

    /* return */
    file->pos = file->info.tmpfs.off;
    return ESUCCESS;

}

/***************************************************************************/
/*                                readdir()                                */
/***************************************************************************/

int32_t tmpfs_readdir(file_t *file, dirent_t *dirent) {

    /* read next entry */
    while (file->info.tmpfs.curdent) {
        if (file->info.tmpfs.curdent->inode > 1) {
            /* return the entry */
            dirent->ino = file->info.tmpfs.curdent->inode;
            strcpy(dirent->name, file->info.tmpfs.curdent->name);
            file->info.tmpfs.curdent = file->info.tmpfs.curdent->next;
            return 1;
        } else {
            /* next entry */
            file->info.tmpfs.curdent = file->info.tmpfs.curdent->next;
        }
    }

    /* no more entries */
    return 0;

}

/***************************************************************************/
/*                                 ioctl()                                 */
/***************************************************************************/

int32_t tmpfs_ioctl(file_t *file, int32_t cmd, void *arg) {

    /* currently tmpfs doesn't make use of this... */
    return EBUSY;

}

/***************************************************************************/
/*                              tmpfsls()                                  */
/***************************************************************************/

void tmpfsls(char *path) {

    /* for debug */

    namei_t namei_data;
    int32_t err;
    char *fpath;
    inode_t *inode;
    tmpfs_inode_t *node;
    tmpfs_dentry_t *x;
    super_block_t *sb;

    printk("$ ls %s\n", path);

    err = namei(NULL, path, &namei_data);
    if (err) {
        printk("doesn't exist!\n");
        return;
    }

    fpath = namei_data.path;
    inode = namei_data.inode;

    if((inode->mode & FT_MASK) != FT_DIR) {
        printk("not directory!\n");
        kfree(fpath);
        iput(inode);
        return;
    }
    printk("listing %s\n", fpath);

    node = (tmpfs_inode_t *) inode->ino;
    x = node->u.dentries.first;

    while (x != NULL) {
        if (x->inode)
            printk("inode: %x, name: %s\n", x->inode, x->name);
        x = x->next;
    }

    sb = inode->sb;

    kfree(fpath);
    iput(inode);

    printk("sb->icount: %x\n", sb->icount);

}

/***************************************************************************/
/*                               fsdriver_t                                */
/***************************************************************************/

fsd_t tmpfs_t = {

    /* alias:        */ "tmpfs",
    /* flags:        */ 0,

    /* read_super:   */ tmpfs_read_super,
    /* write_super:  */ tmpfs_write_super,
    /* put_super:    */ tmpfs_put_super,
    /* read_inode:   */ tmpfs_read_inode,
    /* update_inode: */ tmpfs_update_inode,
    /* put_inode:    */ tmpfs_put_inode,

    /* lookup:       */ tmpfs_lookup,
    /* mknod:        */ tmpfs_mknod,
    /* link:         */ tmpfs_link,
    /* unlink:       */ tmpfs_unlink,
    /* mkdir:        */ tmpfs_mkdir,
    /* rmdir:        */ tmpfs_rmdir,
    /* truncate:     */ tmpfs_truncate,

    /* open:         */ tmpfs_open,
    /* release:      */ tmpfs_release,
    /* read:         */ tmpfs_read,
    /* write:        */ tmpfs_write,
    /* seek:         */ tmpfs_seek,
    /* readdir:      */ tmpfs_readdir,
    /* ioctl:        */ tmpfs_ioctl

};
