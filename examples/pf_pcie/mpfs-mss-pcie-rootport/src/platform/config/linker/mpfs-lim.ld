/*******************************************************************************
 * Copyright 2019 Microchip Corporation.
 *
 * SPDX-License-Identifier: MIT
 *
 * MPFS HAL Embedded Software
 *
 */
/*******************************************************************************
 * 
 * file name : pse_emulation-ram.ld
 * fpr use with G5SoC MSS
 *
 * SVN $Revision: 9187 $
 * SVN $Date: 2017-05-13 13:31:28 +0530 (Sat, 13 May 2017) $
 * 
 */
 
OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*-------------------------------------------------------------------------------------*/
/* Sections:                                                                           */
/* On Unleashed board                                                                  */
/* 0x08000000   LIM on startup- can be used for BM debugging.                          */
/* 0x80000000   DDR  Can be used for debugging assuming has already be configured      */
/* we have 8k of DTIM located at 0x01000000 on the PF SoC and the unleashed            */
/* ram (rwx) : ORIGIN  = 0x01000000, LENGTH = 8k                                       */
/* we also have 2M of L2 cache, which is by default configured as LIM                  */
/* L2 Cache as Loosely Integrated Memory (0x08000000 0x09FFFFFF RWX L2-LIM ).          */
/* ram_LIM (rwx) : ORIGIN = 0x08000000, LENGTH = 1920k                                 */ 
/*                                                                                     */ 
/* Note: 0x1000 is used as alignment between sections as this is the PMP page size     */
/*       If not using the PMP, this can be reduced.                                    */
/*                                                                                     */ 
/*-------------------------------------------------------------------------------------*/
MEMORY
{
    eNVM (rx) : ORIGIN  = 0x20230000, LENGTH = 56k
    ram (rwx) : ORIGIN  = 0x08000000, LENGTH = 1920k
    ram_NVM (rwx) : ORIGIN  = 0x01000000, LENGTH = 8k
}

RAM_START_ADDRESS   = 0x08000000; /* Must be the same value MEMORY region ram ORIGIN above. */
RAM_SIZE            = 1920k;      /* Must be the same value MEMORY region ram LENGTH above. */
STACK_SIZE_PER_HART = 1k;         /* needs to be calculated for your application */
                                  /* Must be aligned */
                                  /* STACK allocated for each hart */
                                  /* Also Thread local storage (AKA hart local storage) allocated for each hart */
                                  /* So memory map will look like once apportion in startup code: */
                                  /* stack hart0  */
                                  /* TLS hart 0 */
                                  /* stack hart1  */
                                  /* TLS hart 1 */
                                  /* etc */
                                  /* so we must set definition here of memory size to include all of the above */
                                  /* STACK_SIZE = (stack size for each hart  + TLS for each hart) * no of harts */         
HEAP_SIZE           = 0k;         /* needs to be calculated for your application if using */

SECTIONS
{

/* text: test code section */
  . = 0x08000000;
  .text : ALIGN(0x10)
  {
     *(.text.init)
/*  *entry.o(.text); */
    . = ALIGN(0x10);
    *(.text .text.* .gnu.linkonce.t.*)
    *(.plt)
    . = ALIGN(0x10);
    
    KEEP (*crtbegin.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*crtend.o(.ctors))
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*crtend.o(.dtors))
    
    *(.rodata .rodata.* .gnu.linkonce.r.*)
    *(.gcc_except_table) 
    *(.eh_frame_hdr)
    *(.eh_frame)
    
    KEEP (*(.init))
    KEEP (*(.fini))

    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    PROVIDE_HIDDEN (__init_array_end = .);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(.fini_array))
    KEEP (*(SORT(.fini_array.*)))
    PROVIDE_HIDDEN (__fini_array_end = .);
    . = ALIGN(0x10);
    
  } > ram

  /* short/global data section */
  .sdata : ALIGN(0x10)
  {
    __sdata_load = LOADADDR(.sdata);
    __sdata_start = .; 
    /* offset used with gp(gloabl pointer) are +/- 12 bits, so set point to middle of expected sdata range */
    /* If sdata more than 4K, linker used direct addressing. Perhaps we should add check/warning to linker script if sdata is > 4k */
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2)
    *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    . = ALIGN(0x10);
    __sdata_end = .;
  } > ram

  /* data section */
  .data : ALIGN(0x10)
  { 
    __data_load = LOADADDR(.data);
    __data_start = .; 
    *(.got.plt) *(.got)
    *(.shdata)
    *(.data .data.* .gnu.linkonce.d.*)
    . = ALIGN(0x10);
    __data_end = .;
  } > ram

  /* sbss section */
  .sbss : ALIGN(0x10)
  {
    __sbss_start = .;
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
    . = ALIGN(0x10);
    __sbss_end = .;
  } > ram
  
  /* sbss section */
  .bss : ALIGN(0x10)
  { 
    __bss_start = .;
    *(.shbss)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(0x10);
    __bss_end = .;
  } > ram

  /* End of uninitialized data segment */
  _end = .;
  
  .heap : ALIGN(0x10)
  {
    __heap_start = .;
    . += HEAP_SIZE;
    __heap_end = .;
    . = ALIGN(0x10);
    _heap_end = __heap_end;
  } > ram
  
  /* must be on 4k boundary- corrsponds to page size */
  .stack : ALIGN(0x1000)
  {
    PROVIDE(__stack_bottom_h0$ = .);
    . += STACK_SIZE_PER_HART;
    PROVIDE(__stack_top_h0$ = .);
    
    PROVIDE(__stack_bottom_h1$ = .);
    . += STACK_SIZE_PER_HART;
    PROVIDE(__stack_top_h1$ = .);
    
    PROVIDE(__stack_bottom_h2$ = .);
    . += STACK_SIZE_PER_HART;
    PROVIDE(__stack_top_h2$ = .);
    
    PROVIDE(__stack_bottom_h3$ = .);
    . += STACK_SIZE_PER_HART;
    PROVIDE(__stack_top_h3$ = .);
    
    PROVIDE(__stack_bottom_h4$ = .);
    . += STACK_SIZE_PER_HART;
    PROVIDE(__stack_top_h4$ = .);
    
  } > ram
}

