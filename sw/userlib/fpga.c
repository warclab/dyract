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
 * Filename: fpga.c
 * Version: 1.0
 * Description: Linux PCIe communications API for RIFFA. Uses RIFFA kernel
 *  driver defined in "fpga_driver.h".
 * History: @mattj: Initial pre-release. Version 0.9.
 * Updated the file to support the new multiport swich
 * Author : Vipin K
 */

#define _GNU_SOURCE
#define ERRINUSE -2
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <string.h>
#include <sys/mman.h>
#include <linux/sched.h>
#include <pthread.h>
#include "fpga.h"


struct fpga_dev
{
    int fd;
    unsigned char * cfgMem;
    unsigned char * bufMem[NUM_CHANNEL];
    int numBuffers;
    int intrFds[NUM_CHANNEL];
    pthread_t sendThreads[NUM_CHANNEL];
    pthread_t recvThreads[NUM_CHANNEL];
};

//global variables
struct fpga_dev *fpgaDev;
bool fpgaInUse = false;

/* Initialize/finalize functions. */
__attribute__((constructor))
int fpga_init() {

	if(!fpgaInUse){
			int fd;
			int i = 0;
			char buf[50];
			int timeout = 10*1000; //10 sec
                        unsigned int stat;

			// Allocate space for the fpga_dev
			fpgaDev = malloc(sizeof(fpga_dev));
			if (fpgaDev == NULL) {
				fprintf(stderr, "Failed to malloc fpga_dev\n");
				exit(EXIT_FAILURE);
				//return -ENOMEM;
			}
			
			
			// Open the device file.
			fd = open(FPGA_DEV_PATH, O_RDWR | O_SYNC);
			if(fd < 0) {
				return fd;
			}
			
			// Map the DMA regions.
			for (i = NUM_CHANNEL-1; i >= 0; i--) {
				fpgaDev->bufMem[i] = mmap(NULL, BUF_SIZE, PROT_READ | PROT_WRITE, 
					MAP_FILE | MAP_SHARED, fd, PCI_BAR_0_SIZE + (BUF_SIZE*i));
				if(fpgaDev->bufMem[i] == MAP_FAILED)
					break;
			}
			fpgaDev->numBuffers = NUM_CHANNEL-1 - i;
			if(fpgaDev->numBuffers == 0)
				exit(EXIT_FAILURE);
				//return -ENOMEM;
			
			// Map the config region.
			fpgaDev->cfgMem = mmap(NULL, PCI_BAR_0_SIZE, PROT_READ | PROT_WRITE, 
				MAP_FILE | MAP_SHARED, fd, 0);
			if(fpgaDev->cfgMem == MAP_FAILED) {
				fprintf(stderr, "mmap() failed to map fpga config region\n");
				exit(EXIT_FAILURE);
				//return -ENOMEM;
			}

			// Initialize the channel fds
			for (i = 0; i < NUM_CHANNEL; i++)
				fpgaDev->intrFds[i] = -1;


			for (i = 0; i < NUM_CHANNEL; i++){
				fpga_channel_open(i,timeout);
			}

			//automatic exit function
			fpgaInUse = true;
            		//Read the status register to get the link status
		        /*stat = fpga_reg_rd(STA_REG);
		        if(stat==0xFFFFFFFF){
                		printf("Fatal Error: The FPGA not detected by the host\n");
				exit(EXIT_FAILURE);
	    		}		
			if(!(stat&0x40000000))
				printf("Fatal Error: The DRAM memory not detected by FPGA\n");             */
			fprintf(stderr,"fpga initiated \n");
			atexit(fpga_close);
			return 0;
	}
	else{
		fprintf(stderr,"FPGA is already in use\n");
		return ERRINUSE;
	}
}



/* Channel opening/closing/configuring functions. */
int fpga_channel_open(int channel, int timeout) {
    int fd;
    char buf[50];
    
    if (fpgaDev->intrFds[channel] >= 0)
        return 0;
    sprintf(buf, "%s/%s%02d", FPGA_INTR_PATH, IRQ_FILE, channel);
    fd = open(buf, O_RDWR);
    if (fd < 0)
        return fd;
    fpgaDev->intrFds[channel] = fd;
    
    if (timeout >= 0)
        return ioctl(fpgaDev->intrFds[channel], IOCTL_SET_TIMEOUT, timeout);
    
    return 0;
}



