/*
 *        +----------------------------------------------------------+
 *        | +------------------------------------------------------+ |
 *        | |  Quafios Kernel 2.0.1.                               | |
 *        | |  -> MIPS: virtual memory.                            | |
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

#ifdef ARCH_MIPS

#include <arch/type.h>
#include <sys/error.h>
#include <sys/mm.h>
#include <sys/scheduler.h>

#include <mips/asm.h>
#include <mips/page.h>

typedef struct regiontbl {
    /* a table that stores information about specific mapping */
    file_mem_t *region[PAGE_TABLE_ENTRY_COUNT];
} __attribute__((packed)) regiontbl_t;

typedef struct {
    uint32_t* page_dir;       /* page directory.                        */
    uint32_t* page_dir_ext;   /* a copy of page directory.              */
    regiontbl_t **region_dir; /* region information directory table.    */
} arch_umem_t;                /* architecture dependant umem structure. */

uint32_t general_pagedir[PAGE_DIR_ENTRY_COUNT]
                __attribute__((aligned(PAGE_SIZE)));
uint32_t general_pagedir_ext[PAGE_DIR_ENTRY_COUNT]
                __attribute__ ((aligned(PAGE_SIZE)));
uint32_t kmem_pagetab[KERNEL_MEMORY_PAGES]
                __attribute__ ((aligned(PAGE_SIZE)));
regiontbl_t *general_regiondir[PAGE_DIR_ENTRY_COUNT]
                __attribute__ ((aligned(PAGE_SIZE)));
uint32_t *cr3; /* just like cr3 of x86 */
int32_t page_initialized = 0;

void file_close() {

}

uint32_t get_badvaddr() {
    uint32_t reg;
    __asm__("mfc0 %0, $8;":"=r"(reg):"r"(0xFFFFFFFF));
    return reg;
}


/****************************************************************************/
/*                        TLB access routines                               */
/****************************************************************************/

void set_tlb(uint32_t index, uint32_t virt, uint32_t phys, uint32_t v) {
    mtc0(index<<8, INDEX);
    mtc0((v<<9)|(phys<<12), ENTRY_LO);
    mtc0((virt<<12), ENTRY_HI);
    tlbwi();
}

void fill_tlb(uint32_t virt, uint32_t phys, uint32_t v) {
    set_tlb(virt&63, virt, phys, v);
}

void get_tlb(uint32_t index, uint32_t *virt, uint32_t *phys, uint32_t *v) {
    uint32_t low, high;
    mtc0(index<<8, INDEX);
    tlbr();
    mfc0(low, ENTRY_LO);
    mfc0(high, ENTRY_HI);
    *v = (low>>9)&1;
    *phys = low>>12;
    *virt = high>>12;
}

void flush_tlb() {
    int i;
    for (i = 0; i < 64; i++)
        set_tlb(i, 0, 0, 0);
}

/****************************************************************************/
/*                  MIPS paging system initialization                       */
/****************************************************************************/

void page_init() {
    int i;
    /* no pages are currently allocated */
    for (i = 0; i < PAGE_DIR_ENTRY_COUNT; i++) {
        general_pagedir[i] = 0;
        general_pagedir_ext[i] = 0;
        general_regiondir[i] = NULL;
    }
    /* initialize the KMEM AREA page tables. */
    for (i = 0; i < KERNEL_MEMORY_PAGES; i++)
        kmem_pagetab[i] = 0;
    /* map kernel memory area into the page directory: */
    for (i = 0; i < KERNEL_MEMORY_PTABLES; i++) {
        int p = KERNEL_MEMORY_BASE/(PAGE_SIZE*PAGE_TABLE_ENTRY_COUNT);
        general_pagedir[i+p] = ((uint32_t)
            &kmem_pagetab[i*PAGE_TABLE_ENTRY_COUNT]) |
                PAGE_ENTRY_KERNEL_MODE;
    }
    /* set cr3 to general_pagedir */
    cr3 = general_pagedir;
    /* flush tlb */
    flush_tlb();
    /* done */
    page_initialized = 1;
}

/****************************************************************************/
/*                          Page Entry Operations                           */
/****************************************************************************/

