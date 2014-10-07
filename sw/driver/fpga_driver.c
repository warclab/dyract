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
 * Filename: fpga_driver.c
 * Version: 0.9
 * Description: Linux PCIe device driver for RIFFA. Uses Linux kernel APIs in
 *  version 2.6.27+ (tested on version 2.6.32 - 3.3.0).
 * History: @mattj: Initial pre-release. Version 0.9.
 * 
 * Version 1.0
 * History: @vipin_k: Updated for the new platform
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/device.h>
#include <linux/major.h>
#include <linux/err.h>
#include <linux/fs.h>
#include <linux/pci.h>
#include <linux/mm.h>
#include <linux/vmalloc.h>
#include <linux/interrupt.h>
#include <linux/dma-mapping.h>
#include <linux/irq.h>
#include <linux/proc_fs.h>
#include <linux/poll.h>
#include <linux/sched.h>
#include <linux/time.h>
#include <linux/param.h>
#include <asm/uaccess.h>
#include "fpga_driver.h"
#include "circ_queue.h"

#define DEBUG 1

MODULE_LICENSE("Dual BSD/GPL");
MODULE_DESCRIPTION("PCIe driver for FPGA (2.6.27+)");
MODULE_AUTHOR("Matt Jacobsen, Patrick Lai");

struct class *mynewmodule_class;
EXPORT_SYMBOL(mynewmodule_class);

struct irq_file {
    wait_queue_head_t readwait;
    wait_queue_head_t writewait;
    int channel;
    atomic_t timeout;
    atomic_t bufreqs;
    struct circ_queue * hostddr;
    struct circ_queue * ddrhost;
    struct circ_queue * hostuser1;
    struct circ_queue * hostuser2;
    struct circ_queue * hostuser3;
    struct circ_queue * hostuser4;
    struct circ_queue * user1host;
    struct circ_queue * user2host;
    struct circ_queue * user3host;
    struct circ_queue * user4host;
    struct circ_queue * ddruser1;
    struct circ_queue * ddruser2;
    struct circ_queue * ddruser3;
    struct circ_queue * ddruser4;
    struct circ_queue * user1ddr;
    struct circ_queue * user2ddr;
    struct circ_queue * user3ddr;
    struct circ_queue * user4ddr;
    struct circ_queue * user;
    struct circ_queue * enet;
    struct circ_queue * config;
};

struct fpga_sc {
  unsigned long irq;
  void __iomem *bar0;
  unsigned long bar0_addr;
  unsigned long bar0_len;
  unsigned long bar0_flags;  
  char name[16];
  struct irq_file file[NUM_CHANNEL];
};

atomic_t gBarSegment[NUM_CHANNEL][NUM_IPIF_BAR_SEG];
char *gDMABuffer[NUM_CHANNEL];
dma_addr_t gDMAHWAddr[NUM_CHANNEL];
int gAllocatedBARs;
dev_t devt;
struct fpga_sc *gsc;
static struct proc_dir_entry *proc_dir;
static struct proc_dir_entry *count_file;


///////////////////////////////////////////////////////
// MEMORY ALLOCATION & HELPER FUNCTIONS
///////////////////////////////////////////////////////

/** 
 * Reads the interrupt vector from the FPGA.
 */
static inline unsigned int read_status(void)
{
  return readl(gsc->bar0 + STA_REG);
}

/** 
 * Clears the interrupt register in the FPGA.
 */
static inline void clear_interrupt_vector(unsigned int vect)
{
  writel(vect, gsc->bar0 + STA_REG);
}


/** 
 * Allocates a BUF_SIZE sized chunk of BAR memory. Returns 0 on success, 
 * non-zero if no memory is available. Upon success, the bar & segment values 
 * will be set according to the allocated memory location.
 */
static inline int allocate_buffer(int * bar, int * segment)
{
	int b, s;
	for (b = 0; b < gAllocatedBARs; b++) {
		for (s = 0; s < NUM_IPIF_BAR_SEG; s++) {
			if (!atomic_xchg(&gBarSegment[b][s], 1)) {
				*bar = b;
				*segment = s;
				return 0;
			}
		}
	}
	return 1;
}


/** 
 * Frees the specified BAR memory. Returns 0 upon success, non-zero otherwise.
 */
