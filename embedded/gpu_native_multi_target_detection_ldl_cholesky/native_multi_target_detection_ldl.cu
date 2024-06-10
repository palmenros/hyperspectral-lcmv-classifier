//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: native_multi_target_detection_ldl.cu
//
// GPU Coder version                    : 24.1
// CUDA/C/C++ source code generated on  : 17-May-2024 07:49:02
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
#include <time.h>

// Function Declarations
static
#ifdef __CUDACC__
    __device__
#endif
    long
    computeEndIdx_device(long start, long end, long stride);

static unsigned long computeNumIters(int ub);

static void cublasCheck(cublasStatus_t errCode, const char *file,
                        unsigned int b_line);

static void cusolverCheck(cusolverStatus_t errCode, const char *file,
                          unsigned int b_line);

static __global__ void
native_multi_target_detection_ldl_kernel1(const float X[692224],
                                          float a[692224]);

static __global__ void
native_multi_target_detection_ldl_kernel10(float t2[225]);

static __global__ void
native_multi_target_detection_ldl_kernel11(const int info_t, const int b,
                                           float t2[225]);

static __global__ void
native_multi_target_detection_ldl_kernel12(const float t2[225], float A[225]);

static __global__ void
native_multi_target_detection_ldl_kernel13(const float C[45], float W[45]);

static __global__ void native_multi_target_detection_ldl_kernel14(float W[45]);

static __global__ void native_multi_target_detection_ldl_kernel15(float W[45]);