arch_umem_t get_arch_umem_t(umem_t *umem) {
    /* get the virtual address of umem's page_dir: */
    arch_umem_t ret;
    if (umem != NULL) {
        arch_umem_t *arch_umem = (arch_umem_t *) umem->arch_reg;
        ret.page_dir      = arch_umem->page_dir;
        ret.page_dir_ext  = arch_umem->page_dir_ext;
        ret.region_dir    = arch_umem->region_dir;
    } else if (curproc != NULL) {
        arch_umem_t *arch_umem = (arch_umem_t *) curproc->umem.arch_reg;
        ret.page_dir      = arch_umem->page_dir;
        ret.page_dir_ext  = arch_umem->page_dir_ext;
        ret.region_dir    = arch_umem->region_dir;
    } else {
        /* umem = NULL & curproc = NULL */
        /* process management is not initialized yet... */
        ret.page_dir      = general_pagedir;
        ret.page_dir_ext  = general_pagedir_ext;
        ret.region_dir    = general_regiondir;
    }
    return ret;
}

uint32_t getPageEntry(umem_t *umem, uint32_t vaddr) {
    uint32_t pde, pe, *pagetbl;
    arch_umem_t arch_umem = get_arch_umem_t(umem);
    pde = (vaddr >> 22) & 0x3FF; /* page dir entry */
    if (!(arch_umem.page_dir[pde] & PAGE_ENTRY_P))
        return 0;
    pagetbl = (uint32_t*)(arch_umem.page_dir[pde]&PAGE_BASE_MASK);
    pe = (vaddr >> 12) & 0x3FF; /* page entry; */
    return pagetbl[pe];
}

uint32_t arch_vmpage_isMapped(umem_t *umem, uint32_t vaddr) {
    uint32_t entry = getPageEntry(umem, vaddr);
    if ((entry & PAGE_ENTRY_P) || (entry & PAGE_ENTRY_AF))
        /* mapped; */
        return 1;
    return 0; /* not mapped; */
}

uint32_t arch_vmdir_isMapped(umem_t *umem, uint32_t vaddr) {
    arch_umem_t arch_umem = get_arch_umem_t(umem);
    uint32_t pde = (vaddr >> 22) & 0x3FF; /* page dir entry */
    return arch_umem.page_dir[pde] & PAGE_ENTRY_P;
}

uint32_t arch_vmpage_getAddr(umem_t *umem, uint32_t vaddr) {
    return getPageEntry(umem, vaddr) & PAGE_BASE_MASK;
}

#if 0

void arch_vmpage_copy(umem_t *msrc, uint32_t src,
                      umem_t *mdest, uint32_t dest,
                      uint8_t *buf1, uint8_t *buf2) {

    /* use buf1 & buf2 to access physical memory pages.
     * buf1 & buf2 should be allocated using kmalloc().
     */
    arch_umem_t arch_umem;

    uint32_t index1 = (((uint32_t)buf1)-KERNEL_MEMORY_BASE)/PAGE_SIZE;
    uint32_t index2 = (((uint32_t)buf2)-KERNEL_MEMORY_BASE)/PAGE_SIZE;

    uint32_t entry1 = kmem_pagetab[index1];
    uint32_t entry2 = kmem_pagetab[index2];

    uint32_t entry;
    uint32_t pde, *pagetbl, pe;

    uint32_t psrc, pdest, i;

    /* source is not allocated/present? */
    if (!(getPageEntry(msrc, src) & PAGE_ENTRY_P))
        return;

    /* dest is not allocated/present? */
    entry = getPageEntry(mdest, dest);
    if (!(entry & PAGE_ENTRY_P)) {
        if (!entry)
            return; /* not mapped!! */

        arch_umem = get_arch_umem_t(mdest);
        pde = (dest >> 22) & 0x3FF; /* page dir entry */
        if (!(arch_umem.page_dir[pde] & PAGE_ENTRY_P))
            return;
        pagetbl = (uint32_t*)(arch_umem.page_dir_ext[pde]&PAGE_BASE_MASK);
        pe = (dest >> 12) & 0x3FF; /* page entry; */

        pagetbl[pe] |= ppalloc();
        pagetbl[pe] |= PAGE_ENTRY_P;
        pagetbl[pe] &= ~PAGE_ENTRY_AF;
    }

    /* get access to physical pages: */
    psrc  = arch_vmpage_getAddr(msrc,  src);
    pdest = arch_vmpage_getAddr(mdest, dest);
    kmem_pagetab[index1] = psrc | PAGE_ENTRY_KERNEL_MODE;
    kmem_pagetab[index2] = pdest | PAGE_ENTRY_KERNEL_MODE;

    /* update CPU caches: */
    set_cr3(get_cr3());

    /* copy data: */
    for(i = 0; i < PAGE_SIZE; i++)
        buf2[i] = buf1[i];

    /* get back every thing: */
    kmem_pagetab[index1] = entry1;
    kmem_pagetab[index2] = entry2;

    /* update CPU caches: */
    set_cr3(get_cr3());

    /* return; */
    return;

}
#endif

