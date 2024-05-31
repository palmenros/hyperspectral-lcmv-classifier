/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: mldivide.c
 *
 * MATLAB Coder version            : 24.1
 * C/C++ source code generated on  : 07-May-2024 11:25:32
 */

/* Include Files */
#include "mldivide.h"
#include <math.h>
#include <string.h>

/* Function Definitions */
/*
 * Arguments    : const float A[225]
 *                float B[45]
 * Return Type  : void
 */
void b_mldivide(const float A[225], float B[45])
{
  float b_A[225];
  float smax;
  int b_i;
  int i;
  int j;
  int jA;
  int jBcol;
  int jp1j;
  int k;
  int kAcol;
  signed char ipiv[15];
  memcpy(&b_A[0], &A[0], 225U * sizeof(float));
  for (i = 0; i < 15; i++) {
    ipiv[i] = (signed char)(i + 1);
  }
  for (j = 0; j < 14; j++) {
    int b_tmp;
    int mmj_tmp;
    signed char i1;
    mmj_tmp = 13 - j;
    b_tmp = j << 4;
    jp1j = b_tmp + 2;
    jA = 15 - j;
    jBcol = 0;
    smax = fabsf(b_A[b_tmp]);
    for (k = 2; k <= jA; k++) {
      float s;
      s = fabsf(b_A[(b_tmp + k) - 1]);
      if (s > smax) {
        jBcol = k - 1;
        smax = s;
      }
    }
    if (b_A[b_tmp + jBcol] != 0.0F) {
      if (jBcol != 0) {
        jA = j + jBcol;
        ipiv[j] = (signed char)(jA + 1);
        for (k = 0; k < 15; k++) {
          jBcol = j + k * 15;
          smax = b_A[jBcol];
          kAcol = jA + k * 15;
          b_A[jBcol] = b_A[kAcol];
          b_A[kAcol] = smax;
        }
      }
      i = (b_tmp - j) + 15;
      for (b_i = jp1j; b_i <= i; b_i++) {
        b_A[b_i - 1] /= b_A[b_tmp];
      }
    }
    jA = b_tmp;
    for (jBcol = 0; jBcol <= mmj_tmp; jBcol++) {
      smax = b_A[(b_tmp + jBcol * 15) + 15];
      if (smax != 0.0F) {
        i = jA + 17;
        jp1j = (jA - j) + 30;
        for (kAcol = i; kAcol <= jp1j; kAcol++) {
          b_A[kAcol - 1] += b_A[((b_tmp + kAcol) - jA) - 16] * -smax;
        }
      }
      jA += 15;
    }
    i1 = ipiv[j];
    if (i1 != j + 1) {
      smax = B[j];
      B[j] = B[i1 - 1];
      B[i1 - 1] = smax;
      smax = B[j + 15];
      B[j + 15] = B[i1 + 14];
      B[i1 + 14] = smax;
      smax = B[j + 30];
      B[j + 30] = B[i1 + 29];
      B[i1 + 29] = smax;
    }
  }
  for (j = 0; j < 3; j++) {
    jBcol = 15 * j;
    for (k = 0; k < 15; k++) {
      kAcol = 15 * k;
      i = k + jBcol;
      if (B[i] != 0.0F) {
        jp1j = k + 2;
        for (b_i = jp1j; b_i < 16; b_i++) {
          jA = (b_i + jBcol) - 1;
          B[jA] -= B[i] * b_A[(b_i + kAcol) - 1];
        }
      }
    }
  }
  for (j = 0; j < 3; j++) {
    jBcol = 15 * j;
    for (k = 14; k >= 0; k--) {
      kAcol = 15 * k;
      i = k + jBcol;
      smax = B[i];
      if (smax != 0.0F) {
        B[i] = smax / b_A[k + kAcol];
        for (b_i = 0; b_i < k; b_i++) {
          jp1j = b_i + jBcol;
          B[jp1j] -= B[i] * b_A[b_i + kAcol];
        }
      }
    }
  }
}

/*
 * Arguments    : const float A[28561]
 *                float B[2535]
 * Return Type  : void
 */
void mldivide(const float A[28561], float B[2535])
{
  float b_A[28561];
  float smax;
  int b_i;
  int i;
  int i1;
  int j;
  int jA;
  int jBcol;
  int jp1j;
  int k;
  int temp_tmp;
  short ipiv[169];
  memcpy(&b_A[0], &A[0], 28561U * sizeof(float));
  for (i = 0; i < 169; i++) {
    ipiv[i] = (short)(i + 1);
  }
  for (j = 0; j < 168; j++) {
    int b_tmp;
    int mmj_tmp;
    short i2;
    mmj_tmp = 167 - j;
    b_tmp = j * 170;
    jp1j = b_tmp + 2;
    jA = 169 - j;
    jBcol = 0;
    smax = fabsf(b_A[b_tmp]);
    for (k = 2; k <= jA; k++) {
      float s;
      s = fabsf(b_A[(b_tmp + k) - 1]);
      if (s > smax) {
        jBcol = k - 1;
        smax = s;
      }
    }
    if (b_A[b_tmp + jBcol] != 0.0F) {
      if (jBcol != 0) {
        jA = j + jBcol;
        ipiv[j] = (short)(jA + 1);
        for (k = 0; k < 169; k++) {
          temp_tmp = j + k * 169;
          smax = b_A[temp_tmp];
          jBcol = jA + k * 169;
          b_A[temp_tmp] = b_A[jBcol];
          b_A[jBcol] = smax;
        }
      }
      i = (b_tmp - j) + 169;
      for (b_i = jp1j; b_i <= i; b_i++) {
        b_A[b_i - 1] /= b_A[b_tmp];
      }
    }
    jA = b_tmp;
    for (jp1j = 0; jp1j <= mmj_tmp; jp1j++) {
      smax = b_A[(b_tmp + jp1j * 169) + 169];
      if (smax != 0.0F) {
        i = jA + 171;
        i1 = (jA - j) + 338;
        for (jBcol = i; jBcol <= i1; jBcol++) {
          b_A[jBcol - 1] += b_A[((b_tmp + jBcol) - jA) - 170] * -smax;
        }
      }
      jA += 169;
    }
    i2 = ipiv[j];
    if (i2 != j + 1) {
      for (jp1j = 0; jp1j < 15; jp1j++) {
        temp_tmp = j + 169 * jp1j;
        smax = B[temp_tmp];
        i = (i2 + 169 * jp1j) - 1;
        B[temp_tmp] = B[i];
        B[i] = smax;
      }
    }
  }
  for (j = 0; j < 15; j++) {
    jBcol = 169 * j;
    for (k = 0; k < 169; k++) {
      jA = 169 * k;
      i = k + jBcol;
      if (B[i] != 0.0F) {
        i1 = k + 2;
        for (b_i = i1; b_i < 170; b_i++) {
          temp_tmp = (b_i + jBcol) - 1;
          B[temp_tmp] -= B[i] * b_A[(b_i + jA) - 1];
        }
      }
    }
  }
  for (j = 0; j < 15; j++) {
    jBcol = 169 * j;
    for (k = 168; k >= 0; k--) {
      jA = 169 * k;
      i = k + jBcol;
      smax = B[i];
      if (smax != 0.0F) {
        B[i] = smax / b_A[k + jA];
        for (b_i = 0; b_i < k; b_i++) {
          i1 = b_i + jBcol;
          B[i1] -= B[i] * b_A[b_i + jA];
        }
      }
    }
  }
}

/*
 * File trailer for mldivide.c
 *
 * [EOF]
 */
