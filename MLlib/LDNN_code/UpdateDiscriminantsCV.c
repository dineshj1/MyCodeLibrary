
#include "mex.h"
#include "math.h"
#include "mat.h"

void shuffle(mwIndex *array, mwSize n)
{
    if (n > 1) 
    {
        mwIndex i;
        for (i = 0; i < n - 1; i++) 
        {
          mwIndex j = i + rand() / (RAND_MAX / (n - i) + 1);
          int t = array[j];
          array[j] = array[i];
          array[i] = t;
        }
    }
}

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
    
    mwSize maxepoch;
    double epsilon;
    double momentumweight;
    mwSize nGroup;
    mwSize nDiscriminantPerGroup;
    double *initial_discriminants;
    double *xtrain;
    double *ytrain;
    
    double *discriminants;
    double *totalerror;
    double *totalerrorvalid;
    double *n_epochs;
    mwSize tM, tN, dM, dN;
            
    mwIndex x, ii, i, j, k;    
    mwIndex *ptr_to_rnd;    

    /* cross validation variables */
    
    double *xvalid, *yvalid;   
    double *voutputs;
    double  vmul_d_pts, vAND_c_muls, voutput, verro, CV;
    mwSize vN;
    mxArray *discreserve, *discold;
    double *discreservep, *discoldp;
    double cv_count;
    double cv_flg;
    
    /* end of validation variables */    

    double *outputs, *outputsAND_c;
    double *outputsAND, *outputs_c, *term2;

    mxArray *prevupdates, *updates;
    double *prevupdates_p, *updates_p;
    
    double sum_d_pts, mul_d_pts, AND_c_muls, output, erro, mp;
    
    xtrain = mxGetPr(prhs[0]);
    ytrain = mxGetPr(prhs[1]);
    initial_discriminants = mxGetPr(prhs[2]);
    
    maxepoch = mxGetScalar(prhs[3]);
    nDiscriminantPerGroup = mxGetScalar(prhs[4]);
    nGroup = mxGetScalar(prhs[5]);
    epsilon = mxGetScalar(prhs[6]);
    momentumweight = mxGetScalar(prhs[7]);    
    
    dM = mxGetM(prhs[2]);
    dN = mxGetN(prhs[2]);
    
    tM = mxGetM(prhs[0]);
    tN = mxGetN(prhs[0]);
    
    plhs[0] = mxCreateDoubleMatrix(dM, dN, mxREAL);            
    plhs[1] = mxCreateDoubleMatrix(maxepoch, 1, mxREAL); 
    plhs[2] = mxCreateDoubleMatrix(maxepoch, 1, mxREAL);
    plhs[3] = mxCreateDoubleMatrix(1, 1, mxREAL);
    
    discriminants = mxGetPr(plhs[0]);
    totalerror = mxGetPr(plhs[1]);
    totalerrorvalid = mxGetPr(plhs[2]);
    n_epochs = mxGetPr(plhs[3]);
    *n_epochs = (double)maxepoch;
    
    /* cross validation initialization */

    xvalid = mxGetPr(prhs[8]);
    yvalid = mxGetPr(prhs[9]);
    
    vN = mxGetN(prhs[8]);
    
    voutputs = (double*)mxCalloc(dN,sizeof(double));
    
    CV = 0;
    discreserve = mxCreateDoubleMatrix(dM, dN, mxREAL);
    discold = mxCreateDoubleMatrix(dM, dN, mxREAL);
    
    discreservep = mxGetPr(discreserve);
    discoldp = mxGetPr(discold);

    cv_count = mxGetScalar(prhs[10]);
    cv_flg = mxGetScalar(prhs[11]);

    /* end of validation initialization */
    
    outputs = (double*)mxCalloc(dN,sizeof(double));
    term2 = (double*)mxCalloc(dN,sizeof(double));
    outputs_c = (double*)mxCalloc(dN,sizeof(double));
    outputsAND = (double*)mxCalloc(nGroup,sizeof(double));
    outputsAND_c = (double*)mxCalloc(nGroup,sizeof(double));
           
    prevupdates = mxCreateDoubleMatrix(dM, dN, mxREAL);
    updates = mxCreateDoubleMatrix(dM, dN, mxREAL);    
    
    prevupdates_p = mxGetPr(prevupdates);
    updates_p = mxGetPr(updates);
    
   
    /* MATFile *pmat;
    const char *file = "Outputs.mat";
    int s; */
    
    
    for (i=0;i<dM*dN;i++){
        discriminants[i] = initial_discriminants[i];
    } 
    
    ptr_to_rnd = (mwIndex*)mxCalloc(tN,sizeof(mwIndex));
    
    for (i=0; i<tN; ptr_to_rnd[i] = i++);
    
    for (x=0;x<maxepoch;x++){
        
/*    cross validation */
        if (cv_flg == 1){
            
            for (i=0; i<vN; i++){

                for (j=0; j<dN; j++){

                    sum_d_pts = 0;
                    for (k=0; k<dM; k++){
                        sum_d_pts = sum_d_pts + discriminants[j*dM+k]*xvalid[i*tM+k];                  
                    }
                    voutputs[j] = 1/(1+exp(-sum_d_pts));
                }            


                vAND_c_muls = 1;
                for (j=0; j<nGroup; j++){
                    vmul_d_pts = 1;
                    for (k=0; k<nDiscriminantPerGroup; k++){
                        vmul_d_pts = vmul_d_pts * voutputs[j*nDiscriminantPerGroup+k];
                    }
                    vAND_c_muls = vAND_c_muls * (1 - vmul_d_pts);
                }

                voutput = 1 - vAND_c_muls;
                verro = 0.1 + 0.8*yvalid[i] - voutput; 
                totalerrorvalid[x] = totalerrorvalid[x] + verro*verro;
            }
            totalerrorvalid[x] = sqrt(totalerrorvalid[x]/vN);
            
        }
 /* end of computing validation outputs  */
        
        shuffle(ptr_to_rnd, tN); 
        for (i=0; i<tN; i++){
            ii = ptr_to_rnd[i];
            
            for (j=0; j<dN; j++){

                sum_d_pts = 0;
                for (k=0; k<dM; k++){
                    sum_d_pts = sum_d_pts + discriminants[j*dM+k]*xtrain[ii*tM+k];                  
                }
                outputs[j] = 1/(1+exp(-sum_d_pts));
                outputs[j] = outputs[j] - DBL_EPSILON*(outputs[j]==1);
                outputs_c[j] = 1 - outputs[j];
            }
            
            AND_c_muls = 1;
            for (j=0; j<nGroup; j++){
                mul_d_pts = 1;
                for (k=0; k<nDiscriminantPerGroup; k++){
                    mul_d_pts = mul_d_pts * outputs[j*nDiscriminantPerGroup+k];
                }
                outputsAND[j] = mul_d_pts;
                outputsAND_c[j] = 1-mul_d_pts;
                AND_c_muls = AND_c_muls * outputsAND_c[j];
            }
            
            output = 1 - AND_c_muls;
            erro = 0.1 + 0.8*ytrain[ii] - output;                       
            totalerror[x] = totalerror[x] + erro*erro;                    
          
            for (j=0; j<nGroup; j++){
                    mp = ((AND_c_muls/outputsAND_c[j])*outputsAND[j])*erro;              
                for (k=0; k<nDiscriminantPerGroup; k++){
                    term2[j*nDiscriminantPerGroup+k] = mp * outputs_c[j*nDiscriminantPerGroup+k];
                }                
            }
            
            for (j=0; j<dN; j++){
                for (k=0; k<tM; k++){
                    updates_p[j*tM+k] = xtrain[ii*tM+k] * term2[j] + momentumweight * prevupdates_p[j*tM+k];
                    discriminants[j*tM+k] = discriminants[j*tM+k] + epsilon * updates_p[j*tM+k];
                    prevupdates_p[j*tM+k] = updates_p[j*tM+k];
                            
                }
            }
            
        }
        totalerror[x] = sqrt(totalerror[x]/tN);
        
        /* mexPrintf("Epoch No. %d ... error = %f \n",x+1,totalerror[x]); */
        
        if (cv_flg == 1){
                        
            /* mexPrintf("Epoch No. %d ... error = %f (validation set)\n",x+1,totalerrorvalid[x]); */
            if(x>0){
                if(totalerrorvalid[x] > totalerrorvalid[x-1]){
                    CV = CV + 1;
                    if (CV==1){
                        mxDestroyArray(discreserve);
                        discreserve = mxDuplicateArray(discold);
                        discreservep = mxGetPr(discreserve);
                    }
                    if (CV==cv_count){
                        mxDestroyArray(plhs[0]);
                        plhs[0] = mxDuplicateArray(discreserve);
                        discriminants = mxGetPr(plhs[0]);
                        *n_epochs = (double)x+1;
                        break;
                    }
                }
                else{
                    CV = 0;
                }
            } 
            mxDestroyArray(discold);
            discold = mxDuplicateArray(plhs[0]);
            discoldp = mxGetPr(discold);
        /*
         pmat = matOpen(file,"w");
            s = matPutVariable(pmat,"discriminants",plhs[0]);
            s = matPutVariable(pmat,"totalerror",plhs[1]);
            s = matPutVariable(pmat,"totalerrorvalid",plhs[2]);
            s = matClose(pmat); */
        }   
    }
    
    mxDestroyArray(discreserve);
    mxDestroyArray(discold);
    mxDestroyArray(prevupdates);
    mxDestroyArray(updates); 

}