void fpga_close() {
	if(fpgaInUse){
		int i;
			
		// Unmap the memory regions.
		for (i = fpgaDev->numBuffers-1; i >= 0; i--) {
			if (fpgaDev->bufMem[i] != NULL)
				munmap(fpgaDev->bufMem[i], BUF_SIZE);
				fpgaDev->bufMem[i] = NULL;
		}
		if (fpgaDev->cfgMem != NULL)
			munmap(fpgaDev->cfgMem, PCI_BAR_0_SIZE);
		fpgaDev->cfgMem = NULL;
			
		// Close the device file.
		if (fpgaDev->fd >= 0)
			close(fpgaDev->fd);
		fpgaDev->fd = -1;
		fprintf(stderr,"fpga closed \n");
		fpgaInUse=false;
	}
	else{
		fprintf(stderr,"cannot close fpga, it was never opened");
	}
}


/* Function to read a single 32-bit value from the FPGA */
unsigned int fpga_read_word(unsigned char * mptr) {
    return *((unsigned int *)mptr);
}

/* Function to write a single 32-bit value to the FPGA */
void fpga_write_word(unsigned char * mptr, unsigned int val) {
    *((unsigned int *)mptr) = val;
}


/*The main function used to send PCIe data to the SWITCH DDR interface and the PCIe user stream interfaces
    inputs :destination type (USERPCIE1, USERPCIE2 ...)
            data buffer holdin the send data
            total length of the transfer
            target address in case of data transfer to DDR and blocking-non blocking indication in case of user data transfer
    output :  Returns total number of bytes sent
    The function rounds the transfer size to 64byte boundary for PCIe packet requirement
    The total transfer data is divided into 4MB chunks to fit into the host DMA buffers.
*/
//void *fpga_send_data(void *send_parameters){
int fpga_send_data(DMA_PNT dest, unsigned char * senddata, int sendlen, unsigned int addr) {
        unsigned int rtn;
        unsigned int len;
        unsigned int ddr_addr;
        unsigned int size = BUF_SIZE;
        unsigned int amt;
        unsigned int buf;
        unsigned int pre_buf;
        unsigned int tmp_buf;
        //my_send_param *send_param;
        //send_param = (my_send_param *)send_parameters;
        int sent = 0;
        //DMA_PNT dest;
        //unsigned char * senddata;
        //int sendlen;
        //unsigned int addr;
        //dest = send_param->dest;
        //senddata = send_param->senddata;
        //sendlen = send_param->sendlen;
        //addr = send_param->addr;
        if(dest == ICAP){
            buf = 0;
            pre_buf = 1;
            len = (sendlen+63)&0xFFFFFFC0;                         //Align length to 64 bytes
            // Send initial transfer request.
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], senddata, amt);
            fpga_reg_wr(0x50,rtn); 
            fpga_reg_wr(0x54,amt);
            fpga_reg_wr(CTRL_REG,0x100001);
            sent += amt;
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);         
            }
            while(1){
               fpga_wait_interrupt(config);          //Wait for interrupt from first buffer
               if (sent < len) {
           	   fpga_reg_wr(0x50,rtn); 
                   fpga_reg_wr(0x54,amt);
                   fpga_reg_wr(CTRL_REG,0x100001); 
                   sent += amt;
                   tmp_buf = buf;
                   buf = pre_buf;
                   pre_buf = tmp_buf;                                 
                   if (sent < len) {
                       amt = (len-sent < size ? len-sent : size);
                       rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                   }
               }
               else{
                   return sent;
               }
            }
        }
        else if(dest == USERPCIE1){
            buf = 2;
            pre_buf = 3;
            len = sendlen;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], senddata, amt);
            fpga_reg_wr(PC_USER1_DMA_SYS,rtn);
            fpga_reg_wr(PC_USER1_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,SEND_USER1_DATA|0x00000001);
	    //printf("Buffer address is %0x\n",rtn); 
            sent += amt; 
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);         
            }            
            if(addr != 0){
                while(1){
                    fpga_wait_interrupt(hostuser1);  
                    //printf("Sent is %d\n",sent);
                    if (sent < len) {
                        fpga_reg_wr(PC_USER1_DMA_SYS,rtn);
                        fpga_reg_wr(PC_USER1_DMA_LEN,amt);
                        fpga_reg_wr(CTRL_REG,SEND_USER1_DATA|0x00000001); 
						//printf("Buffer address is %0x\n",rtn); 
						sent += amt; 
                        tmp_buf = buf;
                        buf = pre_buf;
                        pre_buf = tmp_buf;     
                        if (sent < len){                         
                            amt = (len-sent < size ? len-sent : size);
                            rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                        }
                    }
                    else
                       return sent;
                }
            }
        }
        else if(dest == USERPCIE2){
            buf = 4;
            pre_buf = 5;
            len = sendlen;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], senddata, amt);
            fpga_reg_wr(PC_USER2_DMA_SYS,rtn);
            fpga_reg_wr(PC_USER2_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,SEND_USER2_DATA|0x00000001);  
            sent += amt; 
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);         
            }            
            if(addr != 0){
                while(1){
                    fpga_wait_interrupt(hostuser2);  
                    if (sent < len) {
                        fpga_reg_wr(PC_USER2_DMA_SYS,rtn);
                        fpga_reg_wr(PC_USER2_DMA_LEN,amt);
                        fpga_reg_wr(CTRL_REG,SEND_USER2_DATA|0x00000001); 
                        sent += amt;
                        tmp_buf = buf;
                        buf = pre_buf;
                        pre_buf = tmp_buf;     
                        if (sent < len){                         
                            amt = (len-sent < size ? len-sent : size);
                            rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                        }
                    }
                    else
                       return sent;
                }
            }
        }
        else if(dest == USERPCIE3){
            buf = 6;
            pre_buf = 7;
            len = sendlen;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], senddata, amt);
            fpga_reg_wr(PC_USER3_DMA_SYS,rtn);
            fpga_reg_wr(PC_USER3_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,SEND_USER3_DATA|0x00000001); 
            sent += amt; 
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);         
            }            
            if(addr != 0){
                while(1){
                    fpga_wait_interrupt(hostuser3);  
                    if (sent < len) {
                        fpga_reg_wr(PC_USER3_DMA_SYS,rtn);
                        fpga_reg_wr(PC_USER3_DMA_LEN,amt);
                        fpga_reg_wr(CTRL_REG,SEND_USER3_DATA|0x00000001); 
                        sent += amt;
                        tmp_buf = buf;
                        buf = pre_buf;
                        pre_buf = tmp_buf;     
                        if (sent < len){                         
                            amt = (len-sent < size ? len-sent : size);
                            rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                        }
                    }
                    else
                       return sent;
                }
            }
        }
        else if(dest == USERPCIE4){
            buf = 8;
            pre_buf = 9;
            len = sendlen;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], senddata, amt);
            fpga_reg_wr(PC_USER4_DMA_SYS,rtn);
            fpga_reg_wr(PC_USER4_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,SEND_USER4_DATA|0x00000001);  
            sent += amt; 
            // Still more data, send to next buffer
            if (sent < len) {
                amt = (len-sent < size ? len-sent : size);
                rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);         
            }            
            if(addr != 0){
                while(1){
                    fpga_wait_interrupt(hostuser4);  
                    if (sent < len) {
                        fpga_reg_wr(PC_USER4_DMA_SYS,rtn);
                        fpga_reg_wr(PC_USER4_DMA_LEN,amt);
                        fpga_reg_wr(CTRL_REG,SEND_USER4_DATA|0x00000001);  
                        sent += amt;
                        tmp_buf = buf;
                        buf = pre_buf;
                        pre_buf = tmp_buf;     
                        if (sent < len){                         
                            amt = (len-sent < size ? len-sent : size);
                            rtn = write(fpgaDev->intrFds[pre_buf], senddata+sent, amt);
                        }
                    }
                    else
                       return sent;
                }
            }
        }
        else
            printf("Wrong destination\n");
    return 0;
}


