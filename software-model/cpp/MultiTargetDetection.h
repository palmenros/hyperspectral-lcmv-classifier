#pragma once

#include "Matrix.h"
#include "Vector.h"
#include <vector>

void multi_target_detection_lcmv(const Matrix& T, const Matrix& C, const Matrix& X, Matrix& out);
void ldl_solve(Matrix& A, const Matrix& B, Matrix& X);
void ldl(Matrix& A, Vector& d);
void matrix_mult(const Matrix& A, const Matrix& B, Matrix& O);
void correlation_matrix(const Matrix& X, Matrix& R);
void divide_matrix(Matrix& X, scalar_t e);