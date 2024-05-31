//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: native_multi_target_detection_ldl.cu
//
// GPU Coder version                    : 24.1
// CUDA/C/C++ source code generated on  : 12-May-2024 11:24:45
//

// Include Files
#include "native_multi_target_detection_ldl.h"
#include "native_multi_target_detection_ldl_data.h"
#include "native_multi_target_detection_ldl_initialize.h"
#include "native_multi_target_detection_ldl_rtwutil.h"
#include "rt_nonfinite.h"
#include "MWCUBLASUtils.hpp"
#include "MWCUSOLVERUtils.hpp"
#include "MWCudaDimUtility.hpp"
#include "MWCudaMemoryFunctions.hpp"
#include "MWErrorCodeUtils.hpp"
#include "MWLaunchParametersUtilities.hpp"
#include "math_constants.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include <cmath>
#include <time.h>

// Function Declarations
static long computeEndIdx(long start, long end, long stride);

static
#ifdef __CUDACC__
    __device__
#endif
    long
    computeEndIdx_device(long start, long end, long stride);

static unsigned long computeNumIters(long ub);

static void cublasCheck(cublasStatus_t errCode, const char *file,
                        unsigned int b_line);

static void cusolverCheck(cusolverStatus_t errCode, const char *file,
                          unsigned int b_line);

static __global__ void
native_multi_target_detection_ldl_kernel1(const float X[692224],
                                          float a[692224]);

static __global__ void
native_multi_target_detection_ldl_kernel10(const float T[2535], float a[2535]);

static __global__ void native_multi_target_detection_ldl_kernel11(float D[225],
                                                                  float L[225]);

static __global__ void
native_multi_target_detection_ldl_kernel12(const float C[45], float W[45]);

static __global__ void
native_multi_target_detection_ldl_kernel13(const float L[225], float t2[225]);

static __global__ void native_multi_target_detection_ldl_kernel14(float W[45]);

static __global__ void native_multi_target_detection_ldl_kernel15(float W[45]);

static __global__ void
native_multi_target_detection_ldl_kernel16(const float L[225], float t2[225]);

static __global__ void native_multi_target_detection_ldl_kernel17(float W[45]);

static __global__ void
native_multi_target_detection_ldl_kernel18(const float d11, const int ix,
                                           const long b, float t2[225]);

static __global__ void native_multi_target_detection_ldl_kernel19(float L[225]);

static __global__ void
native_multi_target_detection_ldl_kernel2(float R[28561]);

static __global__ void native_multi_target_detection_ldl_kernel20(const int k,
                                                                  float L[225]);

static __global__ void native_multi_target_detection_ldl_kernel21(const int k,
                                                                  float L[225]);

static __global__ void
native_multi_target_detection_ldl_kernel22(const float t2[225], const int k,
                                           const long b, float L[225]);

static __global__ void native_multi_target_detection_ldl_kernel23(float D[225]);

