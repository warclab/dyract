/*******************************************************************************
 * Copyright (c) 2012, Matthew Jacobsen
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * The views and conclusions contained in the software and documentation are those
 * of the authors and should not be interpreted as representing official policies, 
 * either expressed or implied, of the FreeBSD Project.
 */
/*
 * Filename: fpga_driver.h
 * Version: 0.9
 * History: @mattj: Initial pre-release. Version 0.9.
 */

#ifndef FPGA_DRIVER_H
#define FPGA_DRIVER_H

#include <linux/ioctl.h>

/* 
 * The major device number. We can't rely on dynamic 
 * registration any more, because ioctls need to know 
 * it. 
 */
#define MAJOR_NUM 100

/* Prefix for the interrupt files. */
#define IRQ_FILE "irqnotify"

/* 
 * Set the message of the device driver 
 */
#define IOCTL_GET_TIMEOUT _IOR(MAJOR_NUM, 1, int *)
#define IOCTL_SET_TIMEOUT _IOR(MAJOR_NUM, 2, int)
#define IOCTL_ALLC_PC_BUF _IOR(MAJOR_NUM, 3, int *)
#define IOCTL_FREE_PC_BUF _IOR(MAJOR_NUM, 4, int *)
#define IOCTL_GET_FPGA_BUF _IOR(MAJOR_NUM, 5, unsigned int *)
/*
 * _IOR means that we're creating an ioctl command 
 * number for passing information from a user process
 * to the kernel module. 
 *
 * The first arguments, MAJOR_NUM, is the major device 
 * number we're using.
 *
 * The second argument is the number of the command 
 * (there could be several with different meanings).
 *
 * The third argument is the type we want to get from 
 * the process to the kernel.
 */

/* 
 * The name of the device file 
 */
#define DEVICE_NAME "fpga"
#define VENDOR_ID 0x10EE
#define DEVICE_ID 0x0509

/*
 * Size definitions.
 */
#define PCI_BAR_0_SIZE                                  (4*1024*1024)	   // size of FPGA PCI BAR 0 config region
#define BUF_SIZE					(4*1024*1024)	   // DMA buffer size     
#define NUM_CHANNEL					18	           // number of channels
#define NUM_IPIF_BAR_SEG				1	           // number of buf segments per IPIF BAR 
#define BUF_QUEUE_DEPTH					50                 // Depth irq circular queues

/*
 * Message events
 */
#define EVENT_DATA_RECV		0
#define EVENT_DATA_SENT		1

/*Interrupt status */
#define SEND_DDR_DATA           0x1
#define RECV_DDR_DATA           0x2
#define ENET                    0x4
#define USER                    0x8
#define REBOOT                  0x8
#define SEND_USER1_DATA         0x10
#define RECV_USER1_DATA         0x20
#define SEND_DDR_USER1_DATA     0x40
#define SEND_USER1_DDR_DATA     0x80
#define SEND_USER2_DATA         0x100
#define RECV_USER2_DATA         0x200
#define SEND_DDR_USER2_DATA     0x400
#define SEND_USER2_DDR_DATA     0x800
#define SEND_USER3_DATA         0x1000
#define RECV_USER3_DATA         0x2000
#define SEND_DDR_USER3_DATA     0x4000
#define SEND_USER3_DDR_DATA     0x8000
#define SEND_USER4_DATA         0x10000
#define RECV_USER4_DATA         0x20000
#define SEND_DDR_USER4_DATA     0x40000
#define SEND_USER4_DDR_DATA     0x80000
#define RECONFIG                0x100000


/*FPGA Register Map*/
#define VER_REG                	0x00      // Version
#define SCR_REG                	0x04      // Scratch pad
#define CTRL_REG               	0x08      // Control
#define STA_REG                	0x10      // Status
#define UCTR_REG               	0x18      // User control register
#define PIOA_REG               	0x20      // PIO address
#define PIOD_REG               	0x24      // PIO read/write register
#define PC_DDR_DMA_SYS_REG     	0x28      // DMA system memory address
#define PC_DDR_DMA_FPGA_REG    	0x2C      // DMA local DDR address
#define PC_DDR_DMA_LEN_REG     	0x30      // DMA length
#define DDR_PC_DMA_SYS_REG     	0x34
#define DDR_PC_DMA_FPGA_REG    	0x38
#define DDR_PC_DMA_LEN_REG     	0x3C
#define ETH_SEND_DATA_SIZE 	0x40      
#define ETH_RCV_DATA_SIZE       0x44
#define ETH_DDR_SRC_ADDR        0x48
#define ETH_DDR_DST_ADDR        0x4C
#define RECONFIG_ADDR           0x50
#define PC_USER1_DMA_SYS   	0x60
#define PC_USER1_DMA_LEN     	0x64
#define USER1_PC_DMA_SYS    	0x68
#define USER1_PC_DMA_LEN     	0x6C
#define USER1_DDR_STR_ADDR  	0x70
#define USER1_DDR_STR_LEN    	0x74
#define DDR_USER1_STR_ADDR  	0x78
#define DDR_USER1_STR_LEN   	0x7C
#define PC_USER2_DMA_SYS   	0x80
#define PC_USER2_DMA_LEN    	0x84
#define USER2_PC_DMA_SYS    	0x88
#define USER2_PC_DMA_LEN    	0x8C
#define USER2_DDR_STR_ADDR  	0x90
#define USER2_DDR_STR_LEN   	0x94
#define DDR_USER2_STR_ADDR  	0x98
#define DDR_USER2_STR_LEN   	0x9C
#define PC_USER3_DMA_SYS    	0xA0
#define PC_USER3_DMA_LEN    	0xA4
#define USER3_PC_DMA_SYS    	0xA8
#define USER3_PC_DMA_LEN     	0xAC
#define USER3_DDR_STR_ADDR   	0xB0
#define USER3_DDR_STR_LEN   	0xB4
#define DDR_USER3_STR_ADDR  	0xB8
#define DDR_USER3_STR_LEN   	0xBC
#define PC_USER4_DMA_SYS     	0xC0
#define PC_USER4_DMA_LEN     	0xC4
#define USER4_PC_DMA_SYS     	0xC8
#define USER4_PC_DMA_LEN     	0xCC
#define USER4_DDR_STR_ADDR  	0xD0
#define USER4_DDR_STR_LEN   	0xD4
#define DDR_USER4_STR_ADDR  	0xD8
#define DDR_USER4_STR_LEN   	0xDC
#define SMT                 	0x200      // System monitor temperature
#define SMA                 	0x204      // System monitor Vccint
#define SMV                 	0x208      // System monitor VccAux
#define SMP                 	0x20C      // System monitor Iccint
#define SBV                 	0x270      // Board 12V supply current
#define SAC                    	0x274      // Board 12V Voltage	
    
/*DMA destination enumeration*/

typedef enum dma_type {hostddr,ddrhost,hostuser1,hostuser2,hostuser3,hostuser4,user1host,user2host,user3host,user4host,ddruser1,ddruser2,ddruser3,ddruser4,user1ddr,user2ddr,user3ddr,user4ddr,enet,user,config} DMA_TYPE;


#endif
