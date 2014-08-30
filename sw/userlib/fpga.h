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
 * Filename: fpga_comm.h
 * Version: 0.9
 * Description: Linux PCIe communications API for RIFFA. Uses RIFFA kernel
 *  driver defined in "fpga_driver.h".
 * History: @mattj: Initial pre-release. Version 0.9.
 */

#ifndef FPGA_COMM_H
#define FPGA_COMM_H

#include <fpga_driver.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif


/* Paths in proc and dev filesystems */
#define FPGA_INTR_PATH "/proc/" DEVICE_NAME
#define FPGA_DEV_PATH "/dev/" DEVICE_NAME

struct thread_args;
typedef struct thread_args thread_args;
struct fpga_dev;
struct sys_stat;
typedef struct fpga_dev fpga_dev;

typedef enum dma_point {ICAP,USERPCIE1,USERPCIE2,USERPCIE3,USERPCIE4} DMA_PNT;

/**
 * Initializes the FPGA memory/resources and updates the pointers in the 
 * fpga_dev struct. Returns 0 on success.
 * On error, returns:
 * -1 if could not open the virtual device file (check errno for details).
 * -ENOMEM if could not map the internal buffer memory to user space.
 */
int fpga_init();

/**
 * Cleans up memory/resources for the FPGA virtual files.
 */
void fpga_close();


typedef struct send_param { 
     DMA_PNT dest;
     unsigned char * senddata;
     int sendlen;
     unsigned int addr;
}my_send_param;

/**
 * Writes data to the FPGA on channel, channel. All sendlen bytes from the 
 * senddata pointer will be written (possibly over multiple transfers). After 
 * each transfer, the IP core connected to the channel will receive a doorbell 
 * with the transfer length (in bytes). If start == 1, then after the final 
 * transfer, the IP core will receive a zero length doorbell to signal start. 
 * Returns 0 on success.
 * The endianness of sent data is not changed.
 * On error, returns:
 * -EACCES if the channel is not open.
 * -ETIMEDOUT if timeout is non-zero and expires before all data is received.
 * -EREMOTEIO if the transfer sequence takes too long, data is lost/dropped,
 * or some other error is encountered during transfer.
 * -ERESTARTSYS if a signal interrupts the thread.
 * -ENOMEM if the driver runs out of buffers for data transfers.
 * -EFAULT if internal queues are exhausted or on bad address access.
 */
//void *fpga_send_data(void *send_param);
int fpga_send_data(DMA_PNT dest, unsigned char * senddata, int sendlen, unsigned int addr);

/**
 * Reads data from the FPGA on channel, channel, to the recvdata pointer. Up to 
 * recvlen bytes will be copied to the recvdata pointer (possibly over multiple 
 * transfers). Therefore, recvdata must accomodate at least recvlen bytes. The 
 * number of bytes actually received on the channel are returned. The number of 
 * bytes written to the recvdata pointer will be the minimum of return value and
 * recvlen.
 * The endianness of received data is not changed.
 * On error, returns:
 * -EACCES if the channel is not open.
 * -ETIMEDOUT if timeout is non-zero and expires before all data is received.
 * -EREMOTEIO if the transfer sequence takes too long, data is lost/dropped,
 * or some other error is encountered during transfer.
 * -ERESTARTSYS if a signal interrupts the thread.
 * -ENOMEM if the driver runs out of buffers for data transfers.
 * -EFAULT if internal queues are exhausted or on bad address access.
 */
int fpga_recv_data(DMA_PNT dest, unsigned char * recvdata, int recvlen, unsigned int addr);

//void *fpga_recv_data(void *recv_param);

/**
 * Waits for an interrupt to be recieved on the channel. Equivalent to waiting 
 * for a zero length receive data interrupt. Returns 0 on success.
 * On error, returns:
 * -EACCES if the channel is not open.
 * -ETIMEDOUT if timeout is non-zero and expires before all data is received.
 * -EREMOTEIO if the transfer sequence takes too long, data is lost/dropped,
 * or some other error is encountered during transfer.
 * -ERESTARTSYS if a signal interrupts the thread.
 * -ENOMEM if the driver runs out of buffers for data transfers.
 * -EFAULT if internal queues are exhausted or on bad address access.
 */
int fpga_wait_interrupt(DMA_TYPE);

int fpga_reg_wr(unsigned int regaddr, unsigned int regdata);

int fpga_reg_rd(unsigned int regaddr);

void fpga_channel_close(int channel);

int fpga_recv_local_data(DMA_PNT dest, unsigned char * recvdata, int recvlen);

int user_set_clk(unsigned int freq);

#ifdef __cplusplus
}
#endif

#endif
