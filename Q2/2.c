#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <crypt.h>
#include <unistd.h>
#include <pthread.h>

char* foundPassword;
 
struct threadArgs{
	int start;
	int finish;
	int threadId;
	char * saltEncrypted;
};

int count =0; //counter used to track number of combinations explored so far

/**
	dest = destination, src = source, start = start index of src string, length = length of src string
	e.g if source was abcdefg then -> src = abcdefg, start = 2, then it would be ab[c]defg, length = 7
	memcpy, the arguments is the 'to string, src = source string, + start index, length of array' 
*/
void substr(char *dest, char *src, int start, int length){
  memcpy(dest, src + start, length);
  *(dest + length) = '\0';
}

void* crackThread(void * args){

	struct threadArgs *tArgs = (struct threadArgs*) args;
	printf("Start: %d Finish:%d Thread id :%d \n", tArgs->start, tArgs->finish, tArgs->threadId);
	int start = tArgs->start;
	int finish = tArgs->finish;
	char *saltEncrypted = tArgs->saltEncrypted;
	
	
	//String used in hashing the password
	char salt[7];
	//The current combination of characters being checked
	//malloc used to store the password to prevent the memory being dumped and the password lost 
	char* plain = malloc(sizeof(char)*7);	
	char *encrypted;

	
	substr(salt,saltEncrypted, 0, 6);

	//printf("Thread '%d' range is '%d'\n", tArgs->threadId, finish - start);
	
	struct crypt_data data;
	data.initialized = 0;
	

	for(int i = start; i <= finish; i++){

		int totalTwoThreeCharCombinations = 100 * 26;
		int totalAlpabetCombinations = 26;
		
		int firCharOffset = (i / totalTwoThreeCharCombinations) ;
		char firstChar = (char)(firCharOffset + 65);
		
		//makes 0 -26 in the alphabet 
		int secCharAlphaOffset = ((i / 100) % totalAlpabetCombinations);
		char secondChar = (char)(secCharAlphaOffset + 65);
		
		int nums = i % 100;
		
		//printf("tid = %d  i = %d   %c %c %d \n",tArgs->threadId, i , firstChar, secondChar, nums);
		//printf("plain = %s \n", plain);
		
		
		
		sprintf(plain, "%c%c%02d", firstChar, secondChar, nums);
		encrypted = (char *) crypt_r(plain, salt, &data);
		//printf("Plain: %s Enc: %s\n", plain, encrypted);
		if(strcmp(saltEncrypted, encrypted) == 0){
			//no characters are diffrent in compaired strings saltEncrypted and encrypted				
			//found correct plain text i.e AA00
			foundPassword = plain;
			printf("plain = %s found password = %s \n",plain, foundPassword);
			pthread_exit(NULL);
		}
		
		if(foundPassword != NULL){
			//Will exit the remainding threads once the password is found
			pthread_exit(NULL);
		}
	}
}


int main (int argc, char * argv[]){
	//crack("$6$AS$EquwSMfZH6UigdniioE8VWG9qfQ/iburie8TclTB4HCYRomJtmDsM31EqQEbs5Zk09UzWMOtHoXFFmdKRKVoy/");
	int threadCount = 20;
	if (argc >1){
		threadCount = atoi(argv[1]);
	}

	char * originalEncrypted = "$6$AS$EquwSMfZH6UigdniioE8VWG9qfQ/iburie8TclTB4HCYRomJtmDsM31EqQEbs5Zk09UzWMOtHoXFFmdKRKVoy/";

	//total combinations = 67,600
	int totalCombinations = 26*26*100;
	printf("%d total combinations\n", totalCombinations);
	
	//remainder used to send the split the remaining number of threads evenly
	int remainder = totalCombinations%threadCount;
	printf("%d remainder\n", remainder);
	
	//total passoword combonations
	totalCombinations = totalCombinations-remainder;
	//used to work out how many combinations each thread will do
	
	int workPerThread = totalCombinations/threadCount;
	printf("%d work per thread\n", workPerThread);
	
	//used to correct the margin of error for the threads
	int threadCorrection = 0;
	
	struct threadArgs tArgs [threadCount];
	
	pthread_t *threads = malloc(threadCount *sizeof(pthread_t));
	//loop used to itterate over every possible combination in the thread range
	for(int i = 0; i < threadCount; i++){
		tArgs[i].start = threadCorrection;
		threadCorrection = threadCorrection + workPerThread;
		
		/*if statement used to add any remainder to the current thread if no 
		remainder then finish creating threads*/
		if(remainder > 0){
			tArgs[i].finish = threadCorrection;
			threadCorrection++;
			remainder--;
		} else {
			tArgs[i].finish = threadCorrection - 1;
		}
		printf("start = %d finish = %d\n", tArgs[i].start, tArgs[i].finish);
		tArgs[i].threadId = i;
		tArgs[i].saltEncrypted = originalEncrypted;
		
		/*once the treads have been split evenly this is to create those threads 
		and send to the function*/
		pthread_create(&threads[i], NULL, crackThread, &tArgs[i]);
	}

	for (int i =0; i<threadCount; i++){
		pthread_join(threads[i], NULL);
	}
	
	if(foundPassword != NULL){
		printf("The found combination is = %s\n", foundPassword);
	} else {
		printf("Password cannot be cracked\n");
	}
	free(foundPassword);
	return 0;
}
//  Encryption key = AB12 ------> $6$AS$EquwSMfZH6UigdniioE8VWG9qfQ/iburie8TclTB4HCYRomJtmDsM31EqQEbs5Zk09UzWMOtHoXFFmdKRKVoy/
//  Encryption key = AA00 ------> $6$AS$wKDMKDtx/s3ILNkNaRNFIM0w81/weD1UZ8daNhbQBXuj8L.7OY4trHnSraeizmFYrMwjlb1uRTPxu20rqhmMn/
