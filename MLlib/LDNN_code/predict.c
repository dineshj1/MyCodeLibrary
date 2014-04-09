
#include "mex.h"
#include "math.h"
#include "mat.h"

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{

    double *xtrain;
    double *discriminants;
    int nGroup;
    int nDiscriminantPerGroup;    

    mwSize tM, tN;
	int dM, dN;

    size_t i;
	int j,k;

    double sum_d_pts, AND_c_muls, mul_d_pts;
    double *outputs_p;
    double *output;
    
	xtrain = (double*)mxGetData(prhs[0]);
	discriminants = (double*)mxGetData(prhs[1]);
    
    nGroup = (int)mxGetScalar(prhs[2]);
    nDiscriminantPerGroup = (int)mxGetScalar(prhs[3]);
           
    dM = (int)mxGetM(prhs[1]);
    dN = (int)mxGetN(prhs[1]);

    tM = (mwSize)mxGetM(prhs[0]);
    tN = (mwSize)mxGetN(prhs[0]);
    
    plhs[0] = mxCreateDoubleMatrix(1, tN, mxREAL);            

    outputs_p = mxCalloc(dN,sizeof(double));
    output = mxGetPr(plhs[0]);

    for (i=0; i<tN; i++){

		for (j=0; j<dN; j++){
			sum_d_pts = 0;
			for (k=0; k<dM; k++){
				sum_d_pts = sum_d_pts + discriminants[j*dM+k]*xtrain[i*tM+k];
			}
			outputs_p[j] = 1/(1+exp(-sum_d_pts));
		}

		AND_c_muls = 1;
		for (j=0; j<nGroup; j++){
			mul_d_pts = 1;
			for (k=0; k<nDiscriminantPerGroup; k++){
				mul_d_pts = mul_d_pts * outputs_p[j*nDiscriminantPerGroup+k];
			}
			AND_c_muls = AND_c_muls * (1-mul_d_pts);
		}

		output[i] = 1 - AND_c_muls;
	}

}
