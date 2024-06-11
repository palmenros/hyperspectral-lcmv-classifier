//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: native_multi_target_detection_ldl_terminate.cu
//
// GPU Coder version                    : 24.1
// CUDA/C/C++ source code generated on  : 17-May-2024 07:49:02
//

// Include Files
#include "native_multi_target_detection_ldl_terminate.h"
#include "native_multi_target_detection_ldl_data.h"
#include "native_multi_target_detection_ldl_rtwutil.h"
#include "rt_nonfinite.h"
#include "MWCUBLASUtils.hpp"
#include "MWCUSOLVERUtils.hpp"
#include "MWMemoryManager.hpp"
#include "stdio.h"

// Function Definitions
//
// Arguments    : void
// Return Type  : void
//
void native_multi_target_detection_ldl_terminate()
{
  cudaError_t errCode;
  errCode = cudaGetLastError();
  if (errCode != cudaSuccess) {
    fprintf(stderr, "ERR[%d] %s:%s\n", errCode, cudaGetErrorName(errCode),
            cudaGetErrorString(errCode));
    exit(errCode);
  }
  cublasEnsureDestruction();
  cusolverDestroyWorkspace();
  cusolverEnsureDestruction();
  checkCudaError(mwMemoryManagerTerminate(), __FILE__, __LINE__);
  isInitialized_native_multi_target_detection_ldl = false;
}

//
// File trailer for native_multi_target_detection_ldl_terminate.cu
//
// [EOF]
//
