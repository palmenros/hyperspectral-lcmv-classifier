//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: native_multi_target_detection_ldl_rtwutil.cu
//
// GPU Coder version                    : 24.1
// CUDA/C/C++ source code generated on  : 17-May-2024 07:49:02
//

// Include Files
#include "native_multi_target_detection_ldl_rtwutil.h"
#include "rt_nonfinite.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"

// Function Definitions
//
// Arguments    : int errCode
//                const char *file
//                unsigned int b_line
//                const char *errorName
//                const char *errorString
// Return Type  : void
//
void b_raiseCudaError(int errCode, const char *file, unsigned int b_line,
                      const char *errorName, const char *errorString)
{
  printf("ERR[%d] %s:%s in file %s at line %d\nExiting program execution ...\n",
         errCode, errorName, errorString, file, b_line);
  exit(errCode);
}

//
// Arguments    : cudaError_t errCode
//                const char *file
//                unsigned int b_line
// Return Type  : void
//
void checkCudaError(cudaError_t errCode, const char *file, unsigned int b_line)
{
  if (errCode != cudaSuccess) {
    b_raiseCudaError(errCode, file, b_line, cudaGetErrorName(errCode),
                     cudaGetErrorString(errCode));
  }
}

//
// File trailer for native_multi_target_detection_ldl_rtwutil.cu
//
// [EOF]
//
