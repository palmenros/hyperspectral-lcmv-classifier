//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: native_multi_target_detection_ldl_initialize.cu
//
// GPU Coder version                    : 24.1
// CUDA/C/C++ source code generated on  : 17-May-2024 07:49:02
//

// Include Files
#include "native_multi_target_detection_ldl_initialize.h"
#include "native_multi_target_detection_ldl_data.h"
#include "rt_nonfinite.h"
#include "MWCUBLASUtils.hpp"
#include "MWCUSOLVERUtils.hpp"
#include "MWMemoryManager.hpp"

// Function Definitions
//
// Arguments    : void
// Return Type  : void
//
void native_multi_target_detection_ldl_initialize()
{
  cudaGetLastError();
  mwMemoryManagerInit(256U, 0U, 8U, 2048U);
  cublasEnsureInitialization(CUBLAS_POINTER_MODE_HOST);
  cusolverEnsureInitialization();
  isInitialized_native_multi_target_detection_ldl = true;
}

//
// File trailer for native_multi_target_detection_ldl_initialize.cu
//
// [EOF]
//