static __global__ void
native_multi_target_detection_ldl_kernel24(const float d11, const int ix,
                                           const long b, float R[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel25(float L[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel26(const int k, float L[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel27(const int k, float L[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel28(const float R[28561], const int k,
                                           const long b, float L[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel29(float D[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel3(float D[28561], float L[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel4(const float T[2535], float W[2535]);

static __global__ void
native_multi_target_detection_ldl_kernel5(const float L[28561], float R[28561]);

static __global__ void native_multi_target_detection_ldl_kernel6(float W[2535]);

static __global__ void native_multi_target_detection_ldl_kernel7(float W[2535]);

static __global__ void
native_multi_target_detection_ldl_kernel8(const float L[28561], float R[28561]);

static __global__ void native_multi_target_detection_ldl_kernel9(float W[2535]);

static void raiseCudaError(int errCode, const char *file, unsigned int b_line,
                           const char *errorName, const char *errorString);

// Function Definitions
//
// Arguments    : long start
//                long end
//                long stride
// Return Type  : long
//
static long computeEndIdx(long start, long end, long stride)
{
  long newEnd;
  newEnd = -1L;
  if ((stride > 0L) && (start <= end)) {
    newEnd = (end - start) / stride;
  } else if ((stride < 0L) && (end <= start)) {
    newEnd = (start - end) / -stride;
  }
  return newEnd;
}

//
// Arguments    : long start
//                long end
//                long stride
// Return Type  : long
//
static __device__ long computeEndIdx_device(long start, long end, long stride)
{
  long newEnd;
  newEnd = -1L;
  if ((stride > 0L) && (start <= end)) {
    newEnd = (end - start) / stride;
  } else if ((stride < 0L) && (end <= start)) {
    newEnd = (start - end) / -stride;
  }
  return newEnd;
}

//
// Arguments    : long ub
// Return Type  : unsigned long
//
static unsigned long computeNumIters(long ub)
{
  unsigned long numIters;
  numIters = 0UL;
  if (ub >= 0L) {
    numIters = static_cast<unsigned long>(ub + 1L);
  }
  return numIters;
}

//
// Arguments    : cublasStatus_t errCode
//                const char *file
//                unsigned int b_line
// Return Type  : void
//
static void cublasCheck(cublasStatus_t errCode, const char *file,
                        unsigned int b_line)
{
  const char *errName;
  const char *errString;
  if (errCode != CUBLAS_STATUS_SUCCESS) {
    cublasGetErrorName(errCode, &errName);
    cublasGetErrorString(errCode, &errString);
    raiseCudaError(errCode, file, b_line, errName, errString);
  }
}

//
// Arguments    : cusolverStatus_t errCode
//                const char *file
//                unsigned int b_line
// Return Type  : void
//
static void cusolverCheck(cusolverStatus_t errCode, const char *file,
                          unsigned int b_line)
{
  const char *errName;
  const char *errString;
  if (errCode != CUSOLVER_STATUS_SUCCESS) {
    cusolverGetErrorName(errCode, &errName);
    cusolverGetErrorString(errCode, &errString);
    raiseCudaError(errCode, file, b_line, errName, errString);
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float X[692224]
//                float a[692224]
// Return Type  : void
//
static __global__
    __launch_bounds__(512, 1) void native_multi_target_detection_ldl_kernel1(
        const float X[692224], float a[692224])
{
  unsigned long gThreadId;
  int i;
  int jj;
  gThreadId = mwGetGlobalThreadIndex();
  jj = static_cast<int>(gThreadId % 169UL);
  i = static_cast<int>((gThreadId - static_cast<unsigned long>(jj)) / 169UL);
  if ((i < 4096) && (jj < 169)) {
    //  R = correlation_matrix(X);
    //  TIMING_0
    a[jj + 169 * i] = X[i + (jj << 12)];
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float T[2535]
//                float a[2535]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel10(const float T[2535],
                                                            float a[2535])
{
  unsigned long gThreadId;
  int i;
  int jj;
  gThreadId = mwGetGlobalThreadIndex();
  jj = static_cast<int>(gThreadId % 15UL);
  i = static_cast<int>((gThreadId - static_cast<unsigned long>(jj)) / 15UL);
  if ((i < 169) && (jj < 15)) {
    //  TIMING_3
    a[jj + 15 * i] = T[i + 169 * jj];
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float D[225]
//                float L[225]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel11(float D[225],
                                                            float L[225])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 225) {
    L[i] = CUDART_NAN_F;
    D[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float C[45]
//                float W[45]
// Return Type  : void
//
static __global__ __launch_bounds__(
    64, 1) void native_multi_target_detection_ldl_kernel12(const float C[45],
                                                           float W[45])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 45) {
    W[i] = C[i];
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float L[225]
//                float t2[225]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel13(const float L[225],
                                                            float t2[225])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 225) {
    t2[i] = L[i];
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float W[45]
// Return Type  : void
//
static __global__ __launch_bounds__(
    64, 1) void native_multi_target_detection_ldl_kernel14(float W[45])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 45) {
    W[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float W[45]
// Return Type  : void
//
static __global__ __launch_bounds__(
    64, 1) void native_multi_target_detection_ldl_kernel15(float W[45])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 45) {
    W[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float L[225]
//                float t2[225]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel16(const float L[225],
                                                            float t2[225])
{
  unsigned long gThreadId;
  int i;
  int jj;
  gThreadId = mwGetGlobalThreadIndex();
  jj = static_cast<int>(gThreadId % 15UL);
  i = static_cast<int>((gThreadId - static_cast<unsigned long>(jj)) / 15UL);
  if ((i < 15) && (jj < 15)) {
    t2[jj + 15 * i] = L[i + 15 * jj];
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float W[45]
// Return Type  : void
//
static __global__ __launch_bounds__(
    64, 1) void native_multi_target_detection_ldl_kernel17(float W[45])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 45) {
    W[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float d11
//                const int ix
//                const long b
//                float t2[225]
// Return Type  : void
//
static __global__
    __launch_bounds__(1024, 1) void native_multi_target_detection_ldl_kernel18(
        const float d11, const int ix, const long b, float t2[225])
{
  unsigned long gStride;
  unsigned long gThreadId;
  unsigned long loopEnd;
  gThreadId = mwGetGlobalThreadIndex();
  gStride = mwGetTotalThreadsLaunched();
  loopEnd = static_cast<unsigned long>(b);
  for (unsigned long idx{gThreadId}; idx <= loopEnd; idx += gStride) {
    long jj;
    jj = static_cast<long>(idx);
    t2[static_cast<int>(static_cast<long>(ix) + jj) - 1] *= d11;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float L[225]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel19(float L[225])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 225) {
    L[i] = 0.0F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float R[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    288, 1) void native_multi_target_detection_ldl_kernel2(float R[28561])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 28561) {
    //  TIMING_1
    R[i] /= 4096.0F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const int k
//                float L[225]
// Return Type  : void
//
static __global__ __launch_bounds__(
    32, 1) void native_multi_target_detection_ldl_kernel20(const int k,
                                                           float L[225])
{
  int tmpIdx;
  tmpIdx = static_cast<int>(mwGetGlobalThreadIndex());
  if (tmpIdx < 1) {
    L[(k + 15 * (k - 1)) - 1] = 1.0F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const int k
//                float L[225]
// Return Type  : void
//
static __global__ __launch_bounds__(
    32, 1) void native_multi_target_detection_ldl_kernel21(const int k,
                                                           float L[225])
{
  int tmpIdx;
  tmpIdx = static_cast<int>(mwGetGlobalThreadIndex());
  if (tmpIdx < 1) {
    L[k + 15 * k] = 1.0F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float t2[225]
//                const int k
//                const long b
//                float L[225]
// Return Type  : void
//
static __global__
    __launch_bounds__(1024, 1) void native_multi_target_detection_ldl_kernel22(
        const float t2[225], const int k, const long b, float L[225])
{
  unsigned long gStride;
  unsigned long gThreadId;
  unsigned long loopEnd;
  gThreadId = mwGetGlobalThreadIndex();
  gStride = mwGetTotalThreadsLaunched();
  loopEnd = static_cast<unsigned long>(b);
  for (unsigned long idx{gThreadId}; idx <= loopEnd; idx += gStride) {
    long b_jj;
    int i;
    int jj;
    b_jj = static_cast<long>(idx);
    jj = static_cast<int>(static_cast<long>(k) + b_jj);
    i = k + 2;
    for (b_jj = 0L; b_jj <= computeEndIdx_device(static_cast<long>(i), 15L, 1L);
         b_jj++) {
      L[(static_cast<int>(static_cast<long>(k + 2) + b_jj) + 15 * (jj - 1)) -
        1] = t2[(static_cast<int>(static_cast<long>(k + 2) + b_jj) +
                 15 * (jj - 1)) -
                1];
    }
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float D[225]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel23(float D[225])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 225) {
    D[i] = 0.0F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float d11
//                const int ix
//                const long b
//                float R[28561]
// Return Type  : void
//
static __global__
    __launch_bounds__(1024, 1) void native_multi_target_detection_ldl_kernel24(
        const float d11, const int ix, const long b, float R[28561])
{
  unsigned long gStride;
  unsigned long gThreadId;
  unsigned long loopEnd;
  gThreadId = mwGetGlobalThreadIndex();
  gStride = mwGetTotalThreadsLaunched();
  loopEnd = static_cast<unsigned long>(b);
  for (unsigned long idx{gThreadId}; idx <= loopEnd; idx += gStride) {
    long jj;
    jj = static_cast<long>(idx);
    R[static_cast<int>(static_cast<long>(ix) + jj) - 1] *= d11;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float L[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    288, 1) void native_multi_target_detection_ldl_kernel25(float L[28561])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 28561) {
    L[i] = 0.0F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const int k
//                float L[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    32, 1) void native_multi_target_detection_ldl_kernel26(const int k,
                                                           float L[28561])
{
  int tmpIdx;
  tmpIdx = static_cast<int>(mwGetGlobalThreadIndex());
  if (tmpIdx < 1) {
    L[(k + 169 * (k - 1)) - 1] = 1.0F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const int k
//                float L[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    32, 1) void native_multi_target_detection_ldl_kernel27(const int k,
                                                           float L[28561])
{
  int tmpIdx;
  tmpIdx = static_cast<int>(mwGetGlobalThreadIndex());
  if (tmpIdx < 1) {
    L[k + 169 * k] = 1.0F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float R[28561]
//                const int k
//                const long b
//                float L[28561]
// Return Type  : void
//
static __global__
    __launch_bounds__(1024, 1) void native_multi_target_detection_ldl_kernel28(
        const float R[28561], const int k, const long b, float L[28561])
{
  unsigned long gStride;
  unsigned long gThreadId;
  unsigned long loopEnd;
  gThreadId = mwGetGlobalThreadIndex();
  gStride = mwGetTotalThreadsLaunched();
  loopEnd = static_cast<unsigned long>(b);
  for (unsigned long idx{gThreadId}; idx <= loopEnd; idx += gStride) {
    long b_jj;
    int i;
    int jj;
    b_jj = static_cast<long>(idx);
    jj = static_cast<int>(static_cast<long>(k) + b_jj);
    i = k + 2;
    for (b_jj = 0L;
         b_jj <= computeEndIdx_device(static_cast<long>(i), 169L, 1L); b_jj++) {
      L[(static_cast<int>(static_cast<long>(k + 2) + b_jj) + 169 * (jj - 1)) -
        1] = R[(static_cast<int>(static_cast<long>(k + 2) + b_jj) +
                169 * (jj - 1)) -
               1];
    }
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float D[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    288, 1) void native_multi_target_detection_ldl_kernel29(float D[28561])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 28561) {
    D[i] = 0.0F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float D[28561]
//                float L[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    288, 1) void native_multi_target_detection_ldl_kernel3(float D[28561],
                                                           float L[28561])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 28561) {
    L[i] = CUDART_NAN_F;
    D[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float T[2535]
//                float W[2535]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel4(const float T[2535],
                                                           float W[2535])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 2535) {
    W[i] = T[i];
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float L[28561]
//                float R[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    288, 1) void native_multi_target_detection_ldl_kernel5(const float L[28561],
                                                           float R[28561])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 28561) {
    R[i] = L[i];
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float W[2535]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel6(float W[2535])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 2535) {
    W[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float W[2535]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel7(float W[2535])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 2535) {
    W[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float L[28561]
//                float R[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    288, 1) void native_multi_target_detection_ldl_kernel8(const float L[28561],
                                                           float R[28561])
{
  unsigned long gThreadId;
  int i;
  int jj;
  gThreadId = mwGetGlobalThreadIndex();
  jj = static_cast<int>(gThreadId % 169UL);
  i = static_cast<int>((gThreadId - static_cast<unsigned long>(jj)) / 169UL);
  if ((i < 169) && (jj < 169)) {
    R[jj + 169 * i] = L[i + 169 * jj];
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float W[2535]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel9(float W[2535])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 2535) {
    W[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : int errCode
//                const char *file
//                unsigned int b_line
//                const char *errorName
//                const char *errorString
// Return Type  : void
//
static void raiseCudaError(int errCode, const char *file, unsigned int b_line,
                           const char *errorName, const char *errorString)
{
  printf("ERR[%d] %s:%s in file %s at line %d\nExiting program execution ...\n",
         errCode, errorName, errorString, file, b_line);
  exit(errCode);
}

//
// Arguments    : const float cpu_T[2535]
//                const float cpu_C[45]
//                const float cpu_X[692224]
//                float cpu_W[507]
// Return Type  : void
//
void native_multi_target_detection_ldl(const float cpu_T[2535],
                                       const float cpu_C[45],
                                       const float cpu_X[692224],
                                       float cpu_W[507])
{
  static float cpu_L[28561];
  static float cpu_R[28561];
  dim3 block;
  dim3 grid;
  long b;
  long c;
  float(*gpu_X)[692224];
  float(*gpu_a)[692224];
  float cpu_D[28561];
  float(*gpu_D)[28561];
  float(*gpu_L)[28561];
  float(*gpu_R)[28561];
  float(*b_gpu_a)[2535];
  float(*gpu_T)[2535];
  float(*gpu_W)[2535];
  float(*c_gpu_W)[507];
  float b_cpu_D[225];
  float b_cpu_L[225];
  float cpu_t2[225];
  float(*b_gpu_D)[225];
  float(*b_gpu_L)[225];
  float(*gpu_t2)[225];
  float(*b_gpu_W)[45];
  float(*gpu_C)[45];
  float colmax;
  float d11;
  float s;
  float smax;
  float temp;
  float wkp1;
  int(*gpu_IPIV)[169];
  int(*b_gpu_IPIV)[15];
  int b_cpu_info;
  int b_p;
  int c_cpu_info;
  int cpu_info;
  int cpu_iy;
  int d_cpu_info;
  int e_cpu_info;
  int exitg1;
  int f_cpu_info;
  int imax;
  int ix;
  int jmax;
  int k;
  int kstep;
  int n;
  int *b_gpu_info;
  int *c_gpu_info;
  int *d_gpu_info;
  int *e_gpu_info;
  int *f_gpu_info;
  int *gpu_info;
  int *gpu_iy;
  bool L_outdatedOnCpu;
  bool L_outdatedOnGpu;
  bool R_outdatedOnCpu;
  bool R_outdatedOnGpu;
  bool p;
  bool validLaunchParams;
  clock_t start, end;
  start = clock();


  if (!isInitialized_native_multi_target_detection_ldl) {
    native_multi_target_detection_ldl_initialize();
  }
  end = clock();
  cudaDeviceSynchronize();
  printf("Initialize: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();

  checkCudaError(mwCudaMalloc(&f_gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&e_gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&d_gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_IPIV, 60UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_W, 180UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_D, 900UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_L, 900UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_t2, 900UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_a, 10140UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&c_gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_iy, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_IPIV, 676UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_W, 10140UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_D, 114244UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_L, 114244UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_R, 114244UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_a, 2768896UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&c_gpu_W, 2028UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_X, 2768896UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_C, 180UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_T, 10140UL), __FILE__, __LINE__);
  //  R = correlation_matrix(X);
  end = clock();
  cudaDeviceSynchronize();
  printf("Allocate: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();


  checkCudaError(cudaMemcpy(*gpu_X, cpu_X, 2768896UL, cudaMemcpyHostToDevice),
                 __FILE__, __LINE__);

  end = clock();
  cudaDeviceSynchronize();
  printf("Copy: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();

  //  TIMING_0
  native_multi_target_detection_ldl_kernel1<<<dim3(1352U, 1U, 1U),
                                              dim3(512U, 1U, 1U)>>>(*gpu_X,
                                                                    *gpu_a);
  temp = 1.0F;
  smax = 0.0F;
  cublasCheck(cublasSgemm(getCublasGlobalHandle(), CUBLAS_OP_N, CUBLAS_OP_N,
                          169, 169, 4096, (float *)&temp, (float *)&(*gpu_a)[0],
                          169, (float *)&(*gpu_X)[0], 4096, (float *)&smax,
                          (float *)&(*gpu_R)[0], 169),
              __FILE__, __LINE__);
  //  TIMING_1

  end = clock();
  cudaDeviceSynchronize();
  printf("Correlation matrix (0): %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();


  native_multi_target_detection_ldl_kernel2<<<dim3(100U, 1U, 1U),
                                              dim3(288U, 1U, 1U)>>>(*gpu_R);
  R_outdatedOnGpu = false;
  R_outdatedOnCpu = true;
  //  TIMING_2

  end = clock();
  cudaDeviceSynchronize();
  printf("Correlation matrix (1): %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();



  //  Alternative: t1 = R \ T;
  p = true;
  for (k = 0; k < 28561; k++) {
    if (p) {
      if (R_outdatedOnCpu) {
        checkCudaError(
            cudaMemcpy(cpu_R, *gpu_R, 114244UL, cudaMemcpyDeviceToHost),
            __FILE__, __LINE__);
      }
      R_outdatedOnCpu = false;
      temp = cpu_R[k];
      if (std::isinf(temp) || std::isnan(temp)) {
        p = false;
      }
    } else {
      p = false;
    }
  }
  if (!p) {
    native_multi_target_detection_ldl_kernel3<<<dim3(100U, 1U, 1U),
                                                dim3(288U, 1U, 1U)>>>(*gpu_D,
                                                                      *gpu_L);
    L_outdatedOnGpu = false;
    R_outdatedOnGpu = false;
  } else {
    int ipiv[169];
    for (k = 0; k + 1 <= 169; k += kstep) {
      kstep = 1;
      b_p = k;
      if (R_outdatedOnCpu) {
        checkCudaError(
            cudaMemcpy(cpu_R, *gpu_R, 114244UL, cudaMemcpyDeviceToHost),
            __FILE__, __LINE__);
      }
      R_outdatedOnCpu = false;
      temp = std::abs(cpu_R[k + 169 * k]);
      if (k + 1 < 169) {
        cpu_iy = (k * 169 + k) + 1;
        n = 166 - k;
        ix = 1;
        if (168 - k > 1) {
          smax = std::abs(cpu_R[cpu_iy]);
          for (int b_k{0}; b_k <= n; b_k++) {
            s = std::abs(cpu_R[(cpu_iy + b_k) + 1]);
            if (s > smax) {
              ix = b_k + 2;
              smax = s;
            }
          }
        }
        imax = k + ix;
        colmax = std::abs(cpu_R[imax + 169 * k]);
      } else {
        imax = 168;
        colmax = 0.0F;
      }
      if (std::fmax(temp, colmax) == 0.0F) {
        imax = k;
        ipiv[k] = imax + 1;
      } else {
        if (!(temp < 0.640388191F * colmax)) {
          imax = k;
        } else {
          do {
            exitg1 = 0;
            if (imax + 1 != k + 1) {
              cpu_iy = k * 169 + imax;
              n = imax - k;
              if (n < 1) {
                ix = 0;
              } else {
                ix = 1;
                if (n > 1) {
                  smax = std::abs(cpu_R[cpu_iy]);
                  for (int b_k{0}; b_k <= n - 2; b_k++) {
                    s = std::abs(cpu_R[cpu_iy + (b_k + 1) * 169]);
                    if (s > smax) {
                      ix = b_k + 2;
                      smax = s;
                    }
                  }
                }
              }
              jmax = k + ix;
              temp = std::abs(cpu_R[imax + 169 * (jmax - 1)]);
            } else {
              temp = 0.0F;
              jmax = k;
            }
            if (imax + 1 < 169) {
              cpu_iy = (imax * 169 + imax) + 1;
              n = 166 - imax;
              ix = 2;
              if (168 - imax > 1) {
                smax = std::abs(cpu_R[cpu_iy]);
                for (int b_k{0}; b_k <= n; b_k++) {
                  s = std::abs(cpu_R[(cpu_iy + b_k) + 1]);
                  if (s > smax) {
                    ix = b_k + 3;
                    smax = s;
                  }
                }
              }
              cpu_iy = imax + ix;
              smax = std::abs(cpu_R[(cpu_iy + 169 * imax) - 1]);
              if (smax > temp) {
                temp = smax;
                jmax = cpu_iy;
              }
            }
            if (!(std::abs(cpu_R[imax + 169 * imax]) < 0.640388191F * temp)) {
              exitg1 = 1;
            } else if ((b_p + 1 == jmax) || (temp <= colmax)) {
              kstep = 2;
              exitg1 = 1;
            } else {
              b_p = imax;
              colmax = temp;
              imax = jmax - 1;
            }
          } while (exitg1 == 0);
        }
        jmax = (k + kstep) - 1;
        if ((kstep == 2) && (b_p + 1 != k + 1)) {
          if (b_p + 1 < 169) {
            ix = (k * 169 + b_p) + 1;
            cpu_iy = (b_p * 169 + b_p) + 1;
            n = 167 - b_p;
            for (int b_k{0}; b_k <= n; b_k++) {
              temp = cpu_R[ix + b_k];
              cpu_R[ix + b_k] = cpu_R[cpu_iy + b_k];
              cpu_R[cpu_iy + b_k] = temp;
            }
          }
          b = computeEndIdx(static_cast<long>(k + 2), static_cast<long>(b_p),
                            1L);
          for (long ii{0L}; ii <= b; ii++) {
            temp = cpu_R[(static_cast<int>((k + 2) + ii) + 169 * k) - 1];
            cpu_R[(static_cast<int>((k + 2) + ii) + 169 * k) - 1] =
                cpu_R[b_p + 169 * (static_cast<int>((k + 2) + ii) - 1)];
            cpu_R[b_p + 169 * (static_cast<int>((k + 2) + ii) - 1)] = temp;
          }
          temp = cpu_R[k + 169 * k];
          cpu_R[k + 169 * k] = cpu_R[b_p + 169 * b_p];
          cpu_R[b_p + 169 * b_p] = temp;
          R_outdatedOnGpu = true;
        }
        if (imax + 1 != jmax + 1) {
          if (imax + 1 < 169) {
            ix = (jmax * 169 + imax) + 1;
            cpu_iy = (imax * 169 + imax) + 1;
            n = 167 - imax;
            for (int b_k{0}; b_k <= n; b_k++) {
              temp = cpu_R[ix + b_k];
              cpu_R[ix + b_k] = cpu_R[cpu_iy + b_k];
              cpu_R[cpu_iy + b_k] = temp;
            }
          }
          b = computeEndIdx(static_cast<long>(jmax + 2),
                            static_cast<long>(imax), 1L);
          for (long ii{0L}; ii <= b; ii++) {
            temp = cpu_R[(static_cast<int>((jmax + 2) + ii) + 169 * jmax) - 1];
            cpu_R[(static_cast<int>((jmax + 2) + ii) + 169 * jmax) - 1] =
                cpu_R[imax + 169 * (static_cast<int>((jmax + 2) + ii) - 1)];
            cpu_R[imax + 169 * (static_cast<int>((jmax + 2) + ii) - 1)] = temp;
          }
          temp = cpu_R[jmax + 169 * jmax];
          cpu_R[jmax + 169 * jmax] = cpu_R[imax + 169 * imax];
          cpu_R[imax + 169 * imax] = temp;
          R_outdatedOnGpu = true;
          if (kstep == 2) {
            temp = cpu_R[(k + 169 * k) + 1];
            cpu_R[(k + 169 * k) + 1] = cpu_R[imax + 169 * k];
            cpu_R[imax + 169 * k] = temp;
          }
        }
        if (kstep == 1) {
          if (k + 1 < 169) {
            if (std::abs(cpu_R[k + 169 * k]) >= 9.09494702E-13F) {
              d11 = 1.0F / cpu_R[k + 169 * k];
              b = computeEndIdx(static_cast<long>(k + 2), 169L, 1L);
              for (long ii{0L}; ii <= b; ii++) {
                if (cpu_R[(static_cast<int>((k + 2) + ii) + 169 * k) - 1] !=
                    0.0F) {
                  temp = -d11 *
                         cpu_R[(static_cast<int>((k + 2) + ii) + 169 * k) - 1];
                  cpu_R[(static_cast<int>((k + 2) + ii) +
                         169 * (static_cast<int>((k + 2) + ii) - 1)) -
                        1] +=
                      temp *
                      cpu_R[(static_cast<int>((k + 2) + ii) + 169 * k) - 1];
                  R_outdatedOnGpu = true;
                  ix = static_cast<int>((k + 2) + ii) + 1;
                  c = computeEndIdx(static_cast<long>(ix), 169L, 1L);
                  for (long i{0L}; i <= c; i++) {
                    cpu_R[(static_cast<int>(ix + i) +
                           169 * (static_cast<int>((k + 2) + ii) - 1)) -
                          1] +=
                        cpu_R[(static_cast<int>(ix + i) + 169 * k) - 1] * temp;
                  }
                }
              }
              cpu_iy = k * 169 + k;
              b = computeEndIdx(static_cast<long>(cpu_iy + 2),
                                static_cast<long>((cpu_iy - k) + 169), 1L);
              mwGetLaunchParameters1D(computeNumIters(b), &grid, &block,
                                      2147483647U);
              if (R_outdatedOnGpu) {
                checkCudaError(
                    cudaMemcpy(*gpu_R, cpu_R, 114244UL, cudaMemcpyHostToDevice),
                    __FILE__, __LINE__);
              }
              validLaunchParams = mwValidateLaunchParameters(grid, block);
              if (validLaunchParams) {
                native_multi_target_detection_ldl_kernel24<<<grid, block>>>(
                    d11, cpu_iy + 2, b, *gpu_R);
              }
              R_outdatedOnGpu = false;
              R_outdatedOnCpu = true;
            } else {
              d11 = cpu_R[k + 169 * k];
              b = computeEndIdx(static_cast<long>(k + 2), 169L, 1L);
              for (long ii{0L}; ii <= b; ii++) {
                cpu_R[(static_cast<int>((k + 2) + ii) + 169 * k) - 1] /= d11;
                R_outdatedOnGpu = true;
              }
              b = computeEndIdx(static_cast<long>(k + 2), 169L, 1L);
              for (long ii{0L}; ii <= b; ii++) {
                if (cpu_R[(static_cast<int>((k + 2) + ii) + 169 * k) - 1] !=
                    0.0F) {
                  temp = -d11 *
                         cpu_R[(static_cast<int>((k + 2) + ii) + 169 * k) - 1];
                  cpu_R[(static_cast<int>((k + 2) + ii) +
                         169 * (static_cast<int>((k + 2) + ii) - 1)) -
                        1] +=
                      temp *
                      cpu_R[(static_cast<int>((k + 2) + ii) + 169 * k) - 1];
                  R_outdatedOnGpu = true;
                  ix = static_cast<int>((k + 2) + ii) + 1;
                  c = computeEndIdx(static_cast<long>(ix), 169L, 1L);
                  for (long i{0L}; i <= c; i++) {
                    cpu_R[(static_cast<int>(ix + i) +
                           169 * (static_cast<int>((k + 2) + ii) - 1)) -
                          1] +=
                        cpu_R[(static_cast<int>(ix + i) + 169 * k) - 1] * temp;
                  }
                }
              }
            }
          }
          ipiv[k] = imax + 1;
        } else {
          if (k + 1 < 168) {
            temp = cpu_R[(k + 169 * k) + 1];
            d11 = cpu_R[(k + 169 * (k + 1)) + 1] / cpu_R[(k + 169 * k) + 1];
            smax = cpu_R[k + 169 * k] / cpu_R[(k + 169 * k) + 1];
            s = 1.0F / (d11 * smax - 1.0F);
            b = computeEndIdx(static_cast<long>(k + 3), 169L, 1L);
            for (long ii{0L}; ii <= b; ii++) {
              colmax =
                  s *
                  (d11 * cpu_R[(static_cast<int>((k + 3) + ii) + 169 * k) - 1] -
                   cpu_R[(static_cast<int>((k + 3) + ii) + 169 * (k + 1)) - 1]);
              wkp1 =
                  s *
                  (smax *
                       cpu_R[(static_cast<int>((k + 3) + ii) + 169 * (k + 1)) -
                             1] -
                   cpu_R[(static_cast<int>((k + 3) + ii) + 169 * k) - 1]);
              c = computeEndIdx(
                  static_cast<long>(static_cast<int>((k + 3) + ii)), 169L, 1L);
              for (long i{0L}; i <= c; i++) {
                cpu_R[(static_cast<int>(static_cast<int>((k + 3) + ii) + i) +
                       169 * (static_cast<int>((k + 3) + ii) - 1)) -
                      1] =
                    (cpu_R[(static_cast<int>(static_cast<int>((k + 3) + ii) +
                                             i) +
                            169 * (static_cast<int>((k + 3) + ii) - 1)) -
                           1] -
                     cpu_R[(static_cast<int>(static_cast<int>((k + 3) + ii) +
                                             i) +
                            169 * k) -
                           1] /
                         temp * colmax) -
                    cpu_R[(static_cast<int>(static_cast<int>((k + 3) + ii) +
                                            i) +
                           169 * (k + 1)) -
                          1] /
                        temp * wkp1;
              }
              cpu_R[(static_cast<int>((k + 3) + ii) + 169 * k) - 1] =
                  colmax / temp;
              cpu_R[(static_cast<int>((k + 3) + ii) + 169 * (k + 1)) - 1] =
                  wkp1 / temp;
              R_outdatedOnGpu = true;
            }
          }
          ipiv[k] = -b_p - 1;
          ipiv[k + 1] = -imax - 1;
        }
      }
    }
    native_multi_target_detection_ldl_kernel25<<<dim3(100U, 1U, 1U),
                                                 dim3(288U, 1U, 1U)>>>(*gpu_L);
    L_outdatedOnGpu = false;
    L_outdatedOnCpu = true;
    k = 1;
    while (k <= 169) {
      if (L_outdatedOnGpu) {
        checkCudaError(
            cudaMemcpy(*gpu_L, cpu_L, 114244UL, cudaMemcpyHostToDevice),
            __FILE__, __LINE__);
      }
      native_multi_target_detection_ldl_kernel26<<<dim3(1U, 1U, 1U),
                                                   dim3(32U, 1U, 1U)>>>(k,
                                                                        *gpu_L);
      L_outdatedOnGpu = false;
      L_outdatedOnCpu = true;
      if (ipiv[k - 1] > 0) {
        b = computeEndIdx(static_cast<long>(k + 1), 169L, 1L);
        for (long ii{0L}; ii <= b; ii++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(cpu_L, *gpu_L, 114244UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          if (R_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(cpu_R, *gpu_R, 114244UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          R_outdatedOnCpu = false;
          cpu_L[(static_cast<int>((k + 1) + ii) + 169 * (k - 1)) - 1] =
              cpu_R[(static_cast<int>((k + 1) + ii) + 169 * (k - 1)) - 1];
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k++;
      } else {
        native_multi_target_detection_ldl_kernel27<<<dim3(1U, 1U, 1U),
                                                     dim3(32U, 1U, 1U)>>>(
            k, *gpu_L);
        b = computeEndIdx(static_cast<long>(k), static_cast<long>(k + 1), 1L);
        mwGetLaunchParameters1D(computeNumIters(b), &grid, &block, 2147483647U);
        if (R_outdatedOnGpu) {
          checkCudaError(
              cudaMemcpy(*gpu_R, cpu_R, 114244UL, cudaMemcpyHostToDevice),
              __FILE__, __LINE__);
        }
        R_outdatedOnGpu = false;
        validLaunchParams = mwValidateLaunchParameters(grid, block);
        if (validLaunchParams) {
          native_multi_target_detection_ldl_kernel28<<<grid, block>>>(
              *gpu_R, k, b, *gpu_L);
        }
        k += 2;
      }
    }
    if (ipiv[0] > 0) {
      k = 1;
    } else {
      k = 2;
    }
    while (k + 1 < 169) {
      if (ipiv[k] > 0) {
        cpu_iy = ipiv[k] - 1;
        for (int b_k{0}; b_k < k; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(cpu_L, *gpu_L, 114244UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = cpu_L[k + b_k * 169];
          cpu_L[k + b_k * 169] = cpu_L[cpu_iy + b_k * 169];
          cpu_L[cpu_iy + b_k * 169] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k++;
      } else {
        cpu_iy = -ipiv[k] - 1;
        for (int b_k{0}; b_k < k; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(cpu_L, *gpu_L, 114244UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = cpu_L[k + b_k * 169];
          cpu_L[k + b_k * 169] = cpu_L[cpu_iy + b_k * 169];
          cpu_L[cpu_iy + b_k * 169] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        cpu_iy = -ipiv[k + 1] - 1;
        for (int b_k{0}; b_k < k; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(cpu_L, *gpu_L, 114244UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = cpu_L[(k + b_k * 169) + 1];
          cpu_L[(k + b_k * 169) + 1] = cpu_L[cpu_iy + b_k * 169];
          cpu_L[cpu_iy + b_k * 169] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k += 2;
      }
    }
    native_multi_target_detection_ldl_kernel29<<<dim3(100U, 1U, 1U),
                                                 dim3(288U, 1U, 1U)>>>(*gpu_D);
    R_outdatedOnGpu = false;
    p = true;
    k = 0;
    while (k + 1 <= 169) {
      if (ipiv[k] > 0) {
        if (p) {
          checkCudaError(
              cudaMemcpy(cpu_D, *gpu_D, 114244UL, cudaMemcpyDeviceToHost),
              __FILE__, __LINE__);
        }
        if (R_outdatedOnCpu) {
          checkCudaError(
              cudaMemcpy(cpu_R, *gpu_R, 114244UL, cudaMemcpyDeviceToHost),
              __FILE__, __LINE__);
        }
        R_outdatedOnCpu = false;
        cpu_D[k + 169 * k] = cpu_R[k + 169 * k];
        p = false;
        R_outdatedOnGpu = true;
        k++;
      } else {
        if (p) {
          checkCudaError(
              cudaMemcpy(cpu_D, *gpu_D, 114244UL, cudaMemcpyDeviceToHost),
              __FILE__, __LINE__);
        }
        if (R_outdatedOnCpu) {
          checkCudaError(
              cudaMemcpy(cpu_R, *gpu_R, 114244UL, cudaMemcpyDeviceToHost),
              __FILE__, __LINE__);
        }
        cpu_D[k + 169 * k] = cpu_R[k + 169 * k];
        cpu_D[(k + 169 * (k + 1)) + 1] = cpu_R[(k + 169 * (k + 1)) + 1];
        R_outdatedOnCpu = false;
        cpu_D[(k + 169 * k) + 1] = cpu_R[(k + 169 * k) + 1];
        cpu_D[k + 169 * (k + 1)] = cpu_D[(k + 169 * k) + 1];
        p = false;
        R_outdatedOnGpu = true;
        k += 2;
      }
    }
    k = 168;
    while (k + 1 >= 1) {
      if (ipiv[k] > 0) {
        cpu_iy = ipiv[k] - 1;
        for (int b_k{0}; b_k < 169; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(cpu_L, *gpu_L, 114244UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = cpu_L[k + b_k * 169];
          cpu_L[k + b_k * 169] = cpu_L[cpu_iy + b_k * 169];
          cpu_L[cpu_iy + b_k * 169] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k--;
      } else {
        cpu_iy = -ipiv[k] - 1;
        for (int b_k{0}; b_k < 169; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(cpu_L, *gpu_L, 114244UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = cpu_L[k + b_k * 169];
          cpu_L[k + b_k * 169] = cpu_L[cpu_iy + b_k * 169];
          cpu_L[cpu_iy + b_k * 169] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        cpu_iy = -ipiv[k - 1] - 1;
        for (int b_k{0}; b_k < 169; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(cpu_L, *gpu_L, 114244UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = cpu_L[(k + b_k * 169) - 1];
          cpu_L[(k + b_k * 169) - 1] = cpu_L[cpu_iy + b_k * 169];
          cpu_L[cpu_iy + b_k * 169] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k -= 2;
      }
    }
  }
  checkCudaError(cudaMemcpy(*gpu_T, cpu_T, 10140UL, cudaMemcpyHostToDevice),
                 __FILE__, __LINE__);
  native_multi_target_detection_ldl_kernel4<<<dim3(20U, 1U, 1U),
                                              dim3(128U, 1U, 1U)>>>(*gpu_T,
                                                                    *gpu_W);
  if (L_outdatedOnGpu) {
    checkCudaError(cudaMemcpy(*gpu_L, cpu_L, 114244UL, cudaMemcpyHostToDevice),
                   __FILE__, __LINE__);
  }
  native_multi_target_detection_ldl_kernel5<<<dim3(100U, 1U, 1U),
                                              dim3(288U, 1U, 1U)>>>(*gpu_L,
                                                                    *gpu_R);
  cusolverCheck(cusolverDnSgetrf_bufferSize(getCuSolverGlobalHandle(), 169, 169,
                                            (float *)&(*gpu_R)[0], 169,
                                            getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(cusolverDnSgetrf(
                    getCuSolverGlobalHandle(), 169, 169, (float *)&(*gpu_R)[0],
                    169, static_cast<float *>(getCuSolverWorkspaceBuff()),
                    &(*gpu_IPIV)[0], gpu_info),
                __FILE__, __LINE__);
  checkCudaError(cudaMemcpy(&cpu_info, gpu_info, 4UL, cudaMemcpyDeviceToHost),
                 __FILE__, __LINE__);
  if (cpu_info < 0) {
    native_multi_target_detection_ldl_kernel6<<<dim3(20U, 1U, 1U),
                                                dim3(128U, 1U, 1U)>>>(*gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 169,
                                   15, (float *)&(*gpu_R)[0], 169,
                                   &(*gpu_IPIV)[0], (float *)&(*gpu_W)[0], 169,
                                   gpu_iy),
                  __FILE__, __LINE__);
  }
  if (R_outdatedOnGpu) {
    checkCudaError(cudaMemcpy(*gpu_D, cpu_D, 114244UL, cudaMemcpyHostToDevice),
                   __FILE__, __LINE__);
  }
  cusolverCheck(cusolverDnSgetrf_bufferSize(getCuSolverGlobalHandle(), 169, 169,
                                            (float *)&(*gpu_D)[0], 169,
                                            getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(cusolverDnSgetrf(
                    getCuSolverGlobalHandle(), 169, 169, (float *)&(*gpu_D)[0],
                    169, static_cast<float *>(getCuSolverWorkspaceBuff()),
                    &(*gpu_IPIV)[0], b_gpu_info),
                __FILE__, __LINE__);
  checkCudaError(
      cudaMemcpy(&b_cpu_info, b_gpu_info, 4UL, cudaMemcpyDeviceToHost),
      __FILE__, __LINE__);
  if (b_cpu_info < 0) {
    native_multi_target_detection_ldl_kernel7<<<dim3(20U, 1U, 1U),
                                                dim3(128U, 1U, 1U)>>>(*gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 169,
                                   15, (float *)&(*gpu_D)[0], 169,
                                   &(*gpu_IPIV)[0], (float *)&(*gpu_W)[0], 169,
                                   gpu_iy),
                  __FILE__, __LINE__);
  }
  native_multi_target_detection_ldl_kernel8<<<dim3(100U, 1U, 1U),
                                              dim3(288U, 1U, 1U)>>>(*gpu_L,
                                                                    *gpu_R);
  cusolverCheck(cusolverDnSgetrf_bufferSize(getCuSolverGlobalHandle(), 169, 169,
                                            (float *)&(*gpu_R)[0], 169,
                                            getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(cusolverDnSgetrf(
                    getCuSolverGlobalHandle(), 169, 169, (float *)&(*gpu_R)[0],
                    169, static_cast<float *>(getCuSolverWorkspaceBuff()),
                    &(*gpu_IPIV)[0], c_gpu_info),
                __FILE__, __LINE__);
  checkCudaError(
      cudaMemcpy(&c_cpu_info, c_gpu_info, 4UL, cudaMemcpyDeviceToHost),
      __FILE__, __LINE__);
  if (c_cpu_info < 0) {
    native_multi_target_detection_ldl_kernel9<<<dim3(20U, 1U, 1U),
                                                dim3(128U, 1U, 1U)>>>(*gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 169,
                                   15, (float *)&(*gpu_R)[0], 169,
                                   &(*gpu_IPIV)[0], (float *)&(*gpu_W)[0], 169,
                                   gpu_iy),
                  __FILE__, __LINE__);
  }
  //  TIMING_3

  end = clock();
  cudaDeviceSynchronize();
  printf("LDL 1: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();


  native_multi_target_detection_ldl_kernel10<<<dim3(20U, 1U, 1U),
                                               dim3(128U, 1U, 1U)>>>(*gpu_T,
                                                                     *b_gpu_a);
  temp = 1.0F;
  smax = 0.0F;
  cublasCheck(cublasSgemm(getCublasGlobalHandle(), CUBLAS_OP_N, CUBLAS_OP_N, 15,
                          15, 169, (float *)&temp, (float *)&(*b_gpu_a)[0], 15,
                          (float *)&(*gpu_W)[0], 169, (float *)&smax,
                          (float *)&(*gpu_t2)[0], 15),
              __FILE__, __LINE__);
  R_outdatedOnGpu = false;
  R_outdatedOnCpu = true;
  //  TIMING_4

  end = clock();
  cudaDeviceSynchronize();
  printf("MUL 1: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();

  //  Alternative: t3 = t2 \ C;
  p = true;
  for (k = 0; k < 225; k++) {
    if (p) {
      if (R_outdatedOnCpu) {
        checkCudaError(
            cudaMemcpy(cpu_t2, *gpu_t2, 900UL, cudaMemcpyDeviceToHost),
            __FILE__, __LINE__);
      }
      R_outdatedOnCpu = false;
      temp = cpu_t2[k];
      if (std::isinf(temp) || std::isnan(temp)) {
        p = false;
      }
    } else {
      p = false;
    }
  }
  if (!p) {
    native_multi_target_detection_ldl_kernel11<<<dim3(2U, 1U, 1U),
                                                 dim3(128U, 1U, 1U)>>>(
        *b_gpu_D, *b_gpu_L);
    L_outdatedOnGpu = false;
    R_outdatedOnGpu = false;
  } else {
    int b_ipiv[15];
    for (k = 0; k + 1 <= 15; k += kstep) {
      kstep = 1;
      b_p = k;
      if (R_outdatedOnCpu) {
        checkCudaError(
            cudaMemcpy(cpu_t2, *gpu_t2, 900UL, cudaMemcpyDeviceToHost),
            __FILE__, __LINE__);
      }
      R_outdatedOnCpu = false;
      temp = std::abs(cpu_t2[k + 15 * k]);
      if (k + 1 < 15) {
        cpu_iy = (k * 15 + k) + 1;
        n = 12 - k;
        ix = 1;
        if (14 - k > 1) {
          smax = std::abs(cpu_t2[cpu_iy]);
          for (int b_k{0}; b_k <= n; b_k++) {
            s = std::abs(cpu_t2[(cpu_iy + b_k) + 1]);
            if (s > smax) {
              ix = b_k + 2;
              smax = s;
            }
          }
        }
        imax = k + ix;
        colmax = std::abs(cpu_t2[imax + 15 * k]);
      } else {
        imax = 14;
        colmax = 0.0F;
      }
      if (std::fmax(temp, colmax) == 0.0F) {
        imax = k;
        b_ipiv[k] = imax + 1;
      } else {
        if (!(temp < 0.640388191F * colmax)) {
          imax = k;
        } else {
          do {
            exitg1 = 0;
            if (imax + 1 != k + 1) {
              cpu_iy = k * 15 + imax;
              n = imax - k;
              if (n < 1) {
                ix = 0;
              } else {
                ix = 1;
                if (n > 1) {
                  smax = std::abs(cpu_t2[cpu_iy]);
                  for (int b_k{0}; b_k <= n - 2; b_k++) {
                    s = std::abs(cpu_t2[cpu_iy + (b_k + 1) * 15]);
                    if (s > smax) {
                      ix = b_k + 2;
                      smax = s;
                    }
                  }
                }
              }
              jmax = k + ix;
              temp = std::abs(cpu_t2[imax + 15 * (jmax - 1)]);
            } else {
              temp = 0.0F;
              jmax = k;
            }
            if (imax + 1 < 15) {
              cpu_iy = (imax * 15 + imax) + 1;
              n = 12 - imax;
              ix = 2;
              if (14 - imax > 1) {
                smax = std::abs(cpu_t2[cpu_iy]);
                for (int b_k{0}; b_k <= n; b_k++) {
                  s = std::abs(cpu_t2[(cpu_iy + b_k) + 1]);
                  if (s > smax) {
                    ix = b_k + 3;
                    smax = s;
                  }
                }
              }
              cpu_iy = imax + ix;
              smax = std::abs(cpu_t2[(cpu_iy + 15 * imax) - 1]);
              if (smax > temp) {
                temp = smax;
                jmax = cpu_iy;
              }
            }
            if (!(std::abs(cpu_t2[imax + 15 * imax]) < 0.640388191F * temp)) {
              exitg1 = 1;
            } else if ((b_p + 1 == jmax) || (temp <= colmax)) {
              kstep = 2;
              exitg1 = 1;
            } else {
              b_p = imax;
              colmax = temp;
              imax = jmax - 1;
            }
          } while (exitg1 == 0);
        }
        jmax = (k + kstep) - 1;
        if ((kstep == 2) && (b_p + 1 != k + 1)) {
          if (b_p + 1 < 15) {
            ix = (k * 15 + b_p) + 1;
            cpu_iy = (b_p * 15 + b_p) + 1;
            n = 13 - b_p;
            for (int b_k{0}; b_k <= n; b_k++) {
              temp = cpu_t2[ix + b_k];
              cpu_t2[ix + b_k] = cpu_t2[cpu_iy + b_k];
              cpu_t2[cpu_iy + b_k] = temp;
            }
          }
          b = computeEndIdx(static_cast<long>(k + 2), static_cast<long>(b_p),
                            1L);
          for (long ii{0L}; ii <= b; ii++) {
            temp = cpu_t2[(static_cast<int>((k + 2) + ii) + 15 * k) - 1];
            cpu_t2[(static_cast<int>((k + 2) + ii) + 15 * k) - 1] =
                cpu_t2[b_p + 15 * (static_cast<int>((k + 2) + ii) - 1)];
            cpu_t2[b_p + 15 * (static_cast<int>((k + 2) + ii) - 1)] = temp;
          }
          temp = cpu_t2[k + 15 * k];
          cpu_t2[k + 15 * k] = cpu_t2[b_p + 15 * b_p];
          cpu_t2[b_p + 15 * b_p] = temp;
          R_outdatedOnGpu = true;
        }
        if (imax + 1 != jmax + 1) {
          if (imax + 1 < 15) {
            ix = (jmax * 15 + imax) + 1;
            cpu_iy = (imax * 15 + imax) + 1;
            n = 13 - imax;
            for (int b_k{0}; b_k <= n; b_k++) {
              temp = cpu_t2[ix + b_k];
              cpu_t2[ix + b_k] = cpu_t2[cpu_iy + b_k];
              cpu_t2[cpu_iy + b_k] = temp;
            }
          }
          b = computeEndIdx(static_cast<long>(jmax + 2),
                            static_cast<long>(imax), 1L);
          for (long ii{0L}; ii <= b; ii++) {
            temp = cpu_t2[(static_cast<int>((jmax + 2) + ii) + 15 * jmax) - 1];
            cpu_t2[(static_cast<int>((jmax + 2) + ii) + 15 * jmax) - 1] =
                cpu_t2[imax + 15 * (static_cast<int>((jmax + 2) + ii) - 1)];
            cpu_t2[imax + 15 * (static_cast<int>((jmax + 2) + ii) - 1)] = temp;
          }
          temp = cpu_t2[jmax + 15 * jmax];
          cpu_t2[jmax + 15 * jmax] = cpu_t2[imax + 15 * imax];
          cpu_t2[imax + 15 * imax] = temp;
          R_outdatedOnGpu = true;
          if (kstep == 2) {
            temp = cpu_t2[(k + 15 * k) + 1];
            cpu_t2[(k + 15 * k) + 1] = cpu_t2[imax + 15 * k];
            cpu_t2[imax + 15 * k] = temp;
          }
        }
        if (kstep == 1) {
          if (k + 1 < 15) {
            if (std::abs(cpu_t2[k + 15 * k]) >= 9.09494702E-13F) {
              d11 = 1.0F / cpu_t2[k + 15 * k];
              b = computeEndIdx(static_cast<long>(k + 2), 15L, 1L);
              for (long ii{0L}; ii <= b; ii++) {
                if (cpu_t2[(static_cast<int>((k + 2) + ii) + 15 * k) - 1] !=
                    0.0F) {
                  temp = -d11 *
                         cpu_t2[(static_cast<int>((k + 2) + ii) + 15 * k) - 1];
                  cpu_t2[(static_cast<int>((k + 2) + ii) +
                          15 * (static_cast<int>((k + 2) + ii) - 1)) -
                         1] +=
                      temp *
                      cpu_t2[(static_cast<int>((k + 2) + ii) + 15 * k) - 1];
                  R_outdatedOnGpu = true;
                  ix = static_cast<int>((k + 2) + ii) + 1;
                  c = computeEndIdx(static_cast<long>(ix), 15L, 1L);
                  for (long i{0L}; i <= c; i++) {
                    cpu_t2[(static_cast<int>(ix + i) +
                            15 * (static_cast<int>((k + 2) + ii) - 1)) -
                           1] +=
                        cpu_t2[(static_cast<int>(ix + i) + 15 * k) - 1] * temp;
                  }
                }
              }
              cpu_iy = k * 15 + k;
              b = computeEndIdx(static_cast<long>(cpu_iy + 2),
                                static_cast<long>((cpu_iy - k) + 15), 1L);
              mwGetLaunchParameters1D(computeNumIters(b), &grid, &block,
                                      2147483647U);
              if (R_outdatedOnGpu) {
                checkCudaError(
                    cudaMemcpy(*gpu_t2, cpu_t2, 900UL, cudaMemcpyHostToDevice),
                    __FILE__, __LINE__);
              }
              validLaunchParams = mwValidateLaunchParameters(grid, block);
              if (validLaunchParams) {
                native_multi_target_detection_ldl_kernel18<<<grid, block>>>(
                    d11, cpu_iy + 2, b, *gpu_t2);
              }
              R_outdatedOnGpu = false;
              R_outdatedOnCpu = true;
            } else {
              d11 = cpu_t2[k + 15 * k];
              b = computeEndIdx(static_cast<long>(k + 2), 15L, 1L);
              for (long ii{0L}; ii <= b; ii++) {
                cpu_t2[(static_cast<int>((k + 2) + ii) + 15 * k) - 1] /= d11;
                R_outdatedOnGpu = true;
              }
              b = computeEndIdx(static_cast<long>(k + 2), 15L, 1L);
              for (long ii{0L}; ii <= b; ii++) {
                if (cpu_t2[(static_cast<int>((k + 2) + ii) + 15 * k) - 1] !=
                    0.0F) {
                  temp = -d11 *
                         cpu_t2[(static_cast<int>((k + 2) + ii) + 15 * k) - 1];
                  cpu_t2[(static_cast<int>((k + 2) + ii) +
                          15 * (static_cast<int>((k + 2) + ii) - 1)) -
                         1] +=
                      temp *
                      cpu_t2[(static_cast<int>((k + 2) + ii) + 15 * k) - 1];
                  R_outdatedOnGpu = true;
                  ix = static_cast<int>((k + 2) + ii) + 1;
                  c = computeEndIdx(static_cast<long>(ix), 15L, 1L);
                  for (long i{0L}; i <= c; i++) {
                    cpu_t2[(static_cast<int>(ix + i) +
                            15 * (static_cast<int>((k + 2) + ii) - 1)) -
                           1] +=
                        cpu_t2[(static_cast<int>(ix + i) + 15 * k) - 1] * temp;
                  }
                }
              }
            }
          }
          b_ipiv[k] = imax + 1;
        } else {
          if (k + 1 < 14) {
            temp = cpu_t2[(k + 15 * k) + 1];
            d11 = cpu_t2[(k + 15 * (k + 1)) + 1] / cpu_t2[(k + 15 * k) + 1];
            smax = cpu_t2[k + 15 * k] / cpu_t2[(k + 15 * k) + 1];
            s = 1.0F / (d11 * smax - 1.0F);
            b = computeEndIdx(static_cast<long>(k + 3), 15L, 1L);
            for (long ii{0L}; ii <= b; ii++) {
              colmax =
                  s *
                  (d11 * cpu_t2[(static_cast<int>((k + 3) + ii) + 15 * k) - 1] -
                   cpu_t2[(static_cast<int>((k + 3) + ii) + 15 * (k + 1)) - 1]);
              wkp1 =
                  s *
                  (smax *
                       cpu_t2[(static_cast<int>((k + 3) + ii) + 15 * (k + 1)) -
                              1] -
                   cpu_t2[(static_cast<int>((k + 3) + ii) + 15 * k) - 1]);
              c = computeEndIdx(
                  static_cast<long>(static_cast<int>((k + 3) + ii)), 15L, 1L);
              for (long i{0L}; i <= c; i++) {
                cpu_t2[(static_cast<int>(static_cast<int>((k + 3) + ii) + i) +
                        15 * (static_cast<int>((k + 3) + ii) - 1)) -
                       1] =
                    (cpu_t2[(static_cast<int>(static_cast<int>((k + 3) + ii) +
                                              i) +
                             15 * (static_cast<int>((k + 3) + ii) - 1)) -
                            1] -
                     cpu_t2[(static_cast<int>(static_cast<int>((k + 3) + ii) +
                                              i) +
                             15 * k) -
                            1] /
                         temp * colmax) -
                    cpu_t2[(static_cast<int>(static_cast<int>((k + 3) + ii) +
                                             i) +
                            15 * (k + 1)) -
                           1] /
                        temp * wkp1;
              }
              cpu_t2[(static_cast<int>((k + 3) + ii) + 15 * k) - 1] =
                  colmax / temp;
              cpu_t2[(static_cast<int>((k + 3) + ii) + 15 * (k + 1)) - 1] =
                  wkp1 / temp;
              R_outdatedOnGpu = true;
            }
          }
          b_ipiv[k] = -b_p - 1;
          b_ipiv[k + 1] = -imax - 1;
        }
      }
    }
    native_multi_target_detection_ldl_kernel19<<<dim3(2U, 1U, 1U),
                                                 dim3(128U, 1U, 1U)>>>(
        *b_gpu_L);
    L_outdatedOnGpu = false;
    L_outdatedOnCpu = true;
    k = 1;
    while (k <= 15) {
      if (L_outdatedOnGpu) {
        checkCudaError(
            cudaMemcpy(*b_gpu_L, b_cpu_L, 900UL, cudaMemcpyHostToDevice),
            __FILE__, __LINE__);
      }
      native_multi_target_detection_ldl_kernel20<<<dim3(1U, 1U, 1U),
                                                   dim3(32U, 1U, 1U)>>>(
          k, *b_gpu_L);
      L_outdatedOnGpu = false;
      L_outdatedOnCpu = true;
      if (b_ipiv[k - 1] > 0) {
        b = computeEndIdx(static_cast<long>(k + 1), 15L, 1L);
        for (long ii{0L}; ii <= b; ii++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(b_cpu_L, *b_gpu_L, 900UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          if (R_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(cpu_t2, *gpu_t2, 900UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          R_outdatedOnCpu = false;
          b_cpu_L[(static_cast<int>((k + 1) + ii) + 15 * (k - 1)) - 1] =
              cpu_t2[(static_cast<int>((k + 1) + ii) + 15 * (k - 1)) - 1];
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k++;
      } else {
        native_multi_target_detection_ldl_kernel21<<<dim3(1U, 1U, 1U),
                                                     dim3(32U, 1U, 1U)>>>(
            k, *b_gpu_L);
        b = computeEndIdx(static_cast<long>(k), static_cast<long>(k + 1), 1L);
        mwGetLaunchParameters1D(computeNumIters(b), &grid, &block, 2147483647U);
        if (R_outdatedOnGpu) {
          checkCudaError(
              cudaMemcpy(*gpu_t2, cpu_t2, 900UL, cudaMemcpyHostToDevice),
              __FILE__, __LINE__);
        }
        R_outdatedOnGpu = false;
        validLaunchParams = mwValidateLaunchParameters(grid, block);
        if (validLaunchParams) {
          native_multi_target_detection_ldl_kernel22<<<grid, block>>>(
              *gpu_t2, k, b, *b_gpu_L);
        }
        k += 2;
      }
    }
    if (b_ipiv[0] > 0) {
      k = 1;
    } else {
      k = 2;
    }
    while (k + 1 < 15) {
      if (b_ipiv[k] > 0) {
        cpu_iy = b_ipiv[k] - 1;
        for (int b_k{0}; b_k < k; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(b_cpu_L, *b_gpu_L, 900UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = b_cpu_L[k + b_k * 15];
          b_cpu_L[k + b_k * 15] = b_cpu_L[cpu_iy + b_k * 15];
          b_cpu_L[cpu_iy + b_k * 15] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k++;
      } else {
        cpu_iy = -b_ipiv[k] - 1;
        for (int b_k{0}; b_k < k; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(b_cpu_L, *b_gpu_L, 900UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = b_cpu_L[k + b_k * 15];
          b_cpu_L[k + b_k * 15] = b_cpu_L[cpu_iy + b_k * 15];
          b_cpu_L[cpu_iy + b_k * 15] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        cpu_iy = -b_ipiv[k + 1] - 1;
        for (int b_k{0}; b_k < k; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(b_cpu_L, *b_gpu_L, 900UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = b_cpu_L[(k + b_k * 15) + 1];
          b_cpu_L[(k + b_k * 15) + 1] = b_cpu_L[cpu_iy + b_k * 15];
          b_cpu_L[cpu_iy + b_k * 15] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k += 2;
      }
    }
    native_multi_target_detection_ldl_kernel23<<<dim3(2U, 1U, 1U),
                                                 dim3(128U, 1U, 1U)>>>(
        *b_gpu_D);
    R_outdatedOnGpu = false;
    p = true;
    k = 0;
    while (k + 1 <= 15) {
      if (b_ipiv[k] > 0) {
        if (p) {
          checkCudaError(
              cudaMemcpy(b_cpu_D, *b_gpu_D, 900UL, cudaMemcpyDeviceToHost),
              __FILE__, __LINE__);
        }
        if (R_outdatedOnCpu) {
          checkCudaError(
              cudaMemcpy(cpu_t2, *gpu_t2, 900UL, cudaMemcpyDeviceToHost),
              __FILE__, __LINE__);
        }
        R_outdatedOnCpu = false;
        b_cpu_D[k + 15 * k] = cpu_t2[k + 15 * k];
        p = false;
        R_outdatedOnGpu = true;
        k++;
      } else {
        if (p) {
          checkCudaError(
              cudaMemcpy(b_cpu_D, *b_gpu_D, 900UL, cudaMemcpyDeviceToHost),
              __FILE__, __LINE__);
        }
        if (R_outdatedOnCpu) {
          checkCudaError(
              cudaMemcpy(cpu_t2, *gpu_t2, 900UL, cudaMemcpyDeviceToHost),
              __FILE__, __LINE__);
        }
        b_cpu_D[k + 15 * k] = cpu_t2[k + 15 * k];
        b_cpu_D[(k + 15 * (k + 1)) + 1] = cpu_t2[(k + 15 * (k + 1)) + 1];
        R_outdatedOnCpu = false;
        b_cpu_D[(k + 15 * k) + 1] = cpu_t2[(k + 15 * k) + 1];
        b_cpu_D[k + 15 * (k + 1)] = b_cpu_D[(k + 15 * k) + 1];
        p = false;
        R_outdatedOnGpu = true;
        k += 2;
      }
    }
    k = 14;
    while (k + 1 >= 1) {
      if (b_ipiv[k] > 0) {
        cpu_iy = b_ipiv[k] - 1;
        for (int b_k{0}; b_k < 15; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(b_cpu_L, *b_gpu_L, 900UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = b_cpu_L[k + b_k * 15];
          b_cpu_L[k + b_k * 15] = b_cpu_L[cpu_iy + b_k * 15];
          b_cpu_L[cpu_iy + b_k * 15] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k--;
      } else {
        cpu_iy = -b_ipiv[k] - 1;
        for (int b_k{0}; b_k < 15; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(b_cpu_L, *b_gpu_L, 900UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = b_cpu_L[k + b_k * 15];
          b_cpu_L[k + b_k * 15] = b_cpu_L[cpu_iy + b_k * 15];
          b_cpu_L[cpu_iy + b_k * 15] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        cpu_iy = -b_ipiv[k - 1] - 1;
        for (int b_k{0}; b_k < 15; b_k++) {
          if (L_outdatedOnCpu) {
            checkCudaError(
                cudaMemcpy(b_cpu_L, *b_gpu_L, 900UL, cudaMemcpyDeviceToHost),
                __FILE__, __LINE__);
          }
          temp = b_cpu_L[(k + b_k * 15) - 1];
          b_cpu_L[(k + b_k * 15) - 1] = b_cpu_L[cpu_iy + b_k * 15];
          b_cpu_L[cpu_iy + b_k * 15] = temp;
          L_outdatedOnCpu = false;
          L_outdatedOnGpu = true;
        }
        k -= 2;
      }
    }
  }
  checkCudaError(cudaMemcpy(*gpu_C, cpu_C, 180UL, cudaMemcpyHostToDevice),
                 __FILE__, __LINE__);
  native_multi_target_detection_ldl_kernel12<<<dim3(1U, 1U, 1U),
                                               dim3(64U, 1U, 1U)>>>(*gpu_C,
                                                                    *b_gpu_W);
  if (L_outdatedOnGpu) {
    checkCudaError(cudaMemcpy(*b_gpu_L, b_cpu_L, 900UL, cudaMemcpyHostToDevice),
                   __FILE__, __LINE__);
  }
  native_multi_target_detection_ldl_kernel13<<<dim3(2U, 1U, 1U),
                                               dim3(128U, 1U, 1U)>>>(*b_gpu_L,
                                                                     *gpu_t2);
  cusolverCheck(cusolverDnSgetrf_bufferSize(getCuSolverGlobalHandle(), 15, 15,
                                            (float *)&(*gpu_t2)[0], 15,
                                            getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(cusolverDnSgetrf(
                    getCuSolverGlobalHandle(), 15, 15, (float *)&(*gpu_t2)[0],
                    15, static_cast<float *>(getCuSolverWorkspaceBuff()),
                    &(*b_gpu_IPIV)[0], d_gpu_info),
                __FILE__, __LINE__);
  checkCudaError(
      cudaMemcpy(&d_cpu_info, d_gpu_info, 4UL, cudaMemcpyDeviceToHost),
      __FILE__, __LINE__);
  if (d_cpu_info < 0) {
    native_multi_target_detection_ldl_kernel14<<<dim3(1U, 1U, 1U),
                                                 dim3(64U, 1U, 1U)>>>(*b_gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 15,
                                   3, (float *)&(*gpu_t2)[0], 15,
                                   &(*b_gpu_IPIV)[0], (float *)&(*b_gpu_W)[0],
                                   15, gpu_iy),
                  __FILE__, __LINE__);
  }
  if (R_outdatedOnGpu) {
    checkCudaError(cudaMemcpy(*b_gpu_D, b_cpu_D, 900UL, cudaMemcpyHostToDevice),
                   __FILE__, __LINE__);
  }
  cusolverCheck(cusolverDnSgetrf_bufferSize(getCuSolverGlobalHandle(), 15, 15,
                                            (float *)&(*b_gpu_D)[0], 15,
                                            getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(cusolverDnSgetrf(
                    getCuSolverGlobalHandle(), 15, 15, (float *)&(*b_gpu_D)[0],
                    15, static_cast<float *>(getCuSolverWorkspaceBuff()),
                    &(*b_gpu_IPIV)[0], e_gpu_info),
                __FILE__, __LINE__);
  checkCudaError(
      cudaMemcpy(&e_cpu_info, e_gpu_info, 4UL, cudaMemcpyDeviceToHost),
      __FILE__, __LINE__);
  if (e_cpu_info < 0) {
    native_multi_target_detection_ldl_kernel15<<<dim3(1U, 1U, 1U),
                                                 dim3(64U, 1U, 1U)>>>(*b_gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 15,
                                   3, (float *)&(*b_gpu_D)[0], 15,
                                   &(*b_gpu_IPIV)[0], (float *)&(*b_gpu_W)[0],
                                   15, gpu_iy),
                  __FILE__, __LINE__);
  }
  native_multi_target_detection_ldl_kernel16<<<dim3(2U, 1U, 1U),
                                               dim3(128U, 1U, 1U)>>>(*b_gpu_L,
                                                                     *gpu_t2);
  cusolverCheck(cusolverDnSgetrf_bufferSize(getCuSolverGlobalHandle(), 15, 15,
                                            (float *)&(*gpu_t2)[0], 15,
                                            getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(cusolverDnSgetrf(
                    getCuSolverGlobalHandle(), 15, 15, (float *)&(*gpu_t2)[0],
                    15, static_cast<float *>(getCuSolverWorkspaceBuff()),
                    &(*b_gpu_IPIV)[0], f_gpu_info),
                __FILE__, __LINE__);
  checkCudaError(
      cudaMemcpy(&f_cpu_info, f_gpu_info, 4UL, cudaMemcpyDeviceToHost),
      __FILE__, __LINE__);
  if (f_cpu_info < 0) {
    native_multi_target_detection_ldl_kernel17<<<dim3(1U, 1U, 1U),
                                                 dim3(64U, 1U, 1U)>>>(*b_gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 15,
                                   3, (float *)&(*gpu_t2)[0], 15,
                                   &(*b_gpu_IPIV)[0], (float *)&(*b_gpu_W)[0],
                                   15, gpu_iy),
                  __FILE__, __LINE__);
  }
  //  TIMING_5

  end = clock();
  cudaDeviceSynchronize();
  printf("LDL 2: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();


  //  Compute the weighting matrix W
  temp = 1.0F;
  smax = 0.0F;
  cublasCheck(cublasSgemm(getCublasGlobalHandle(), CUBLAS_OP_N, CUBLAS_OP_N,
                          169, 3, 15, (float *)&temp, (float *)&(*gpu_W)[0],
                          169, (float *)&(*b_gpu_W)[0], 15, (float *)&smax,
                          (float *)&(*c_gpu_W)[0], 169),
              __FILE__, __LINE__);
  //  TIMING_6

  end = clock();
  cudaDeviceSynchronize();
  printf("MUL 2: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();

  checkCudaError(cudaMemcpy(cpu_W, *c_gpu_W, 2028UL, cudaMemcpyDeviceToHost),
                 __FILE__, __LINE__);

  end = clock();
  cudaDeviceSynchronize();
  printf("Copy back: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();


  checkCudaError(mwCudaFree(*gpu_T), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_C), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_X), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*c_gpu_W), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_a), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_R), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_L), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_D), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_W), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_IPIV), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(gpu_iy), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(gpu_info), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(b_gpu_info), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(c_gpu_info), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*b_gpu_a), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_t2), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*b_gpu_L), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*b_gpu_D), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*b_gpu_W), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*b_gpu_IPIV), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(d_gpu_info), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(e_gpu_info), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(f_gpu_info), __FILE__, __LINE__);

  end = clock();
  cudaDeviceSynchronize();
  printf("Free: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();

}

//
// File trailer for native_multi_target_detection_ldl.cu
//
// [EOF]
//
