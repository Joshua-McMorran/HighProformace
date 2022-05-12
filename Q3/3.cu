#include <stdio.h>
#include <stdlib.h>


__device__ char* CudaCrypt(char* rawPassword){

	char * newPassword = (char *) malloc(sizeof(char) * 11);

	newPassword[0] = rawPassword[0] + 2;
	newPassword[1] = rawPassword[0] - 2;
	newPassword[2] = rawPassword[0] + 1;
	newPassword[3] = rawPassword[1] + 3;
	newPassword[4] = rawPassword[1] - 3;
	newPassword[5] = rawPassword[1] - 1;
	newPassword[6] = rawPassword[2] + 2;
	newPassword[7] = rawPassword[2] - 2;
	newPassword[8] = rawPassword[3] + 4;
	newPassword[9] = rawPassword[3] - 4;
	newPassword[10] = '\0';

	for(int i =0; i<10; i++){
		if(i >= 0 && i < 6){ //checking all lower case letter limits
			if(newPassword[i] > 122){
				newPassword[i] = (newPassword[i] - 122) + 97;
			}else if(newPassword[i] < 97){
				newPassword[i] = (97 - newPassword[i]) + 97;
			}
		}else{ //checking number section
			if(newPassword[i] > 57){
				newPassword[i] = (newPassword[i] - 57) + 48;
			}else if(newPassword[i] < 48){
				newPassword[i] = (48 - newPassword[i]) + 48;
			}
		}
	}
	return newPassword;
}


//comapres 2 strings and returns 0 if both strings are the same
__device__ int stringCompare(char * stringOne, char * stringTwo, int stringLength){
	
	int stringCount = 0;	
	for(int i = 0; i <stringLength; i++){
		if(stringOne[i] != stringTwo[i]){
				stringCount++;
		}
	}
	return stringCount;
}

__global__ void crack(char * alphabet, char * numbers, char * originalEncrypted, char * foundPassword){

	char genRawPass[4];
	char * encrypted; 
	
	genRawPass[0] = alphabet[blockIdx.x];
	genRawPass[1] = alphabet[blockIdx.y];

	genRawPass[2] = numbers[threadIdx.x];
	genRawPass[3] = numbers[threadIdx.y];
	
	encrypted = CudaCrypt(genRawPass); 
	
	//printf("genpass = %s encrypted = %s\n", genRawPass, encrypted);
	
	if(stringCompare(originalEncrypted, encrypted, 11) == 0){
		//printf("Password found encrypted = %s genpass = %s\n", encrypted, genRawPass);
		
		//sets the found password to the created empty char array on the GPU
		//*foundPassword = *genRawPass;  
		for(int i=0; i <4; i++){
			foundPassword[i] = genRawPass[i];
			//printf("The found 1 password is -> %s\n", foundPassword);
			printf("char 1 = %i char 2 = %i char 3 = %i char 4 = %i char 5 = %i\n",foundPassword[0], foundPassword[1], foundPassword[2],foundPassword[3], foundPassword[4]);
		}
		printf("found password 2 = %s\n", foundPassword);
	}
}

int main (int argc, char* argv[]){
	/*  encrypted examples:
		rnqdwy5134 pz38
		lhkuoq8453 jr61
		iehdwy3191 gz15
	*/

	char alphabet[26] = { 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z' };
	char numbers[10] = { '0', '1', '2', '3', '4', '5', '6' ,'7', '8', '9' };
	
	char * originalEncrypted = "rnqdwy5134";
	 
	
	//creating GPU variable and copying it
	char * gpuAlphabet;
	cudaMalloc((void**) &gpuAlphabet, sizeof(char) * 26); 
	cudaMemcpy(gpuAlphabet, alphabet, sizeof(char) * 26, cudaMemcpyHostToDevice);
	
	char * gpuNumbers;
	cudaMalloc((void**) &gpuNumbers, sizeof(char) * 10);
	cudaMemcpy(gpuNumbers, numbers, sizeof(char) * 10, cudaMemcpyHostToDevice);
	
	char *gpuOriginalEncrypted;
	cudaMalloc((void**) &gpuOriginalEncrypted, sizeof(char) * 11);
	cudaMemcpy(gpuOriginalEncrypted, originalEncrypted, sizeof(char) * 11, cudaMemcpyHostToDevice);
	
	//creates an empty char array allowing for the pass to be set on GPU
	char *gpuFoundPassword;
	cudaMalloc((void**) &gpuFoundPassword, sizeof(char) * 4);

	crack<<< dim3(26,26,1), dim3(10,10,1) >>>(gpuAlphabet, gpuNumbers, gpuOriginalEncrypted, gpuFoundPassword);
	cudaDeviceSynchronize();
	
	//copys the now set array from the GPU  back to the CPU
	char * foundPassword = (char*)malloc(sizeof(char)*4);
	cudaMemcpy(foundPassword, gpuFoundPassword, sizeof(char) * 4, cudaMemcpyDeviceToHost);
	
	
	printf("The found 3 password is -> '%c%c%c%c'\n", foundPassword[0],foundPassword[1],foundPassword[2],foundPassword[3]);
	
	//print char 1 at a time as 4 times for the 4 chars 
	
	//free all memory
	cudaFree(gpuAlphabet);
	cudaFree(gpuNumbers);
	cudaFree(gpuOriginalEncrypted);
	cudaFree(gpuFoundPassword);
	free(foundPassword);

} 