uint32_t arch_vmpage_map(umem_t *umem, uint32_t vaddr, uint32_t user) {

    /* maps a page, CPU level...
     * user: 0 -> kernel mode, 1 -> user mode
     * returns error if no memory, or if vaddr is already mapped.
     */
    arch_umem_t arch_umem;
    uint32_t pde, *pagetbl, pe, i;
    if (arch_vmpage_isMapped(umem, vaddr))
        return EBUSY;
    arch_umem = get_arch_umem_t(umem);
    pde = (vaddr >> 22) & 0x3FF; /* page dir entry */

    if (!(arch_umem.page_dir[pde] & PAGE_ENTRY_P)) {
        /* allocate page table; */
        pagetbl = (uint32_t *) kmalloc(PAGE_SIZE);
        if (pagetbl == NULL) {
            return ENOMEM;
        }

        /* to get the physical address of pagetbl
         * pagetbl should be allocated first.
         * kmalloc doesn't allocate until a page
         * fault occurs:
         */
        pagetbl[0] = 0; /* this is very tricky ;) */

        arch_umem.page_dir[pde] = (((uint32_t) pagetbl) &
                                   PAGE_BASE_MASK) |
                                   PAGE_ENTRY_USER_MODE |
                                   PAGE_EXT_REMOVABLE;

        /* also allocate a region table corresponding to this page table */
        if (!(arch_umem.region_dir[pde] = kmalloc(sizeof(regiontbl_t))))
            return ENOMEM;

        /* clear the tables */
        for (i = 0; i < PAGE_TABLE_ENTRY_COUNT; i++)
            arch_umem.region_dir[pde]->region[i] = (file_mem_t*)(pagetbl[i]=0);
    } else {
        pagetbl = (uint32_t *)(arch_umem.page_dir[pde]&PAGE_BASE_MASK);
    }

    pe = (vaddr >> 12) & 0x3FF; /* page entry; */

    pagetbl[pe] = PAGE_ENTRY_AF | PAGE_ENTRY_RW;
    if (user) pagetbl[pe] |= PAGE_ENTRY_US;

    if (arch_umem.page_dir[pde] & PAGE_EXT_REMOVABLE)
        arch_umem.page_dir_ext[pde]++;

    /* update CPU caches. */
    /*flush_tlb();*/

    return ESUCCESS;
}