/* Receiving data functions. */
int fpga_recv_data(DMA_PNT dest, unsigned char * recvdata, int recvlen, unsigned int addr) {
//void *fpga_recv_data(void *recv_parameters) {
        unsigned int rtn;
        unsigned int len;
        unsigned int size;
        unsigned int amt;
        unsigned int buf;
        unsigned int pre_buf;
        unsigned int tmp_buf;
        unsigned int ddr_addr;
        int copyd = 0;
        int sent = 0;
        int pre_amt = 0;
        //my_send_param *recv_param;
        //recv_param = (my_send_param *)recv_parameters;
        //DMA_PNT dest;
        //unsigned char * recvdata;
        //int recvlen;
        //unsigned int addr;
        //dest = recv_param->dest;
        //recvdata = recv_param->senddata;
        //recvlen = recv_param->sendlen;
        //addr = recv_param->addr;
        if(dest == USERPCIE1){
            buf = 10;
            pre_buf = 11;
            len = recvlen;
            size = BUF_SIZE;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], NULL, 0);
            fpga_reg_wr(USER1_PC_DMA_SYS,rtn);
            fpga_reg_wr(USER1_PC_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,RECV_USER1_DATA|0x00000001);
            sent += amt;
            pre_amt = amt; 
            if(addr != 0){
               while(1){
                  fpga_wait_interrupt(user1host);          //Wait for interrupt from first buffer
                  if (sent < len) { 
                      rtn = write(fpgaDev->intrFds[pre_buf], NULL, 0);  //just to get the DMA buffer address
                      amt = (len-sent < size ? len-sent : size); 
                      fpga_reg_wr(USER1_PC_DMA_SYS,rtn);
                      fpga_reg_wr(USER1_PC_DMA_LEN,amt);
                      fpga_reg_wr(CTRL_REG,RECV_USER1_DATA|0x00000001);
                      sent += amt;               
                  }
                  rtn = read(fpgaDev->intrFds[buf],recvdata+copyd,pre_amt);
                  copyd += pre_amt;
                  if (copyd >= len) {
                      return copyd;
                  }
                  pre_amt = amt;              
                  tmp_buf = buf;
                  buf = pre_buf;
                  pre_buf = tmp_buf; 
               }
           }
        }        
        else if(dest == USERPCIE2){
            buf = 12;
            pre_buf = 13;
            copyd = 0;
            len = recvlen;
            size = BUF_SIZE;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], NULL, 0);
            fpga_reg_wr(USER2_PC_DMA_SYS,rtn);
            fpga_reg_wr(USER2_PC_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,RECV_USER2_DATA|0x00000001);
            sent += amt;
            pre_amt = amt; 
            if(addr != 0){
               while(1){
                   fpga_wait_interrupt(user2host);          //Wait for interrupt from first buffer
                   if (sent < len) { 
                       rtn = write(fpgaDev->intrFds[pre_buf], NULL, 0);  //just to get the DMA buffer address
                       amt = (len-sent < size ? len-sent : size); 
                       fpga_reg_wr(USER2_PC_DMA_SYS,rtn);
                       fpga_reg_wr(USER2_PC_DMA_LEN,amt);
                       fpga_reg_wr(CTRL_REG,RECV_USER2_DATA|0x00000001);
                       sent += amt;               
                  }
                  rtn = read(fpgaDev->intrFds[buf],recvdata+copyd,pre_amt);
                  copyd += pre_amt;
                  if (copyd >= len) {
                     return copyd;
                  }
                  pre_amt = amt;              
                  tmp_buf = buf;
                  buf = pre_buf;
                  pre_buf = tmp_buf; 
               } 
           }
        }   
        else if(dest == USERPCIE3){
            buf = 14;
            pre_buf = 15;
            len = recvlen;
            size = BUF_SIZE;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], NULL, 0);
            fpga_reg_wr(USER3_PC_DMA_SYS,rtn);
            fpga_reg_wr(USER3_PC_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,RECV_USER3_DATA|0x00000001);
            sent += amt;
            pre_amt = amt; 
            if(addr != 0){
               while(1){
                  fpga_wait_interrupt(user3host);          //Wait for interrupt from first buffer
                  if (sent < len) { 
                      rtn = write(fpgaDev->intrFds[pre_buf], NULL, 0);  //just to get the DMA buffer address
                      amt = (len-sent < size ? len-sent : size); 
                      fpga_reg_wr(USER3_PC_DMA_SYS,rtn);
                      fpga_reg_wr(USER3_PC_DMA_LEN,amt);
                      fpga_reg_wr(CTRL_REG,RECV_USER3_DATA|0x00000001);
                      sent += amt;               
                  }
                  rtn = read(fpgaDev->intrFds[buf],recvdata+copyd,pre_amt);
                  copyd += pre_amt;
                  if (copyd >= len) {
                      return copyd;
                  }
                  pre_amt = amt;              
                  tmp_buf = buf;
                  buf = pre_buf;
                  pre_buf = tmp_buf; 
               } 
           }
        }
        else if(dest == USERPCIE4){
            buf = 16;
            pre_buf = 17;
            len = recvlen;
            size = BUF_SIZE;
            amt = len < size ? len : size;
            rtn = write(fpgaDev->intrFds[buf], NULL, 0);
            fpga_reg_wr(USER4_PC_DMA_SYS,rtn);
            fpga_reg_wr(USER4_PC_DMA_LEN,amt);
            fpga_reg_wr(CTRL_REG,RECV_USER4_DATA|0x00000001);
            sent += amt;
            pre_amt = amt; 
            if(addr != 0){
               while(1){
                  fpga_wait_interrupt(user4host);          //Wait for interrupt from first buffer
                  if (sent < len) { 
                      rtn = write(fpgaDev->intrFds[pre_buf], NULL, 0);  //just to get the DMA buffer address
                      amt = (len-sent < size ? len-sent : size); 
                      fpga_reg_wr(USER4_PC_DMA_SYS,rtn);
                      fpga_reg_wr(USER4_PC_DMA_LEN,amt);
                      fpga_reg_wr(CTRL_REG,RECV_USER4_DATA|0x00000001);
                      sent += amt;               
                  }
                  rtn = read(fpgaDev->intrFds[buf],recvdata+copyd,pre_amt);
                  copyd += pre_amt;
                  if (copyd >= len) {
                      return copyd;
                  }
                  pre_amt = amt;              
                  tmp_buf = buf;
                  buf = pre_buf;
                  pre_buf = tmp_buf; 
               } 
           }
        }
        else
            printf("Wrong destination\n");
    return 0;                
}