static inline int free_buffer(int bar, int segment)
{
	int i;

	if (bar >= 0 && bar < gAllocatedBARs && segment >= 0 && segment < NUM_IPIF_BAR_SEG) {
		if (atomic_xchg(&gBarSegment[bar][segment], 0) == 1) {
			for (i = 0; i < NUM_CHANNEL; ++i)
				wake_up(&gsc->file[i].readwait);
			return 0;
		}
		else {
			return -EFAULT;
		}
	}
	else {
		return -EINVAL;
	}
}

///////////////////////////////////////////////////////
// INTERRUPT HANDLER
///////////////////////////////////////////////////////

/**
 * Interrupt handler for all interrupts on all files. Reads data/values
 * from FPGA and wakes up waiting threads to process the data.
 */
static irqreturn_t intrpt_handler(int irq, void *dev_id) {
	unsigned int info;
	struct irq_file *irqfile;
    #ifdef DEBUG
        printk("Some interrupt \n");
    #endif
    info = read_status();   //Read the interrupt status register from FPGA
    irqfile = &gsc->file[0];

    #ifdef DEBUG
        printk("Status register value %0x\n",info);
    #endif

    if(info & SEND_DDR_DATA){  
        #ifdef DEBUG   
            printk("System to FPGA DMA interrupt1\n");
	    #endif
        if (push_circ_queue(irqfile->hostddr, EVENT_DATA_SENT, info))
  		    printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & RECV_DDR_DATA){
        #ifdef DEBUG 
            printk("FPGA to system interrupt \n");
	    #endif
        if (push_circ_queue(irqfile->ddrhost, EVENT_DATA_RECV, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }  
    if(info & SEND_USER1_DATA){
        #ifdef DEBUG 
            printk("FPGA to User1 \n");
 	    #endif
        if (push_circ_queue(irqfile->hostuser1, EVENT_DATA_SENT, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    } 
    if(info & SEND_USER2_DATA){
        #ifdef DEBUG 
            printk("FPGA to User2 \n");
  	    #endif
        if (push_circ_queue(irqfile->hostuser2, EVENT_DATA_SENT, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
            wake_up(&irqfile->readwait);
    } 

    if(info & SEND_USER3_DATA){
        #ifdef DEBUG 
            printk("FPGA to User3 \n");
	    #endif
        if (push_circ_queue(irqfile->hostuser3, EVENT_DATA_SENT, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
            wake_up(&irqfile->readwait);
    } 
    
    if(info & SEND_USER4_DATA){
        #ifdef DEBUG 
            printk("FPGA to User4 \n");
        #endif
        if (push_circ_queue(irqfile->hostuser4, EVENT_DATA_SENT, info))
            printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    } 
    if(info & RECV_USER1_DATA) {
        #ifdef DEBUG 
            printk("User1 FPGA\n");
        #endif
        if (push_circ_queue(irqfile->user1host, EVENT_DATA_RECV, info))
            printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }       
    if(info & RECV_USER2_DATA) {
        #ifdef DEBUG 
            printk("User2 FPGA\n");
        #endif
        if (push_circ_queue(irqfile->user2host, EVENT_DATA_RECV, info))
            printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & RECV_USER3_DATA) {
        #ifdef DEBUG 
            printk("User3 FPGA\n");
        #endif
        if (push_circ_queue(irqfile->user3host, EVENT_DATA_RECV, info))
            printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
            wake_up(&irqfile->readwait);
    }
    if(info & RECV_USER4_DATA) {
        #ifdef DEBUG 
            printk("User4 FPGA\n");
	    #endif
        if (push_circ_queue(irqfile->user4host, EVENT_DATA_RECV, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }    
    if(info & SEND_DDR_USER1_DATA) {
        #ifdef DEBUG 
            printk("DDR User1 FPGA\n");
	    #endif
        if (push_circ_queue(irqfile->ddruser1, EVENT_DATA_SENT, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & SEND_DDR_USER2_DATA) {
        #ifdef DEBUG 
            printk("DDR User2 FPGA\n");
	    #endif
        if (push_circ_queue(irqfile->ddruser2, EVENT_DATA_SENT, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & SEND_DDR_USER3_DATA) {
        #ifdef DEBUG 
            printk("DDR User3 FPGA\n");
	    #endif
        if (push_circ_queue(irqfile->ddruser3, EVENT_DATA_SENT, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & SEND_DDR_USER4_DATA) {
        #ifdef DEBUG 
            printk("DDR User4 FPGA\n");
	    #endif
        if (push_circ_queue(irqfile->ddruser4, EVENT_DATA_SENT, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & SEND_USER1_DDR_DATA) {
        #ifdef DEBUG 
            printk("User1 DDR FPGA\n");
	    #endif
        if (push_circ_queue(irqfile->user1ddr, EVENT_DATA_RECV, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & SEND_USER2_DDR_DATA) {
        #ifdef DEBUG 
            printk("User2 DDR FPGA\n");
	    #endif
        if (push_circ_queue(irqfile->user2ddr, EVENT_DATA_RECV, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & SEND_USER3_DDR_DATA) {
        #ifdef DEBUG 
            printk("User3 DDR FPGA\n");
	    #endif
        if (push_circ_queue(irqfile->user3ddr, EVENT_DATA_RECV, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & SEND_USER4_DDR_DATA) {
        #ifdef DEBUG 
            printk("User4 DDR FPGA\n");
	    #endif
        if (push_circ_queue(irqfile->user4ddr, EVENT_DATA_RECV, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & ENET) {
        #ifdef DEBUG 
            printk("Ethernet \n");
	    #endif
        if (push_circ_queue(irqfile->enet, EVENT_DATA_RECV, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & USER) {
        #ifdef DEBUG 
            printk("USER \n");
	    #endif
        if (push_circ_queue(irqfile->user, EVENT_DATA_RECV, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    if(info & RECONFIG) {
        #ifdef DEBUG 
            printk("RECONFIG \n");
	#endif
        if (push_circ_queue(irqfile->config, EVENT_DATA_RECV, info))
			printk(KERN_ERR "intrpt_handler, msg queue full for irq %d\n", irqfile->channel);
        wake_up(&irqfile->readwait);
    }
    clear_interrupt_vector(info);
    //info = read_status();
    //printk("Now status register value %0x\n",info);
  //printk(KERN_INFO "Interrupt called on irq: %d, with val: %08x\n", irq, irqreg);
  return IRQ_HANDLED;
}


/**
 * Reads data from the FPGA. Will block until all the data is received from the
 * FPGA unless a non-zero timeout is configured. Then the function will block 
 * until the timeout expires. On success, the received data will be copied into 
 * the user buffer, up to len bytes. The number of bytes received are returned. 
 * Error return values:
 * -ETIMEDOUT: if timeout is non-zero and expires before all data is received.
 * -EREMOTEIO: if the transfer sequence takes too long, data is lost/dropped,
 * or some other error is encountered during transfer.
 * -ERESTARTSYS: if a signal interrupts the thread.
 * -ENOMEM: if the driver runs out of buffers for data transfers.
 * -EFAULT: if internal queues are exhausted or on bad address access.
 */
static ssize_t irq_proc_read(struct file *filp, char  __user *bufp, size_t len, loff_t *ppos)
{
  struct irq_file *irqfile = (struct irq_file *)filp->private_data;
  long timeout;
  int nomsg;
  unsigned int msg, info; 
  struct circ_queue * queue;

        DEFINE_WAIT(wait);

	// Read timeout & convert to jiffies.
	timeout = (long)atomic_read(&irqfile->timeout);
	timeout = (timeout == 0 ? MAX_SCHEDULE_TIMEOUT : timeout * HZ/1000);
  
    if (len >= 64) { // Need to transfer data.
        if (copy_to_user(bufp, gDMABuffer[irqfile->channel], len))
	    printk(KERN_ERR "irq_proc_read cannot copy to user buffer.\n");          
    }
    else {	
        switch(len) {
     	   case hostddr:
                queue = irqfile->hostddr;
                break;
            case ddrhost:
                queue = irqfile->ddrhost;
                break;
            case hostuser1:
                queue = irqfile->hostuser1;
                break;
            case hostuser2:
                queue = irqfile->hostuser2;
                break;
            case hostuser3:
                queue = irqfile->hostuser3;
                break;
            case hostuser4:
                queue = irqfile->hostuser4;
                break;
            case user1host:
                queue = irqfile->user1host;
                break;
            case user2host:
                queue = irqfile->user2host;
                break;
            case user3host:
                queue = irqfile->user3host;
                break;
            case user4host:
                queue = irqfile->user4host;
                break;
            case ddruser1:
                queue = irqfile->ddruser1;
                break;
            case ddruser2:
                queue = irqfile->ddruser2;
                break;
            case ddruser3:
                queue = irqfile->ddruser3;
                break;
            case ddruser4:
                queue = irqfile->ddruser4;
                break;
            case user1ddr:
                queue = irqfile->user1ddr;
                break;
            case user2ddr:
                queue = irqfile->user2ddr;
                break;
            case user3ddr:
                queue = irqfile->user3ddr;
                break;
            case user4ddr:
                queue = irqfile->user4ddr;
                break;
            case user:
                queue = irqfile->user;
                break;
            case enet:
                queue = irqfile->enet;
                break;
            case config:
				queue = irqfile->config;
	    	break;                   
            default:
                queue = irqfile->hostddr;
                break;
        }
        while (1) {
            // Loop until we get a message or timeout.
            while ((nomsg = pop_circ_queue(queue, &msg, &info))) {
                prepare_to_wait(&irqfile->readwait, &wait, TASK_INTERRUPTIBLE);
                // Another check before we schedule.
                if ((nomsg = pop_circ_queue(queue, &msg, &info))){
                    timeout = schedule_timeout(timeout);
                    finish_wait(&irqfile->readwait, &wait);
                }
                if (signal_pending(current))
                    return -ERESTARTSYS;
                if (!nomsg)
                    break;
                if (timeout == 0) {
                    printk(KERN_ERR "irq_proc_read timed out.\n");
                    //free_buffer(bar, segment);
                    return -ETIMEDOUT;
                }
            }
            break;
        }
    }
  return 0;
}


static ssize_t irq_proc_write(struct file *filp, const char  __user *bufp, size_t len, loff_t *ppos)
{
  struct irq_file *irqfile = (struct irq_file *)filp->private_data;
  if (copy_from_user(gDMABuffer[irqfile->channel], bufp, len)) {
      printk(KERN_ERR "irq_proc_write cannot read user buffer.\n");
      return -1;
  }  
  return gDMAHWAddr[irqfile->channel];
}

/**
 * Called to set the timeout value, allocate a buffer, and release
 * a buffer. Return value depends on ioctlnum and expected behavior.
 */
static long irq_proc_ioctl(struct file *filp, unsigned int ioctlnum, 
	unsigned long ioctlparam)
{
  struct irq_file *irqfile = (struct irq_file *)filp->private_data;
	int bar, segment;

	switch (ioctlnum) {
		case IOCTL_GET_TIMEOUT:
			put_user(atomic_read(&irqfile->timeout), (int *)ioctlparam);
			break;
		case IOCTL_SET_TIMEOUT:
			atomic_set(&irqfile->timeout, (int)ioctlparam);
			break;
		case IOCTL_ALLC_PC_BUF:
			if (allocate_buffer(&bar, &segment))
				return -ENOMEM;
			put_user(bar, (int *)ioctlparam);
			put_user(segment, ((int *)ioctlparam) + 1);
			break;
		case IOCTL_FREE_PC_BUF:
			get_user(bar, (int *)ioctlparam);
			get_user(segment, ((int *)ioctlparam) + 1);
			if (free_buffer(bar, segment))
				return -EFAULT;
			break;
	}
	return 0;
}

/**
 * Sets the virtual file pointers for the opened file struct. Returns 0.
 */
static int irq_proc_open(struct inode *inop, struct file *filp)
{
  int i;
  struct proc_dir_entry *ent;
  //struct irq_file *irqfile;
  ent = PDE(inop);
  i = (unsigned long)ent->data;
  filp->private_data = (void *)&gsc->file[i];	
  return 0;
}

/**
 * Clears the virtual file pointers for the opened file struct. Returns 0.
 */
static int irq_proc_release(struct inode *inop, struct file *filp)
{
  (void)inop;
  filp->private_data = NULL;
  return 0;
}


///////////////////////////////////////////////////////
// FPGA DEVICE HANDLERS
///////////////////////////////////////////////////////

static int fpga_probe(struct pci_dev *dev, const struct pci_device_id *id) {
  int i, j, error;
  struct fpga_sc *sc;
   
  // Setup the PCIe device.
  error = pci_enable_device(dev);
  if (error < 0) {
    printk(KERN_ERR "pci_enable_device returned %d\n", error);
    return (-ENODEV);
  }
	
  // Allocate necessary structures.
  sc = kzalloc(sizeof(*sc), GFP_KERNEL);
  if (sc == NULL) {
    printk(KERN_ERR "Not enough memory to allocate sc");
    pci_disable_device(dev);
    return (-ENOMEM);
  }
  memset(sc, 0, sizeof(*sc));
  snprintf(sc->name, sizeof(sc->name), "%s%d", pci_name(dev), 0);

	// Create irq_file structs.
  for (i = 0; i < NUM_CHANNEL; ++i) {
    init_waitqueue_head(&sc->file[i].readwait);
    init_waitqueue_head(&sc->file[i].writewait);
    atomic_set(&sc->file[i].timeout, 0);
    atomic_set(&sc->file[i].bufreqs, 0);
    sc->file[i].channel = i;
  }
  sc->file[0].hostddr = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].ddrhost = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].hostuser1 = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].hostuser2 = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].hostuser3 = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].hostuser4 = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].user1host = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].user2host = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].user3host = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].user4host = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].ddruser1 = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].ddruser2 = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].ddruser3 = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].ddruser4 = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].user1ddr = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].user2ddr = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].user3ddr = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].user4ddr = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].user     = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].enet     = init_circ_queue(BUF_QUEUE_DEPTH);
  sc->file[0].config   = init_circ_queue(BUF_QUEUE_DEPTH);
  
  printk(KERN_INFO "FPGA PCIe endpoint name: %s\n", sc->name);

  // Setup the memory regions
  error = pci_request_regions(dev, sc->name);
  if (error < 0) {
    printk(KERN_ERR "pci_request_regions returned %d\n", error);
    pci_disable_device(dev);
    free_circ_queue(sc->file[0].hostddr);
    free_circ_queue(sc->file[0].ddrhost);
    free_circ_queue(sc->file[0].hostuser1);
    free_circ_queue(sc->file[0].hostuser2);
    free_circ_queue(sc->file[0].hostuser3);
    free_circ_queue(sc->file[0].hostuser4);
    free_circ_queue(sc->file[0].user1host);
    free_circ_queue(sc->file[0].user2host);
    free_circ_queue(sc->file[0].user3host);
    free_circ_queue(sc->file[0].user4host);
    free_circ_queue(sc->file[0].ddruser1);
    free_circ_queue(sc->file[0].ddruser2);
    free_circ_queue(sc->file[0].ddruser3);
    free_circ_queue(sc->file[0].ddruser4);
    free_circ_queue(sc->file[0].user1ddr);
    free_circ_queue(sc->file[0].user2ddr);
    free_circ_queue(sc->file[0].user3ddr);
    free_circ_queue(sc->file[0].user4ddr);
    free_circ_queue(sc->file[0].user);
    free_circ_queue(sc->file[0].enet);
    free_circ_queue(sc->file[0].config);
    kfree(sc);
    return (-ENODEV);
  }
	
  // PCI BAR 0
  sc->bar0_addr = pci_resource_start(dev, 0);
  sc->bar0_len = pci_resource_len(dev, 0);
  sc->bar0_flags = pci_resource_flags(dev, 0);
  sc->bar0 = ioremap(sc->bar0_addr, sc->bar0_len);
  printk(KERN_INFO "BAR 0 address: %lx\n", sc->bar0_addr);
  printk(KERN_INFO "BAR 0 length: %ld\n", sc->bar0_len);

  // Setup MSI interrupts 
  error = pci_enable_msi(dev);
  if (error != 0) {
    printk(KERN_ERR "pci_enable_msi failed, returned %d\n", error);
    if (sc->bar0) 
			iounmap(sc->bar0);
    pci_release_regions(dev);
    pci_disable_device(dev);
    free_circ_queue(sc->file[0].hostddr);
    free_circ_queue(sc->file[0].ddrhost);
    free_circ_queue(sc->file[0].hostuser1);
    free_circ_queue(sc->file[0].hostuser2);
    free_circ_queue(sc->file[0].hostuser3);
    free_circ_queue(sc->file[0].hostuser4);
    free_circ_queue(sc->file[0].user1host);
    free_circ_queue(sc->file[0].user2host);
    free_circ_queue(sc->file[0].user3host);
    free_circ_queue(sc->file[0].user4host);
    free_circ_queue(sc->file[0].ddruser1);
    free_circ_queue(sc->file[0].ddruser2);
    free_circ_queue(sc->file[0].ddruser3);
    free_circ_queue(sc->file[0].ddruser4);
    free_circ_queue(sc->file[0].user1ddr);
    free_circ_queue(sc->file[0].user2ddr);
    free_circ_queue(sc->file[0].user3ddr);
    free_circ_queue(sc->file[0].user4ddr);
    free_circ_queue(sc->file[0].user);
    free_circ_queue(sc->file[0].enet);
    free_circ_queue(sc->file[0].config);
    kfree(sc);
    return error;
  }
  error = request_irq(dev->irq, intrpt_handler, 0, sc->name, sc);
  if (error != 0) {
    printk(KERN_ERR "request_irq(%d) failed, returned %d\n", dev->irq, error);
    if (sc->bar0) 
			iounmap(sc->bar0);
    pci_release_regions(dev);
    pci_disable_device(dev);
    free_circ_queue(sc->file[0].hostddr);
    free_circ_queue(sc->file[0].ddrhost);
    free_circ_queue(sc->file[0].hostuser1);
    free_circ_queue(sc->file[0].hostuser2);
    free_circ_queue(sc->file[0].hostuser3);
    free_circ_queue(sc->file[0].hostuser4);
    free_circ_queue(sc->file[0].user1host);
    free_circ_queue(sc->file[0].user2host);
    free_circ_queue(sc->file[0].user3host);
    free_circ_queue(sc->file[0].user4host);
    free_circ_queue(sc->file[0].ddruser1);
    free_circ_queue(sc->file[0].ddruser2);
    free_circ_queue(sc->file[0].ddruser3);
    free_circ_queue(sc->file[0].ddruser4);
    free_circ_queue(sc->file[0].user1ddr);
    free_circ_queue(sc->file[0].user2ddr);
    free_circ_queue(sc->file[0].user3ddr);
    free_circ_queue(sc->file[0].user4ddr);
    free_circ_queue(sc->file[0].user);
    free_circ_queue(sc->file[0].enet);
    free_circ_queue(sc->file[0].config);
    kfree(sc);
    return error;
  }
  sc->irq = dev->irq;
  printk(KERN_INFO "MSI setup on irq %d\n", dev->irq);

  // Allocate the DMA buffers and get the addresses.
	gAllocatedBARs = 0;
	for (i = 0; i < NUM_CHANNEL; i++) {
		for (j = 0; j < NUM_IPIF_BAR_SEG; j++)
			atomic_set(&gBarSegment[i][j], 0);
	}
	for (i = 0; i < NUM_CHANNEL; i++) {
	  gDMABuffer[i] = pci_alloc_consistent(dev, BUF_SIZE, &(gDMAHWAddr[i]));
		if (gDMABuffer[i] == NULL) {
		  printk(KERN_ERR "pci_alloc_consistent() failed for DMA buffer %d\n", i);
			break;
		}
		if ( (((unsigned long)gDMAHWAddr[i]) & (BUF_SIZE-1)) > 0 )
			printk(KERN_ERR "gDMAHWBuffer %d not aligned on BUF_SIZE boundary\n", i);
		printk(KERN_INFO "gDMABuffer %d: %p -> %p\n", i, gDMABuffer[i], (void *)gDMAHWAddr[i]);
		gAllocatedBARs++;
	}

	// Fail if we could not map any IPIF BARs.
	if (gAllocatedBARs == 0) {
		printk(KERN_ERR "ERROR, pci_alloc_consistent() failed for all DMA buffers.\n");
		if (sc->bar0) 
			iounmap(sc->bar0);
		pci_release_regions(dev);
		pci_disable_device(dev);
        free_circ_queue(sc->file[0].hostddr);
        free_circ_queue(sc->file[0].ddrhost);
        free_circ_queue(sc->file[0].hostuser1);
        free_circ_queue(sc->file[0].hostuser2);
        free_circ_queue(sc->file[0].hostuser3);
        free_circ_queue(sc->file[0].hostuser4);
        free_circ_queue(sc->file[0].user1host);
        free_circ_queue(sc->file[0].user2host);
        free_circ_queue(sc->file[0].user3host);
        free_circ_queue(sc->file[0].user4host);
        free_circ_queue(sc->file[0].ddruser1);
        free_circ_queue(sc->file[0].ddruser2);
        free_circ_queue(sc->file[0].ddruser3);
        free_circ_queue(sc->file[0].ddruser4);
        free_circ_queue(sc->file[0].user1ddr);
        free_circ_queue(sc->file[0].user2ddr);
        free_circ_queue(sc->file[0].user3ddr);
        free_circ_queue(sc->file[0].user4ddr);
        free_circ_queue(sc->file[0].user);
        free_circ_queue(sc->file[0].enet);
	free_circ_queue(sc->file[0].config);
	kfree(sc);
	return -1;
	}

  // Save pointer to structure 
  pci_set_drvdata(dev, sc);
  gsc = sc;

  return 0;
}

static void fpga_remove(struct pci_dev *dev) {
  struct fpga_sc *sc;
	int i;

  // Free memory allocated to our Endpoint
	for (i = 0; i < gAllocatedBARs; i++)
	  pci_free_consistent(dev, BUF_SIZE, gDMABuffer[i], gDMAHWAddr[i]);
  
  sc = pci_get_drvdata(dev);
  if (sc == NULL) {
    return;
  }
  
  if (sc->bar0)
    iounmap(sc->bar0);
  free_irq(dev->irq, sc);
  pci_disable_msi(dev);
  pci_release_regions(dev);
  pci_disable_device(dev);
  free_circ_queue(sc->file[0].hostddr);
  free_circ_queue(sc->file[0].ddrhost);
  free_circ_queue(sc->file[0].hostuser1);
  free_circ_queue(sc->file[0].hostuser2);
  free_circ_queue(sc->file[0].hostuser3);
  free_circ_queue(sc->file[0].hostuser4);
  free_circ_queue(sc->file[0].user1host);
  free_circ_queue(sc->file[0].user2host);
  free_circ_queue(sc->file[0].user3host);
  free_circ_queue(sc->file[0].user4host);
  free_circ_queue(sc->file[0].ddruser1);
  free_circ_queue(sc->file[0].ddruser2);
  free_circ_queue(sc->file[0].ddruser3);
  free_circ_queue(sc->file[0].ddruser4);
  free_circ_queue(sc->file[0].user1ddr);
  free_circ_queue(sc->file[0].user2ddr);
  free_circ_queue(sc->file[0].user3ddr);
  free_circ_queue(sc->file[0].user4ddr);
  free_circ_queue(sc->file[0].user);
  free_circ_queue(sc->file[0].enet);
  free_circ_queue(sc->file[0].config);
  kfree(sc);
  pci_set_drvdata(dev, NULL);
}


///////////////////////////////////////////////////////
// DEV FILE HANDLERS
///////////////////////////////////////////////////////

static int xc_open(struct inode *inode, struct file *filp)
{
  try_module_get(THIS_MODULE);
	filp->private_data = (void *)gsc; 
  return 0;
}

static int xc_release(struct inode *inode, struct file *filp)
{
  module_put(THIS_MODULE);
	filp->private_data = NULL;
  return 0;
}

static int xc_mmap(struct file *filp, struct vm_area_struct *vma)
{
	// We can only mmap contiguous memory regions. So each mapping call can only 
	// map regions within either the PCI_BAR_0 or IPIF_BARs. Use the page offset 
	// in the vma to determine which to map. Note that the caller must know the 
	// sizes of each region. The PCI_BAR_0 is always 8KB == 2 pages and IPIF_BARs
	// are always 4MB = 1024 pages. The caller will treat the different memory
	// regions as one large contiguous address space in the vma, with PCI_BAR_0 
	// first, followed by each IPIF_BAR region.
  struct fpga_sc * sc = (struct fpga_sc *)filp->private_data;
	unsigned long off = (vma->vm_pgoff<<PAGE_SHIFT);
	unsigned long len = vma->vm_end - vma->vm_start;
	unsigned long addr;
	int i;

	if (off < sc->bar0_len) {
		// Map PCI BAR 0.
		addr = ((unsigned long)sc->bar0_addr) >> PAGE_SHIFT;
		vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
		if (remap_pfn_range(vma, vma->vm_start, addr, len, PAGE_SHARED) != 0) {
		  printk(KERN_INFO "Couldn't mmap PCI BAR 0 memory.\n");
		  return -EAGAIN;
		}
		return 0;
	}
	else {
		for (i = 0; i < gAllocatedBARs; i++) {
			if (off < ((BUF_SIZE*(i+1)) + sc->bar0_len)) {
				// Map DMA IPIF_BAR region.
				addr = (((unsigned long)virt_to_phys((void *)gDMABuffer[i])) >> PAGE_SHIFT);
				vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
				if (remap_pfn_range(vma, vma->vm_start, addr, len, PAGE_SHARED) != 0) {
					printk(KERN_INFO "Couldn't mmap IPIF BAR %d memory.\n", i);
					return -EAGAIN;
				}
				return 0;
			}
		}
	}
  
  return -EAGAIN;
}

///////////////////////////////////////////////////////
// MODULE INIT/EXIT FUNCTIONS
///////////////////////////////////////////////////////

struct pci_device_id fpga_ids[] = {
  {PCI_DEVICE(VENDOR_ID, DEVICE_ID)},
  {0},
};

//MODULE_DEVICE_TABLE(pci, fpga_ids);
struct pci_driver fpga_driver = {
  .name 	= DEVICE_NAME,
  .id_table	= fpga_ids,
  .probe	= fpga_probe,
  .remove	= fpga_remove
};

static const struct file_operations fpga_fops = {
  .owner       	= THIS_MODULE,
  .open					= xc_open,
  .release			= xc_release,
  .mmap					= xc_mmap,
};

static struct file_operations irq_proc_file_operations = {
  .owner          = THIS_MODULE,
  .read           = irq_proc_read,
  .write          = irq_proc_write,
  .open           = irq_proc_open,
  .release        = irq_proc_release,
  .unlocked_ioctl = irq_proc_ioctl,
};

static int fpga_init(void) {	
  /* Register the PCIe endppoint */
  int i, error;
  char buf[20];

  error = pci_register_driver(&fpga_driver);
  if (error != 0) {
    printk(KERN_INFO "pci_module_register returned %d", error);
    return (error);
  }
  
  error = register_chrdev(MAJOR_NUM, DEVICE_NAME, &fpga_fops);
  if (error < 0) {
    printk(KERN_INFO "register_chrdev() returned %d", error);
    return (error);
  }
  
  mynewmodule_class = class_create(THIS_MODULE, DEVICE_NAME);
  if (IS_ERR(mynewmodule_class)) {
    error = PTR_ERR(mynewmodule_class);
    printk(KERN_INFO "class_create() returned %d", error);
  }
  
  devt = MKDEV(MAJOR_NUM, 0);
  device_create(mynewmodule_class, NULL, devt, "%s", DEVICE_NAME);

  /* create the proc directory */
  proc_dir = proc_mkdir(DEVICE_NAME, NULL);
  if(proc_dir == NULL)
    return -ENOMEM;
  
  /* create the irq files */
  for (i = 0; i < NUM_CHANNEL; ++i) {
    sprintf(buf, "%s%02d", IRQ_FILE, i);
    count_file = create_proc_entry(buf, 0666, proc_dir);
    if(count_file == NULL) {
      remove_proc_entry(DEVICE_NAME, NULL);
      return -ENOMEM;
    }
    count_file->data = (void *)(unsigned long)i;
    count_file->read_proc = NULL;
    count_file->write_proc = NULL;
    count_file->proc_fops = &irq_proc_file_operations;
  }
  return (0);
}

static void fpga_exit(void) {
  int i;
  char buf[20];

  device_destroy(mynewmodule_class, devt); 
  class_destroy(mynewmodule_class);
  pci_unregister_driver(&fpga_driver);
  
  unregister_chrdev(MAJOR_NUM, DEVICE_NAME);
  for (i = 0; i < NUM_CHANNEL; ++i) {
    sprintf(buf, "%s%02d", IRQ_FILE, i);
    remove_proc_entry(buf, proc_dir);
  }
  remove_proc_entry(DEVICE_NAME, NULL);
}

module_init(fpga_init);
module_exit(fpga_exit);