uint32_t arch_vmpage_unmap(umem_t *umem, int32_t vaddr) {

    /* unmaps a page, CPU level...
     * returns error if vaddr is not already mapped.
     */
    arch_umem_t arch_umem;
    uint32_t pde, *pagetbl, pe;

    if (!arch_vmpage_isMapped(umem, vaddr))
        return EBUSY;

    arch_umem = get_arch_umem_t(umem);

    pde = (vaddr >> 22) & 0x3FF; /* page dir entry */
    pagetbl = (uint32_t *)(arch_umem.page_dir[pde]&PAGE_BASE_MASK);
    pe = (vaddr >> 12) & 0x3FF; /* page entry; */

    if (arch_umem.region_dir[pde] && arch_umem.region_dir[pde]->region[pe]) {
        arch_umem.region_dir[pde]->region[pe]->ref--;
        if (!arch_umem.region_dir[pde]->region[pe]->ref) {
            file_t *file = arch_umem.region_dir[pde]->region[pe]->file;
            if (arch_umem.region_dir[pde]->region[pe]->paddr) {
                ppfree(arch_umem.region_dir[pde]->region[pe]->paddr);
            }
            linkedlist_aremove(&(file->inode->sma),
                arch_umem.region_dir[pde]->region[pe]);
            kfree(arch_umem.region_dir[pde]->region[pe]);
            file_close(arch_umem.region_dir[pde]->region[pe]->file);
        }
        arch_umem.region_dir[pde]->region[pe] = 0;
    } else {
        if (pagetbl[pe] & PAGE_ENTRY_P)
            ppfree(pagetbl[pe] & PAGE_BASE_MASK);
    }

    pagetbl[pe] = 0;

    if (arch_umem.page_dir[pde] & PAGE_EXT_REMOVABLE)
        arch_umem.page_dir_ext[pde]--;

    if ((arch_umem.page_dir[pde]&PAGE_FLAG_MASK)==PAGE_EXT_REMOVABLE) {
        /* page table is empty */
        kfree(arch_umem.page_dir[pde] & PAGE_BASE_MASK);
        arch_umem.page_dir_ext[pde] = 0;
        arch_umem.page_dir[pde] = 0;
        /* also deallocate the associated region table */
        kfree(arch_umem.region_dir[pde]);
        arch_umem.region_dir[pde] = 0;
    }

    /* update CPU caches. */
    /*flush_tlb();*/

    return ESUCCESS;

}

#if 0

void arch_set_page(umem_t *umem, uint32_t vaddr, uint32_t paddr) {

    /* used to gain direct access to physical memory */
    arch_umem_t arch_umem;
    uint32_t pde, *pagetbl, pe;

    /* get umem structures of current process: */
    arch_umem = get_arch_umem_t(NULL);

    /* get page entry of the virtual address: */
    pde = (vaddr >> 22) & 0x3FF; /* page dir entry */
    if (!(arch_umem.page_dir[pde] & PAGE_ENTRY_P))
        return; /* failed */
    pagetbl = (uint32_t *) (arch_umem.page_dir_ext[pde]&PAGE_BASE_MASK);
    pe = (vaddr >> 12) & 0x3FF; /* page entry; */

    /* set page entry: */
    pagetbl[pe] = (pagetbl[pe] & PAGE_FLAG_MASK) | paddr;
    pagetbl[pe] |= PAGE_ENTRY_P;

    /* update cache: */
    set_cr3(get_cr3());

}

void arch_vmpage_attach_file(umem_t *umem,
                             uint32_t vaddr,
                             file_mem_t *region) {

    arch_umem_t arch_umem;
    uint32_t pde, *pagetbl, pe;
    regiontbl_t *regiontbl;

    /* get arch_umem structure: */
    arch_umem = get_arch_umem_t(umem);

    /* get page table: */
    pde = (vaddr >> 22) & 0x3FF; /* page dir entry */
    if (!(arch_umem.page_dir[pde] & PAGE_ENTRY_P))
        return; /* failed */
    pagetbl = (uint32_t *) (arch_umem.page_dir_ext[pde]&PAGE_BASE_MASK);
    regiontbl = arch_umem.region_dir[pde];

    /* get page entry */
    pe = (vaddr >> 12) & 0x3FF; /* page entry; */

    /* attach the page */
    regiontbl->region[pe] = region;

}

#endif

/****************************************************************************/
/*                        Virtual Memory Organization                       */
/****************************************************************************/