int fpga_recv_local_data(DMA_PNT dest, unsigned char * recvdata, int recvlen) {
	int rtn;
        if(dest == USERPCIE1){
           rtn = read(fpgaDev->intrFds[10],recvdata,recvlen);
        }        
        else if(dest == USERPCIE2){
           rtn = read(fpgaDev->intrFds[12],recvdata,recvlen);
        }  
        else if(dest == USERPCIE3){
           rtn = read(fpgaDev->intrFds[14],recvdata,recvlen);
        }
        else if(dest == USERPCIE4){
               rtn = read(fpgaDev->intrFds[16],recvdata,recvlen);
	}
        else
            printf("Wrong destination\n");
    return 0;                
}


/*Function to sync interrupt on a specified channel. The channels can be hostddr, ddrhost, hostuser1 to 4, user1 to 4 to host, ddruser1 to 4, user1 to 4 to ddr, userhost and enet*/
int fpga_wait_interrupt(DMA_TYPE dma_type) {
    int rtn;
    rtn= read(fpgaDev->intrFds[0], NULL,dma_type);      
} 



/* Low level data transferring and buffer management functions. */
int fpga_reg_wr(unsigned int regaddr, unsigned int regdata) {
	fpga_write_word(fpgaDev->cfgMem + regaddr, regdata);
	return 0;
}

