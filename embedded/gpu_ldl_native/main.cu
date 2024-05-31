//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: main.cu
//
// GPU Coder version                    : 24.1
// CUDA/C/C++ source code generated on  : 12-May-2024 11:24:45
//

/*************************************************************************/
/* This automatically generated example CUDA main file shows how to call */
/* entry-point functions that MATLAB Coder generated. You must customize */
/* this file for your application. Do not modify this file directly.     */
/* Instead, make a copy of this file, modify it, and integrate it into   */
/* your development environment.                                         */
/*                                                                       */
/* This file initializes entry-point function arguments to a default     */
/* size and value before calling the entry-point functions. It does      */
/* not store or use any values returned from the entry-point functions.  */
/* If necessary, it does pre-allocate memory for returned values.        */
/* You can use this file as a starting point for a main function that    */
/* you can deploy in your application.                                   */
/*                                                                       */
/* After you copy the file, and before you deploy it, you must make the  */
/* following changes:                                                    */
/* * For variable-size function arguments, change the example sizes to   */
/* the sizes that your application requires.                             */
/* * Change the example values of function arguments to the values that  */
/* your application requires.                                            */
/* * If the entry-point functions return values, store these values or   */
/* otherwise use them as required by your application.                   */
/*                                                                       */
/*************************************************************************/

// Include Files
#include "main.h"
#include "native_multi_target_detection_ldl.h"
#include "native_multi_target_detection_ldl_terminate.h"
#include "rt_nonfinite.h"

// Function Declarations
static void argInit_15x3_real32_T(float result[45]);

static void argInit_169x15_real32_T(float result[2535]);

static void argInit_4096x169_real32_T(float result[692224]);

static float argInit_real32_T();

// Function Definitions
//
// Arguments    : float result[45]
// Return Type  : void
//
static void argInit_15x3_real32_T(float result[45])
{
  // Loop over the array to initialize each element.
  for (int i{0}; i < 45; i++) {
    // Set the value of the array element.
    // Change this value to the value that the application requires.
    result[i] = argInit_real32_T();
  }
}

//
// Arguments    : float result[2535]
// Return Type  : void
//
static void argInit_169x15_real32_T(float result[2535])
{
  // Loop over the array to initialize each element.
  for (int i{0}; i < 2535; i++) {
    // Set the value of the array element.
    // Change this value to the value that the application requires.
    result[i] = argInit_real32_T();
  }
}

//
// Arguments    : float result[692224]
// Return Type  : void
//
static void argInit_4096x169_real32_T(float result[692224])
{
  // Loop over the array to initialize each element.
  for (int i{0}; i < 692224; i++) {
    // Set the value of the array element.
    // Change this value to the value that the application requires.
    result[i] = argInit_real32_T();
  }
}

//
// Arguments    : void
// Return Type  : float
//
static float argInit_real32_T()
{
  return 0.0F;
}

//
// Arguments    : int argc
//                char **argv
// Return Type  : int
//
int main(int, char **)
{
  // The initialize function is being called automatically from your entry-point
  // function. So, a call to initialize is not included here. Invoke the
  // entry-point functions.
  // You can call entry-point functions multiple times.
  main_native_multi_target_detection_ldl();
  // Terminate the application.
  // You do not need to do this more than one time.
  native_multi_target_detection_ldl_terminate();
  return 0;
}

//
// Arguments    : void
// Return Type  : void
//
void main_native_multi_target_detection_ldl()
{
  static float d[692224];
  float b[2535];
  float W[507];
  float c[45];
  // Initialize function 'native_multi_target_detection_ldl' input arguments.
  // Initialize function input argument 'T'.
  // Initialize function input argument 'C'.
  // Initialize function input argument 'X'.
  // Call the entry-point 'native_multi_target_detection_ldl'.
  argInit_169x15_real32_T(b);
  argInit_15x3_real32_T(c);
  argInit_4096x169_real32_T(d);
  native_multi_target_detection_ldl(b, c, d, W);
}

//
// File trailer for main.cu
//
// [EOF]
//
