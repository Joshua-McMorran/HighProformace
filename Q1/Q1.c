#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

typedef struct matrixPair{
	double** matrix_X;
	double** matrix_Y;
	int rowX;
	int colX;
	int rowY;
	int colY;
}mPair;


double** matrixMultiplaction(mPair matrixPair, int threadAmount){

	if(matrixPair.colX != matrixPair.rowY){
		//used to check if the matrices are able to be multiplied
		FILE *fp;
		fp = fopen("matrixresults1712403.txt","a");
		fprintf(fp, "Matrix dimensions %d %d uncompatiable, unable to multiply\n\n",matrixPair.colX, matrixPair.rowY);
		fclose(fp);
	} 
	//printf("Can multiplay matrices\n");
	int resultRow = matrixPair.rowX;
	int resultCol = matrixPair.colY;
	int N = matrixPair.colX;
	//used to define the totalCount of the matrixResult array size
	int totalCount = resultRow * resultCol;
	//creates and initialise matrixResult
	double** matrixResult = malloc(totalCount* sizeof(double*));
	for(int x = 0; x < resultRow; x++){
		matrixResult[x] = malloc(resultCol * sizeof(double*));		
	}
		
	#pragma omp parallel for collapse(3)
	for(int i = 0; i < resultRow; i++){
		for(int j = 0; j < resultRow; j++){
			for(int k = 0; k < N; k++){
				matrixResult[i][j] += matrixPair.matrix_X[i][k] * matrixPair.matrix_Y[k][j];
			}
		}
	}
	
	return matrixResult;

}


//this function is used to get the total amount of matrices in the file
int getTotalMatrixCount(char *filename){
	FILE *fp;
	fp = fopen(filename, "r");
	int matrixCount = 1;
	char currentLine;
	int row, col;
	char last;
    char current;
    
    //this counts the total amount of matrices in the file 
    do
    {
        current = fgetc(fp);
        if(current == '\n' && last == '\n'){
       		matrixCount++;
       		//printf("current = %d\n", matrixCount);
        }
        //set last to current before looping back over
        last = current; 
    } while( current != EOF );    
 
	fclose(fp);
	return matrixCount;
}


mPair* Matrixread(char *filename){

	FILE *fp;	
	char currentLine;
	double matrixValue = 0.0;
	
	//this creates 'count/2' amount of structs pairs 
	int count = getTotalMatrixCount(filename)/2;
	mPair *Matrix_Pairs = malloc(count* sizeof(mPair));
	int totalMatrixPairsAdded = 0;
	
	fp = fopen(filename, "r");
	int row, col, rowX, colX, rowY, colY;
	
	while(currentLine = fscanf(fp, "%d,%d", &rowX, &colX) != EOF){
		if(currentLine != '\n'){
		//printf("X dimensions rowX = %d colX = %d \n", rowX, colX);
		//sets up the X matrix into a 2d array
			double** matrix_X = malloc(rowX * sizeof(double*));

			//for loop used to malloc the second dimention of the array
			for(int x = 0; x < rowX; x++){
				matrix_X[x] = malloc(colX * sizeof(double*));		
				}			
			for(row = 0; row < rowX; row++){
				for(col = 0; col <colX - 1; col++){
					//used to populate the 2D array with rowX and colX
					fscanf(fp, "%lf,", &matrixValue);
					matrix_X[row][col] = matrixValue;
					//printf("matrix X [%d][%d] = %lf  \n", row, col, matrix_X[row][col]);	
				}
				//add the last element of the matrix as that does not contain a ','
				fscanf(fp, "%lf", &matrixValue);
				matrix_X[row][col] = matrixValue;
				//printf("matrix X [%d][%d] = %lf  \n", row, col, matrix_X[row][col]);	
			}

			//this set Matrix_X to the current index
			Matrix_Pairs[totalMatrixPairsAdded].matrix_X = matrix_X;
			Matrix_Pairs[totalMatrixPairsAdded].rowX = rowX;
			Matrix_Pairs[totalMatrixPairsAdded].colX= colX;
						
			//fscanf allows for the detection of int and ignores the \n char
			fscanf(fp, "%d,%d" , &rowY, &colY);
			//printf("Y dimensions rowY = %d colY = %d \n", rowY, colY);
			
			//sets up the Y matrix into a 2d array
			double** matrix_Y = malloc(rowY * sizeof(double*));
			for(int y = 0; y < rowY; y++){
				matrix_Y[y] = malloc(colY * sizeof(double*));
			}
			for(row = 0; row < rowY; row++){
				for(col = 0; col < colY - 1; col++){
					fscanf(fp, "%lf,", &matrixValue);
					matrix_Y[row][col] = matrixValue;
					//printf("matrix Y [%d][%d] = %f  \n", row, col, matrix_Y[row][col]);
				}
				fscanf(fp, "%lf", &matrixValue);
				matrix_Y[row][col] = matrixValue;
				//printf("matrix Y [%d][%d] = %f  \n", row, col, matrix_Y[row][col]);	
			}
			//this set to the current index
			Matrix_Pairs[totalMatrixPairsAdded].matrix_Y = matrix_Y;
			Matrix_Pairs[totalMatrixPairsAdded].rowY = rowY;
			Matrix_Pairs[totalMatrixPairsAdded].colY = colY;
			totalMatrixPairsAdded++;
		}
	}
	fclose(fp);	
	return Matrix_Pairs;
}

void matrixOutput(double** matrixValues, int rows, int cols){

	FILE *fp;
	fp = fopen("matrixresults1712403.txt","a");

	fprintf(fp, "%d,%d\n",rows, cols);
	for(int i = 0; i < rows; i++){
		for(int j = 0; j < cols; j++){
			if(j == rows-1){
				fprintf(fp, "%lf",matrixValues[i][j]);
			} else {
				fprintf(fp,"%lf,",matrixValues[i][j]);
			
			}
			
		}
		fprintf(fp,"\n");
	}
	fprintf(fp,"\n");
	fclose(fp);
}


void main(){
	
	int threadAmount;
	printf("How many threads would you like to run? (1-100)\n");
	scanf("%d", &threadAmount);
	if(threadAmount <= 100 && threadAmount > 0){
		//setting OMP the amount threads
		#pragma omp parallel num_threads(threadAmount);
	} else {
		printf("Please enter a thread amount in between 1 and 100\n");
		return;
	}

	remove("matrixresults1712403.txt");
	char * filename = "1712403-matrices.txt";
	mPair* AllMatrixPairs = Matrixread(filename);
	int totalMatrixCount = getTotalMatrixCount(filename)/2;
	
	for(int k = 0; k < totalMatrixCount; k++){
		double** matrixTotalResult = matrixMultiplaction(AllMatrixPairs[k], threadAmount);
		int rows = AllMatrixPairs[k].rowX;
		int cols = rows;
		matrixOutput(matrixTotalResult, rows, cols);
	}
	printf("Matrix calculation complete\n");
	printf("Text file '%s' created\n",filename);
}