/* Low level data transferring and buffer management functions. */
int fpga_reg_rd(unsigned int regaddr) {
	return fpga_read_word(fpgaDev->cfgMem + regaddr);
}


/*Function to issue a soft reset to the user logic
  Input : Reset active polarity
  The function initially deasserts the reset, then asserts and again deasserts*/
void user_soft_reset(unsigned int polarity) {
   int rtn;
   rtn = fpga_reg_rd(UCTR_REG); 
   if(polarity == 0) {
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFF);
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFE);
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFF);
  }
  else {
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFE);
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFF);
      fpga_reg_wr(UCTR_REG,rtn & 0xFFFFFFFE);
  }
}

/*Function to configure the clock frequency to the user logic
  Input : Required frequency. Currently supports 250, 200, 150 and 100
*/
int user_set_clk(unsigned int freq){
   int rtn;
   rtn = fpga_reg_rd(UCTR_REG);            //Read the current control register value since both soft reset and clock config are in the same register
   switch(freq){
       case 250:
           fpga_reg_wr(UCTR_REG,0x1);
       break;
       case 200:
           fpga_reg_wr(UCTR_REG,0x3);
       break;
       case 150:
           fpga_reg_wr(UCTR_REG,0x5);
       break;
       case 100:
           fpga_reg_wr(UCTR_REG,0x7);
       break;
       default:
           printf("unsupported frequency\n");
           return -1;
       break;
   }
   return 0;
}