static __global__ void
native_multi_target_detection_ldl_kernel2(float R[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel3(float R[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel4(const int info_t, const int b,
                                          float R[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel5(const float R[28561], float A[28561]);

static __global__ void
native_multi_target_detection_ldl_kernel6(const float T[2535], float W[2535]);

static __global__ void native_multi_target_detection_ldl_kernel7(float W[2535]);

static __global__ void native_multi_target_detection_ldl_kernel8(float W[2535]);

static __global__ void
native_multi_target_detection_ldl_kernel9(const float T[2535], float a[2535]);

static void raiseCudaError(int errCode, const char *file, unsigned int b_line,
                           const char *errorName, const char *errorString);

// Function Definitions
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
// Arguments    : int ub
// Return Type  : unsigned long
//
static unsigned long computeNumIters(int ub)
{
  unsigned long numIters;
  numIters = 0UL;
  if (ub >= 0) {
    numIters = static_cast<unsigned long>(ub + 1);
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
  int j;
  gThreadId = mwGetGlobalThreadIndex();
  j = static_cast<int>(gThreadId % 169UL);
  i = static_cast<int>((gThreadId - static_cast<unsigned long>(j)) / 169UL);
  if ((i < 4096) && (j < 169)) {
    //  R = correlation_matrix(X);
    //  TIMING_0
    a[j + 169 * i] = X[i + (j << 12)];
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                float t2[225]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel10(float t2[225])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 225) {
    t2[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const int info_t
//                const int b
//                float t2[225]
// Return Type  : void
//
static __global__
    __launch_bounds__(1024, 1) void native_multi_target_detection_ldl_kernel11(
        const int info_t, const int b, float t2[225])
{
  unsigned long gStride;
  unsigned long gThreadId;
  unsigned long loopEnd;
  gThreadId = mwGetGlobalThreadIndex();
  gStride = mwGetTotalThreadsLaunched();
  loopEnd = static_cast<unsigned long>(b);
  for (unsigned long idx{gThreadId}; idx <= loopEnd; idx += gStride) {
    int i;
    int j;
    j = static_cast<int>(idx);
    i = j + 2;
    for (long b_i{0L};
         b_i <= computeEndIdx_device(static_cast<long>(i),
                                     static_cast<long>(info_t), 1L);
         b_i++) {
      t2[(static_cast<int>(static_cast<long>(j + 2) + b_i) + 15 * j) - 1] =
          0.0F;
    }
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float t2[225]
//                float A[225]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel12(const float t2[225],
                                                            float A[225])
{
  unsigned long gThreadId;
  int i;
  int j;
  gThreadId = mwGetGlobalThreadIndex();
  j = static_cast<int>(gThreadId % 15UL);
  i = static_cast<int>((gThreadId - static_cast<unsigned long>(j)) / 15UL);
  if ((i < 15) && (j < 15)) {
    A[j + 15 * i] = t2[i + 15 * j];
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
    64, 1) void native_multi_target_detection_ldl_kernel13(const float C[45],
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
//                float R[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    288, 1) void native_multi_target_detection_ldl_kernel3(float R[28561])
{
  int i;
  i = static_cast<int>(mwGetGlobalThreadIndex());
  if (i < 28561) {
    R[i] = CUDART_NAN_F;
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const int info_t
//                const int b
//                float R[28561]
// Return Type  : void
//
static __global__
    __launch_bounds__(1024, 1) void native_multi_target_detection_ldl_kernel4(
        const int info_t, const int b, float R[28561])
{
  unsigned long gStride;
  unsigned long gThreadId;
  unsigned long loopEnd;
  gThreadId = mwGetGlobalThreadIndex();
  gStride = mwGetTotalThreadsLaunched();
  loopEnd = static_cast<unsigned long>(b);
  for (unsigned long idx{gThreadId}; idx <= loopEnd; idx += gStride) {
    int i;
    int j;
    j = static_cast<int>(idx);
    i = j + 2;
    for (long b_i{0L};
         b_i <= computeEndIdx_device(static_cast<long>(i),
                                     static_cast<long>(info_t), 1L);
         b_i++) {
      R[(static_cast<int>(static_cast<long>(j + 2) + b_i) + 169 * j) - 1] =
          0.0F;
    }
  }
}

//
// Arguments    : dim3 blockArg
//                dim3 gridArg
//                const float R[28561]
//                float A[28561]
// Return Type  : void
//
static __global__ __launch_bounds__(
    288, 1) void native_multi_target_detection_ldl_kernel5(const float R[28561],
                                                           float A[28561])
{
  unsigned long gThreadId;
  int i;
  int j;
  gThreadId = mwGetGlobalThreadIndex();
  j = static_cast<int>(gThreadId % 169UL);
  i = static_cast<int>((gThreadId - static_cast<unsigned long>(j)) / 169UL);
  if ((i < 169) && (j < 169)) {
    A[j + 169 * i] = R[i + 169 * j];
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
    128, 1) void native_multi_target_detection_ldl_kernel6(const float T[2535],
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
//                float W[2535]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel8(float W[2535])
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
//                const float T[2535]
//                float a[2535]
// Return Type  : void
//
static __global__ __launch_bounds__(
    128, 1) void native_multi_target_detection_ldl_kernel9(const float T[2535],
                                                           float a[2535])
{
  unsigned long gThreadId;
  int i;
  int j;
  gThreadId = mwGetGlobalThreadIndex();
  j = static_cast<int>(gThreadId % 15UL);
  i = static_cast<int>((gThreadId - static_cast<unsigned long>(j)) / 15UL);
  if ((i < 169) && (j < 15)) {
    //  TIMING_3
    a[j + 15 * i] = T[i + 169 * j];
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
  dim3 block;
  dim3 grid;
  float(*gpu_X)[692224];
  float(*gpu_a)[692224];
  float(*gpu_A)[28561];
  float(*gpu_R)[28561];
  float(*b_gpu_a)[2535];
  float(*gpu_T)[2535];
  float(*gpu_W)[2535];
  float(*c_gpu_W)[507];
  float(*b_gpu_A)[225];
  float(*gpu_t2)[225];
  float(*b_gpu_W)[45];
  float(*gpu_C)[45];
  float alpha1;
  float beta1;
  int(*gpu_IPIV)[169];
  int(*b_gpu_IPIV)[15];
  int b_cpu_info;
  int c_cpu_info;
  int cpu_info;
  int cpu_info_t;
  int d_cpu_info;
  int *b_gpu_info;
  int *c_gpu_info;
  int *d_gpu_info;
  int *gpu_info;
  int *gpu_info_t;
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


  checkCudaError(mwCudaMalloc(&d_gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&c_gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_IPIV, 60UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_W, 180UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_A, 900UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_t2, 900UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_a, 10140UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&b_gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_info, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_IPIV, 676UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_W, 10140UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_A, 114244UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_info_t, 4UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_R, 114244UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_a, 2768896UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&c_gpu_W, 2028UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_X, 2768896UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_C, 180UL), __FILE__, __LINE__);
  checkCudaError(mwCudaMalloc(&gpu_T, 10140UL), __FILE__, __LINE__);
  //  R = correlation_matrix(X);
  //  TIMING_0
  
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
  
  native_multi_target_detection_ldl_kernel1<<<dim3(1352U, 1U, 1U),
                                              dim3(512U, 1U, 1U)>>>(*gpu_X,
                                                                    *gpu_a);
  alpha1 = 1.0F;
  beta1 = 0.0F;
  cublasCheck(cublasSgemm(getCublasGlobalHandle(), CUBLAS_OP_N, CUBLAS_OP_N,
                          169, 169, 4096, (float *)&alpha1,
                          (float *)&(*gpu_a)[0], 169, (float *)&(*gpu_X)[0],
                          4096, (float *)&beta1, (float *)&(*gpu_R)[0], 169),
              __FILE__, __LINE__);
  //  TIMING_1
  end = clock();
  cudaDeviceSynchronize();
  printf("Correlation matrix 0: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();
  
  native_multi_target_detection_ldl_kernel2<<<dim3(100U, 1U, 1U),
                                              dim3(288U, 1U, 1U)>>>(*gpu_R);
  //  TIMING_2
  //  Alternative: t1 = R \ T;
  // t1 = R \ T;
  end = clock();
  cudaDeviceSynchronize();
  printf("Correlation matrix 1: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();


  cusolverCheck(cusolverDnSpotrf_bufferSize(
                    getCuSolverGlobalHandle(), CUBLAS_FILL_MODE_UPPER, 169,
                    (float *)&(*gpu_R)[0], 169, getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(
      cusolverDnSpotrf(getCuSolverGlobalHandle(), CUBLAS_FILL_MODE_UPPER, 169,
                       (float *)&(*gpu_R)[0], 169,
                       static_cast<float *>(getCuSolverWorkspaceBuff()),
                       *getCuSolverWorkspaceReq(), gpu_info_t),
      __FILE__, __LINE__);
  checkCudaError(
      cudaMemcpy(&cpu_info_t, gpu_info_t, 4UL, cudaMemcpyDeviceToHost),
      __FILE__, __LINE__);
  if (cpu_info_t < 0) {
    native_multi_target_detection_ldl_kernel3<<<dim3(100U, 1U, 1U),
                                                dim3(288U, 1U, 1U)>>>(*gpu_R);
  }
  if (cpu_info_t == 0) {
    cpu_info_t = 169;
  } else {
    cpu_info_t--;
  }
  mwGetLaunchParameters1D(computeNumIters(cpu_info_t - 2), &grid, &block,
                          2147483647U);
  validLaunchParams = mwValidateLaunchParameters(grid, block);
  if (validLaunchParams) {
    native_multi_target_detection_ldl_kernel4<<<grid, block>>>(
        cpu_info_t, cpu_info_t - 2, *gpu_R);
  }
  native_multi_target_detection_ldl_kernel5<<<dim3(100U, 1U, 1U),
                                              dim3(288U, 1U, 1U)>>>(*gpu_R,
                                                                    *gpu_A);
  checkCudaError(cudaMemcpy(*gpu_T, cpu_T, 10140UL, cudaMemcpyHostToDevice),
                 __FILE__, __LINE__);
  native_multi_target_detection_ldl_kernel6<<<dim3(20U, 1U, 1U),
                                              dim3(128U, 1U, 1U)>>>(*gpu_T,
                                                                    *gpu_W);
  cusolverCheck(cusolverDnSgetrf_bufferSize(getCuSolverGlobalHandle(), 169, 169,
                                            (float *)&(*gpu_A)[0], 169,
                                            getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(cusolverDnSgetrf(
                    getCuSolverGlobalHandle(), 169, 169, (float *)&(*gpu_A)[0],
                    169, static_cast<float *>(getCuSolverWorkspaceBuff()),
                    &(*gpu_IPIV)[0], gpu_info),
                __FILE__, __LINE__);
  checkCudaError(cudaMemcpy(&cpu_info, gpu_info, 4UL, cudaMemcpyDeviceToHost),
                 __FILE__, __LINE__);
  if (cpu_info < 0) {
    native_multi_target_detection_ldl_kernel7<<<dim3(20U, 1U, 1U),
                                                dim3(128U, 1U, 1U)>>>(*gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 169,
                                   15, (float *)&(*gpu_A)[0], 169,
                                   &(*gpu_IPIV)[0], (float *)&(*gpu_W)[0], 169,
                                   gpu_info_t),
                  __FILE__, __LINE__);
  }
  cusolverCheck(cusolverDnSgetrf_bufferSize(getCuSolverGlobalHandle(), 169, 169,
                                            (float *)&(*gpu_R)[0], 169,
                                            getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(cusolverDnSgetrf(
                    getCuSolverGlobalHandle(), 169, 169, (float *)&(*gpu_R)[0],
                    169, static_cast<float *>(getCuSolverWorkspaceBuff()),
                    &(*gpu_IPIV)[0], b_gpu_info),
                __FILE__, __LINE__);
  checkCudaError(
      cudaMemcpy(&b_cpu_info, b_gpu_info, 4UL, cudaMemcpyDeviceToHost),
      __FILE__, __LINE__);
  if (b_cpu_info < 0) {
    native_multi_target_detection_ldl_kernel8<<<dim3(20U, 1U, 1U),
                                                dim3(128U, 1U, 1U)>>>(*gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 169,
                                   15, (float *)&(*gpu_R)[0], 169,
                                   &(*gpu_IPIV)[0], (float *)&(*gpu_W)[0], 169,
                                   gpu_info_t),
                  __FILE__, __LINE__);
  }
  //  TIMING_3
    end = clock();
  cudaDeviceSynchronize();
  printf("LDL 1: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();


  native_multi_target_detection_ldl_kernel9<<<dim3(20U, 1U, 1U),
                                              dim3(128U, 1U, 1U)>>>(*gpu_T,
                                                                    *b_gpu_a);
  cublasCheck(cublasSgemm(getCublasGlobalHandle(), CUBLAS_OP_N, CUBLAS_OP_N, 15,
                          15, 169, (float *)&alpha1, (float *)&(*b_gpu_a)[0],
                          15, (float *)&(*gpu_W)[0], 169, (float *)&beta1,
                          (float *)&(*gpu_t2)[0], 15),
              __FILE__, __LINE__);
  //  TIMING_4
  //  Alternative: t3 = t2 \ C;
  // t3 = t2 \ C;
    end = clock();
  cudaDeviceSynchronize();
  printf("MUL 1: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();
  
  cusolverCheck(cusolverDnSpotrf_bufferSize(
                    getCuSolverGlobalHandle(), CUBLAS_FILL_MODE_UPPER, 15,
                    (float *)&(*gpu_t2)[0], 15, getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(
      cusolverDnSpotrf(getCuSolverGlobalHandle(), CUBLAS_FILL_MODE_UPPER, 15,
                       (float *)&(*gpu_t2)[0], 15,
                       static_cast<float *>(getCuSolverWorkspaceBuff()),
                       *getCuSolverWorkspaceReq(), gpu_info_t),
      __FILE__, __LINE__);
  checkCudaError(
      cudaMemcpy(&cpu_info_t, gpu_info_t, 4UL, cudaMemcpyDeviceToHost),
      __FILE__, __LINE__);
  if (cpu_info_t < 0) {
    native_multi_target_detection_ldl_kernel10<<<dim3(2U, 1U, 1U),
                                                 dim3(128U, 1U, 1U)>>>(*gpu_t2);
  }
  if (cpu_info_t == 0) {
    cpu_info_t = 15;
  } else {
    cpu_info_t--;
  }
  mwGetLaunchParameters1D(computeNumIters(cpu_info_t - 2), &grid, &block,
                          2147483647U);
  validLaunchParams = mwValidateLaunchParameters(grid, block);
  if (validLaunchParams) {
    native_multi_target_detection_ldl_kernel11<<<grid, block>>>(
        cpu_info_t, cpu_info_t - 2, *gpu_t2);
  }
  native_multi_target_detection_ldl_kernel12<<<dim3(2U, 1U, 1U),
                                               dim3(128U, 1U, 1U)>>>(*gpu_t2,
                                                                     *b_gpu_A);
  checkCudaError(cudaMemcpy(*gpu_C, cpu_C, 180UL, cudaMemcpyHostToDevice),
                 __FILE__, __LINE__);
  native_multi_target_detection_ldl_kernel13<<<dim3(1U, 1U, 1U),
                                               dim3(64U, 1U, 1U)>>>(*gpu_C,
                                                                    *b_gpu_W);
  cusolverCheck(cusolverDnSgetrf_bufferSize(getCuSolverGlobalHandle(), 15, 15,
                                            (float *)&(*b_gpu_A)[0], 15,
                                            getCuSolverWorkspaceReq()),
                __FILE__, __LINE__);
  setCuSolverWorkspaceTypeSize(4);
  cusolverInitWorkspace();
  cusolverCheck(cusolverDnSgetrf(
                    getCuSolverGlobalHandle(), 15, 15, (float *)&(*b_gpu_A)[0],
                    15, static_cast<float *>(getCuSolverWorkspaceBuff()),
                    &(*b_gpu_IPIV)[0], c_gpu_info),
                __FILE__, __LINE__);
  checkCudaError(
      cudaMemcpy(&c_cpu_info, c_gpu_info, 4UL, cudaMemcpyDeviceToHost),
      __FILE__, __LINE__);
  if (c_cpu_info < 0) {
    native_multi_target_detection_ldl_kernel14<<<dim3(1U, 1U, 1U),
                                                 dim3(64U, 1U, 1U)>>>(*b_gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 15,
                                   3, (float *)&(*b_gpu_A)[0], 15,
                                   &(*b_gpu_IPIV)[0], (float *)&(*b_gpu_W)[0],
                                   15, gpu_info_t),
                  __FILE__, __LINE__);
  }
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
    native_multi_target_detection_ldl_kernel15<<<dim3(1U, 1U, 1U),
                                                 dim3(64U, 1U, 1U)>>>(*b_gpu_W);
  } else {
    cusolverCheck(cusolverDnSgetrs(getCuSolverGlobalHandle(), CUBLAS_OP_N, 15,
                                   3, (float *)&(*gpu_t2)[0], 15,
                                   &(*b_gpu_IPIV)[0], (float *)&(*b_gpu_W)[0],
                                   15, gpu_info_t),
                  __FILE__, __LINE__);
  }
  //  TIMING_5
    end = clock();
  cudaDeviceSynchronize();
  printf("LDL 2: %lf seconds\n", ((double) (end - start)) / CLOCKS_PER_SEC);
  start = clock();
  
  //  Compute the weighting matrix W
  cublasCheck(cublasSgemm(getCublasGlobalHandle(), CUBLAS_OP_N, CUBLAS_OP_N,
                          169, 3, 15, (float *)&alpha1, (float *)&(*gpu_W)[0],
                          169, (float *)&(*b_gpu_W)[0], 15, (float *)&beta1,
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
  checkCudaError(mwCudaFree(gpu_info_t), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_A), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_W), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_IPIV), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(gpu_info), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(b_gpu_info), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*b_gpu_a), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*gpu_t2), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*b_gpu_A), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*b_gpu_W), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(*b_gpu_IPIV), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(c_gpu_info), __FILE__, __LINE__);
  checkCudaError(mwCudaFree(d_gpu_info), __FILE__, __LINE__);
  
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
