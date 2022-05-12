#include <stdio.h>
#include <stdlib.h>

#include "lodepng.h"

__global__ void blurImage(unsigned char * inputImage, unsigned char * outputImage, int width, int height){


	int uniqueID = blockDim.x * blockIdx.x + threadIdx.x; //to create unique ID for each pixel
	
	//printf("%d \n", uniqueID);

	int row = uniqueID / width;
	int col = uniqueID % width;
	
	//printf("width2 = %d height2 = %d \n", width, height);

	//printf("UID = %d col = %d row = %d \n",uniqueID ,col, row);	
	
	//targetPixel = the pixel that the current thread is bluring
	int targetPixel = uniqueID * 4;
	
	
	//check if row is equal to 0, if equal to 0 then you are on the top of the image	
	int topBorder = 0;
	if(row == 0){
		topBorder = 1;
	}
	
	//check if row is equal to height - 1, if row is equal then you are on the bottom of the image
	int bottomBorder = 0;
	if(row == height - 1){
		bottomBorder = 1;
	}
	
	//check if col is equal to 0, if equal to 0 then you are at the left border of the image
	int westBorder = 0;
	if(col == 0){
		westBorder = 1;
	}
	
	//check if col is equal to 0, if equal to 0 then you are at the right border of the image
	int eastBorder = 0;
	if( col == width - 1){
		eastBorder = 1;
	}
	
	//this sets the RGBT values of the target pixel access the array and assign the colour to the appropriate value
	int r = inputImage[targetPixel+0];
	int g = inputImage[targetPixel+1];
	int b = inputImage[targetPixel+2];
	int t = inputImage[targetPixel+3];

	//printf("UID = %d t = %d r = %d \n", uniqueID, t ,r);
	
	//used to declare North red, South red, West red, East red etc
	int Nr = 0, Ng = 0, Nb = 0, Nt = 0;
	int Sr = 0, Sg = 0, Sb = 0, St = 0;
	int Wr = 0, Wg = 0, Wb = 0, Wt = 0;
	int Er = 0, Eg = 0, Eb = 0, Et = 0;
	
	//used to declare diaginal NE, NW etc
	int NEr = 0, NEg = 0, NEb = 0, NEt = 0;
	int NWr = 0, NWg = 0, NWb = 0, NWt = 0;
	int SWr = 0, SWg = 0, SWb = 0, SWt = 0;
	int SEr = 0, SEg = 0, SEb = 0, SEt = 0;
	
	
	//used for the math to average the pixel (blur)
	int pixelCount = 1;
	
	//check used to see if the primary pixel is on the top of the image
	if(topBorder != 1){
		//not on the top border therefore pixels above current row
		
		int northPixelIndex = ((row - 1)* width * 4) + (col * 4);
		//printf("northPixelIndex = %d\n", northPixelIndex);
		
		/* 	(row - 1) = 0 * 3 = 0 * 4 = 0 (col = 1 * 4) = 4 
			total is 4th index in array which is pixel[1] value R
			
			this is the algroithm to find the north pixel of the target pixel
					(x-1)*y*4+(z*4);
		*/
				
		Nr = inputImage[northPixelIndex];
		Ng = inputImage[northPixelIndex + 1];
		Nb = inputImage[northPixelIndex + 2];
		Nt = inputImage[northPixelIndex + 3];
		
		pixelCount++;
		
		//printf("UID = %d Nr = %d Ng = %d Nb = %d Nt = %d\n",uniqueID ,Nr,Ng,Nb,Nt);
		
			//northEast - NE
			if(eastBorder != 1){
				
				int NEpixelIndex = ((row - 1)* width * 4) + ((col + 1) * 4);
				
				NEr = inputImage[NEpixelIndex];
				NEg = inputImage[NEpixelIndex + 1];
				NEb = inputImage[NEpixelIndex + 2];
				NEt = inputImage[NEpixelIndex + 3];
				
				pixelCount++;
			}
			
			if(westBorder !=1 ){
				
				int NWpixelIndex = ((row - 1)* width * 4) + ((col - 1) * 4);
				
				NWr = inputImage[NWpixelIndex];
				NWg = inputImage[NWpixelIndex + 1];
				NWb = inputImage[NWpixelIndex + 2];
				NWt = inputImage[NWpixelIndex + 3];
				
				pixelCount++;
			
			}
		
	}
	
	if(bottomBorder != 1){
		
		int southPixelIndex = ((row + 1)* width * 4) + (col * 4);
		
		Sr = inputImage[southPixelIndex];
		Sg = inputImage[southPixelIndex + 1];
		Sb = inputImage[southPixelIndex + 2];
		St = inputImage[southPixelIndex + 3];
		
		pixelCount++;
		
			if(westBorder != 1){
				
				int SWPixelIndex = ((row + 1)* width * 4) + ((col - 1) * 4);
		
				SWr = inputImage[SWPixelIndex];
				SWg = inputImage[SWPixelIndex + 1];
				SWb = inputImage[SWPixelIndex + 2];
				SWt = inputImage[SWPixelIndex + 3];
				
				pixelCount++;
			}
			
			if(eastBorder != 1){
				
				int SEPixelIndex = ((row + 1)* width * 4) + ((col + 1)* 4);
				
				SEr = inputImage[SEPixelIndex];
				SEg = inputImage[SEPixelIndex + 1];
				SEb = inputImage[SEPixelIndex + 2];
				SEt = inputImage[SEPixelIndex + 3];
				
				pixelCount++;
			}
	}
	
	if(westBorder != 1){
			
		int westPixelIndex = (row * width * 4) + ((col - 1) * 4);
		
		Wr = inputImage[westPixelIndex];
		Wg = inputImage[westPixelIndex + 1];
		Wb = inputImage[westPixelIndex + 2];
		Wt = inputImage[westPixelIndex + 3];
		
		pixelCount++;
	}
	
	if(eastBorder != 1){
		
		int eastPixelIndex = (row * width * 4) + ((col + 1) *4);
		
		Er = inputImage[eastPixelIndex];
		Eg = inputImage[eastPixelIndex + 1];
		Eb = inputImage[eastPixelIndex + 2];
		Et = inputImage[eastPixelIndex + 3];
		
		pixelCount++;
	}
	
	
	int sumR = r + Nr + Sr + Er + Wr + NWr + NEr + SEr + SWr;
	int sumG = g + Ng + Sg + Eg + Wg + NWg + NEg + SEg + SWg;
	int sumB = b + Nb + Sb + Eb+ Wb + NWb + NEb + SEb + SWb;
	
	//printf("UID = %d sumR = %d sumG = %d sumB = %d \n", uniqueID, sumR, sumG, sumB);
	//printf("Uid = %d pixelCount = %d \n", uniqueID, pixelCount);
	
	int averageR = sumR / pixelCount;
	int averageG = sumG / pixelCount;
	int averageB = sumB / pixelCount;
	int averageT = t;
	
	//printf("UID = %d averageR = %d averageG = %d averageB = %d pixelCount = %d \n",uniqueID, averageR, averageG, averageB, pixelCount);
	//this assignes the newImage with the average pixel values creating the original image blurred
	outputImage[targetPixel] = averageR;
	outputImage[targetPixel + 1] = averageG;
	outputImage[targetPixel + 2] = averageB;
	outputImage[targetPixel + 3] = averageT;
	
	
}


