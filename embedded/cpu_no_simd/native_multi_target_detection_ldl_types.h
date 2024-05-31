/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: native_multi_target_detection_ldl_types.h
 *
 * MATLAB Coder version            : 24.1
 * C/C++ source code generated on  : 07-May-2024 11:25:32
 */

#ifndef NATIVE_MULTI_TARGET_DETECTION_LDL_TYPES_H
#define NATIVE_MULTI_TARGET_DETECTION_LDL_TYPES_H

/* Include Files */
#include "rtwtypes.h"

/* Type Definitions */
#ifndef struct_emxArray_real32_T
#define struct_emxArray_real32_T
struct emxArray_real32_T {
  float *data;
  int *size;
  int allocatedSize;
  int numDimensions;
  bool canFreeData;
};
#endif /* struct_emxArray_real32_T */
#ifndef typedef_emxArray_real32_T
#define typedef_emxArray_real32_T
typedef struct emxArray_real32_T emxArray_real32_T;
#endif /* typedef_emxArray_real32_T */

#endif
/*
 * File trailer for native_multi_target_detection_ldl_types.h
 *
 * [EOF]
 */
