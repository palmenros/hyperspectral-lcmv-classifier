//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: native_multi_target_detection_ldl_rtwutil.h
//
// GPU Coder version                    : 24.1
// CUDA/C/C++ source code generated on  : 17-May-2024 07:49:02
//

#ifndef NATIVE_MULTI_TARGET_DETECTION_LDL_RTWUTIL_H
#define NATIVE_MULTI_TARGET_DETECTION_LDL_RTWUTIL_H

// Include Files
#include "rtwtypes.h"
#include <cstddef>
#include <cstdlib>

// Function Declarations
extern void b_raiseCudaError(int errCode, const char *file, unsigned int b_line,
                             const char *errorName, const char *errorString);

extern void checkCudaError(cudaError_t errCode, const char *file,
                           unsigned int b_line);

#endif
//
// File trailer for native_multi_target_detection_ldl_rtwutil.h
//
// [EOF]
//