int main(int argc, char ** argv){
	
	unsigned char* cpuImage; //stores the image data on the CPU	
	unsigned int errorDecode; //varible will hold whether there was issues loading the PNG image
	unsigned  int width, height; //stores the width and heught of the image	
	
	char * filename = argv[1];
	char * newFileName = argv[2];
	
	errorDecode = lodepng_decode32_file(&cpuImage, &width, &height, filename);
	if(errorDecode){
	printf("error %u: %s\n", errorDecode, lodepng_error_text(errorDecode));
	}
	
	printf("width = %d height = %d \n", width, height);
	
	int arrayImageSize = width*height*4; //Store number accurate to the size of the array needed
	int memorySize = arrayImageSize * sizeof(unsigned char); //Store memory size needed in variable+
	
	unsigned char cpuOutImage[arrayImageSize]; //used to store the array size needed to create the image
	
	unsigned char* gpuInput;
	unsigned char* gpuOutput;
	
	cudaMalloc((void**) &gpuInput, memorySize);
	cudaMalloc((void**) &gpuOutput, memorySize);
	
	cudaMemcpy(gpuInput, cpuImage, memorySize, cudaMemcpyHostToDevice);
	
	//if width = 3 and height = 3, blueImage will run 9 times (3x3)
	blurImage <<< dim3(width, 1, 1),dim3(height, 1, 1) >>> (gpuInput, gpuOutput, width, height);
	cudaDeviceSynchronize();
	
	cudaMemcpy(cpuOutImage, gpuOutput, memorySize, cudaMemcpyDeviceToHost);
	
	unsigned int errorEncode = lodepng_encode32_file(newFileName, cpuOutImage, width, height);
	if(errorEncode) {
	printf("error %u: %s\n", errorEncode, lodepng_error_text(errorEncode));
	}
	cudaFree(gpuInput);
	cudaFree(gpuOutput);
}