uint32_t arch_vminit(umem_t *umem) {

    /* initialize the virtual memory of umem. */
    int32_t i;
    arch_umem_t *arch_umem = (arch_umem_t *)kmalloc(sizeof(arch_umem_t));
    if (arch_umem == NULL)
        return ENOMEM;

    /* create page dir: */
    arch_umem->page_dir = kmalloc(PAGE_SIZE);
    if (arch_umem->page_dir == NULL) {
        kfree(arch_umem);
        return ENOMEM;
    }

    /* create the extended page dir; */
    arch_umem->page_dir_ext = kmalloc(PAGE_SIZE);
    if (arch_umem->page_dir_ext == NULL) {
        kfree(arch_umem->page_dir);
        kfree(arch_umem);
        return ENOMEM;
    }

    /* create the region dir */
    arch_umem->region_dir = kmalloc(sizeof(regiontbl_t *) *
                                    PAGE_DIR_ENTRY_COUNT);
    if (arch_umem->page_dir_ext == NULL) {
        kfree(arch_umem->page_dir_ext);
        kfree(arch_umem->page_dir);
        kfree(arch_umem);
        return ENOMEM;
    }

    /* Copy general page dir & general page dir extended: */
    for (i = 0; i < PAGE_DIR_ENTRY_COUNT; i++) {
        arch_umem->page_dir[i] = general_pagedir[i];
        arch_umem->page_dir_ext[i] = general_pagedir_ext[i];
        arch_umem->region_dir[i] = 0;
    }

    /* return */
    umem->arch_reg = (void *) arch_umem;
    return ESUCCESS;
}

void arch_vmswitch(umem_t *umem) {
    arch_umem_t arch_umem = get_arch_umem_t(umem);
    cr3 = arch_umem.page_dir;
    flush_tlb();
}

void arch_vmdestroy(umem_t *umem) {
    /* called on termination of a process */
    arch_umem_t *arch_umem = (arch_umem_t *) umem->arch_reg;
    kfree(arch_umem->region_dir);
    kfree(arch_umem->page_dir_ext);
    kfree(arch_umem->page_dir);
    kfree(arch_umem);
}

/****************************************************************************/
/*                            Page Fault Handler                            */
/****************************************************************************/

void tlb_miss() {
    /* variable declarations:  */
    /* ----------------------- */
    arch_umem_t arch_umem;
    uint32_t pde, *pagetbl, pe, paddr, vaddr, read = 0;
    file_mem_t *region = NULL;

    /* get umem structures of current process:  */
    /* ---------------------------------------- */
    arch_umem = get_arch_umem_t(NULL);

    /* get page entry of the address stored in badvaddr:  */
    /* -------------------------------------------------- */
    vaddr = get_badvaddr();
    pde = (vaddr >> 22) & 0x3FF; /* page dir entry */
    if (!(arch_umem.page_dir[pde] & PAGE_ENTRY_P)) {
        panic(NULL, "Page fault!\n");
    }
    pagetbl = (uint32_t *) (arch_umem.page_dir[pde]&PAGE_BASE_MASK);
    pe = (vaddr >> 12) & 0x3FF; /* page entry; */
    if (!(pagetbl[pe] & PAGE_ENTRY_P) && !(pagetbl[pe] & PAGE_ENTRY_AF)) {
        panic(NULL, "Page fault!\n");
    }

    /*printk("vaddr: %x %x %x\n", vaddr, pagetbl, pagetbl[pe]);*/

    /* allocate memory:  */
    /* ----------------- */
    if (pagetbl[pe] & PAGE_ENTRY_AF) {
        if (arch_umem.region_dir[pde])
            region = arch_umem.region_dir[pde]->region[pe];
        if (region == NULL) {
            /* normal page */
            paddr = ppalloc();
        } else {
            /* a mapped file */
            if (!region->paddr) {
                region->paddr = ppalloc();
                /* consider reading */
                read = 1;
            }
            paddr = region->paddr;
        }
        pagetbl[pe] |= paddr;
        pagetbl[pe] |= PAGE_ENTRY_P;
        pagetbl[pe] &= ~PAGE_ENTRY_AF;
    } else {
        paddr = pagetbl[pe];
    }

    /* update TLB:  */
    /* ------------ */
    fill_tlb(vaddr>>12, paddr>>12, 1);

    /* read from disk:  */
    /* ---------------- */
    if (read) {
        /*fsd_t *fsdriver = region->file->mp->sb->fsdriver;
        void * buf = (void *)(vaddr & PAGE_BASE_MASK);
        fsdriver->seek(region->file, region->pos);
        fsdriver->read(region->file, buf, PAGE_SIZE);*/
    }

}

#else

typedef int dummy;

#endif