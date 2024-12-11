#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include <string.h>
#include "encoding.h"
#include <unistd.h>
#include "stdatomic.h"
#include "dma.h"

#define SRAM1_ADDR 0x20000000
#define SRAM2_ADDR 0x30000000
#define DATA_LEN   0x0000024C 

void dma_init(void);
void dma_cfg(uint32_t src_addr, uint32_t dst_addr, uint32_t data_len);
void dma_transfer_begin(void);

int main(int argc, char **argv)
{
  set_csr(mie, MIP_MEIP);
  set_csr(mstatus, MSTATUS_MIE);

  //conv
  uint32_t *ptr = SRAM1_ADDR;
  uint32_t *ptr_o;
  uint32_t kernel1[3][3];
  uint32_t kernel2[3][3];
  uint32_t kernel3[3][3];

  uint32_t feature1[16][16];
  uint32_t feature2[16][16];
  uint32_t feature3[16][16];

  for(int i = 0; i < 9; i++)
  {
    kernel1[i/3][i%3] = *ptr;
    ptr = ptr + 1;
  }
  
  for(int i = 0; i < 9; i++)
  {
    kernel2[i/3][i%3] = *ptr;
    ptr = ptr + 1;
  }

  for(int i = 0; i < 9; i++)
  {
    kernel3[i/3][i%3] = *ptr;
    ptr = ptr + 1;
  }
  

  for(int i = 0; i < 256; i++)
  {
    feature1[i/16][i%16] = *ptr;
    ptr = ptr + 1;
  }

  for(int i = 0; i < 256; i++)
  {
    feature2[i/16][i%16] = *ptr;
    ptr = ptr + 1;
  }

  for(int i = 0; i < 256; i++)
  {
    feature3[i/16][i%16] = *ptr;
    ptr = ptr + 1;
  }
  
  ptr_o = ptr;
  

  int out_size = 16 - 3 + 1;
  uint32_t sum = 0;
    //calculate output1
    for(int i = 0; i < out_size; i++) {
        for(int j = 0; j < out_size; j++) {
            sum = 0;
            for(int ki = 0; ki < 3; ki++) {
                for(int kj = 0; kj < 3; kj++) {
                    sum += kernel1[ki][kj] * feature1[i+ki][j+kj];
                }
            }
            *ptr = sum;
	    //printf("%d\n", sum);
	    ptr = ptr + 1;
        }
    }
    
    //calculate output2
    for(int i = 0; i < out_size; i++) {
        for(int j = 0; j < out_size; j++) {
            sum = 0;
            for(int ki = 0; ki < 3; ki++) {
                for(int kj = 0; kj < 3; kj++) {
                    sum += kernel2[ki][kj] * feature2[i+ki][j+kj];
                }
            }
            *ptr = sum;
	    //printf("%d\n", sum);
	    ptr = ptr + 1;
        }
    }

    //calculate output3
    for(int i = 0; i < out_size; i++) {
        for(int j = 0; j < out_size; j++) {
            sum = 0;
            for(int ki = 0; ki < 3; ki++) {
                for(int kj = 0; kj < 3; kj++) {
                    sum += kernel3[ki][kj] * feature3[i+ki][j+kj];
                }
            }
            *ptr = sum;
	    //printf("%d\n", sum);
	    ptr = ptr + 1;
        }
    }

  //dma_init();
  dma_cfg(ptr_o, SRAM2_ADDR, DATA_LEN);

  uint32_t *temp = 0x1000000C;//state register
  uint32_t *ptr_o2 = SRAM2_ADDR;//sram2 begin location
  //printf("test state register: %x\n", *temp);
  dma_transfer_begin(); 

  while(DMA_REG_8(DMA_REG_STA) != 0)
  {
    //transfer

  }

  printf("dma_transfer done\n");
  //printf("test state register: %x\n", *temp);
  
  //test
  int flag = 0;
  for(int i = 0; i < 588; i++)
  {
    if(*(ptr_o+i) == *(ptr_o2+i)) flag = 1;
    else {
      flag = 0;
      break;
    }

  }

  if(flag) printf("The verification pass!");
  else printf("The verfication fail!");

  DMA_REG_8(0x2560) = 1;

  return 0;	
}

void dma_init(void)
{
  DMA_REG_8(DMA_REG_STA) = DMA_STA_EN;
}

void dma_cfg(uint32_t src_addr, uint32_t dst_addr, uint32_t data_len)
{

  printf("SRC addr: %x, DST addr: %x, Data Length: %x\n", src_addr, dst_addr, data_len);
  DMA_REG_32(DMA_REG_SRCADDR) = src_addr;
  DMA_REG_32(DMA_REG_DSTADDR) = dst_addr;
  DMA_REG_32(DMA_REG_LEN) = data_len;
}

void dma_transfer_begin(void)
{
  DMA_REG_8(DMA_REG_STA) = DMA_STA_EN;
  printf("dma_transfer begin\n");
  
}
