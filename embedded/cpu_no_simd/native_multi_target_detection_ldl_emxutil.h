/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: native_multi_target_detection_ldl_emxutil.h
 *
 * MATLAB Coder version            : 24.1
 * C/C++ source code generated on  : 07-May-2024 11:25:32
 */

#ifndef NATIVE_MULTI_TARGET_DETECTION_LDL_EMXUTIL_H
#define NATIVE_MULTI_TARGET_DETECTION_LDL_EMXUTIL_H

/* Include Files */
#include "native_multi_target_detection_ldl_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void emxEnsureCapacity_real32_T(emxArray_real32_T *emxArray,
                                       int oldNumel);

extern void emxFree_real32_T(emxArray_real32_T **pEmxArray);

extern void emxInit_real32_T(emxArray_real32_T **pEmxArray);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for native_multi_target_detection_ldl_emxutil.h
 *
 * [EOF]
 */
