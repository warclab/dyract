#include <stdio.h>
#include <stdlib.h>
#include <unistd.h> 
#include "fpga.h"

#define header_size 1078
#define image_size (512*512)

unsigned int gDATA[512*514];  //Buffer to hold the send data

int main(int argc, char *argv[]) {

    FILE *in_file;
    FILE *out_file;
    char *file_header;
    char *file_data;
    int rtn;
    int sent = 0;
    int recv = 0;
    int len = 512*512;
    int line_buff = 1;
    FILE *file;
    char *buffer;
    unsigned long fileLen;
    in_file = fopen(argv[1],"rb");
    if (!in_file)
    {
	fprintf(stderr, "Unable to open image file\n");
	return;
    }
    file_header=(char *)malloc(header_size);
    fread(file_header, 1, header_size, in_file);
    //Save file data
    file_data=(char *)malloc(image_size);
    fread(file_data, 4, image_size, in_file);
    //Close the image file
    fclose(in_file);
    //Open a new file to store the result
    out_file = fopen(argv[2],"wb");
    //Store image header
    fwrite(file_header, 1, header_size, out_file);
    //Open partial bitstream file
    file = fopen(argv[3], "rb");
    if (!file)
    {
	fprintf(stderr, "Unable to open partial bit file\n");
	return;
    }
    //Get file length
    fseek(file, 0, SEEK_END);
    fileLen=ftell(file);
    fseek(file, 0, SEEK_SET);
    //Allocate memory
    buffer=(char *)malloc(fileLen+1);
    if (!buffer)
    {
	fprintf(stderr, "Memory error!\n");
        fclose(file);
	return;
    }
    //Read file contents into buffer
    fread(buffer, 1, fileLen, file);
    fclose(file);
    //Send partial bitstream to FPGA
    rtn = fpga_send_data(ICAP, (unsigned char *) buffer, fileLen, 0); 
    free(buffer);
    //Reset user logic
    rtn = fpga_reg_wr(UCTR_REG,0x0);
    rtn = fpga_reg_wr(UCTR_REG,0x1);
    rtn = fpga_reg_wr(CTRL_REG,0x0);
    rtn = fpga_reg_wr(CTRL_REG,0x1);
    if(strcmp(argv[4],"s")==0) {
        printf("Streaming filter");
    	while(sent < len){
	  rtn = fpga_send_data(USERPCIE1,(unsigned char *) file_data+sent,4096,1);
	  rtn = fpga_recv_data(USERPCIE1,(unsigned char *) gDATA+sent,4096,1);
	  sent += 4096;
        }  
    }
    else if (strcmp(argv[4],"c")==0) {
      while(sent < len){
        rtn = fpga_send_data(USERPCIE1,(unsigned char *) file_data+sent,512,1);
        rtn = fpga_send_data(USERPCIE2,(unsigned char *) file_data+sent+512,512,1);
        rtn = fpga_send_data(USERPCIE3,(unsigned char *) file_data+sent+1024,512,1);
        //rtn = fpga_wait_interrupt(hostuser1);
        //rtn = fpga_wait_interrupt(hostuser2);
        //rtn = fpga_wait_interrupt(hostuser3);
        rtn = fpga_reg_wr(0x400,0x1);
        rtn = fpga_recv_data(USERPCIE1,(unsigned char *) gDATA+recv,512,1);
	//printf("Data receive done\n");
	rtn = fpga_reg_wr(0x400,0x0);
	sent += 512;
        recv += 512;
      }
    }
    else
        printf("Wrong filter type %s\n",argv[3]);
    fwrite(gDATA,1,image_size+2,out_file);
    fclose(out_file);
    free(file_header);
    free(file_data);
    return 0;
}
