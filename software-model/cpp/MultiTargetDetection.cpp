#include "MultiTargetDetection.h"
#include "Matrix.h"
#include "Vector.h"
#include <iostream>
#include "Types.h"
#include <cmath>
#include <vector>
#include <chrono>

void multi_target_detection_lcmv(const Matrix& T, const Matrix& C, const Matrix& X, Matrix& out)
{

	// N = 4096
	dim_t NUM_PIXELS = X.num_rows();

	// NUM_CHANNELS = 169
	dim_t NUM_CHANNELS = X.num_cols();
	
	// NUM_SIGNATURES = 15
	dim_t NUM_SIGNATURES = C.num_rows();
	
	// NUM_OUTPUT_CHANNELS = 3
	dim_t NUM_OUTPUT_CHANNELS = C.num_cols();

	ASSERT(out.num_rows() == NUM_PIXELS);
	ASSERT(out.num_cols() == NUM_OUTPUT_CHANNELS);

	ASSERT(T.num_rows() == NUM_CHANNELS);
	ASSERT(T.num_cols() == NUM_SIGNATURES);

	// Compute correlation matrix
	
	Matrix W(NUM_CHANNELS, NUM_OUTPUT_CHANNELS);
	std::vector<double> times(6);
	multi_target_detection_W(T, C, X, W, times);

	// Classify each pixel
	for (dim_t i = 0; i < NUM_PIXELS; i++) {
		// out(i, :) = X(i, :) * W;
		for (dim_t j = 0; j < NUM_OUTPUT_CHANNELS; j++) {
			scalar_t sum = 0;

			for (dim_t k = 0; k < NUM_CHANNELS; k++) {
				sum += X(i, k) * W(k, j);
			}

			out(i, j) = sum;
		}
	}
}

// size(X) = [N, M]
// size(R) = [M, M]
// Does not divide by N
// When this function returns R = X' * X
void correlation_matrix(const Matrix& X, Matrix& R)
{
	dim_t n = X.num_rows();
	dim_t m = X.num_cols();

	ASSERT(R.is_square());
	ASSERT(R.num_rows() == m);
	ASSERT(R.num_cols() == m);

	Vector d(m);

	for (dim_t i = 0; i != n; i++) {
		// Para cada sample
		
		// Esperamos a que d este lleno con los nuevos datos
		// (en hardware esperamos a que el bus se llene)
		for (dim_t _k = 0; _k != m; _k++) {
			d(_k) = X(i, _k);
		}

		for (dim_t j = 0; j != m; j++) {
			// Para cada datapoint de sample

			//R(j, :) = d * d(j) + (i == 0 ? 0 : R(j, :));

			for (dim_t _k = 0; _k != m; _k++) {
				R(j, _k) = d(_k) * d(j) + (i == 0 ? 0 : R(j, _k));
			}
		}
	}
}

// When this function returns X = X / N
void divide_matrix(Matrix& X, scalar_t e)
{
	dim_t n = X.num_rows();
	dim_t m = X.num_cols();

	for (dim_t i = 0; i < n; i++) {
		for (dim_t j = 0; j < m; j++) {
			X(i, j) /= e;
		}
	}
}

// size(A) = [n, p]
// size(B) = [p, m]
// size(O) = [n, m]
// When this function returns, O = A * B
void matrix_mult(const Matrix& A, const Matrix& B, Matrix& O) {
	dim_t n = A.num_rows();
	dim_t p = A.num_cols();
	
	ASSERT(B.num_rows() == p);
	dim_t m = B.num_cols();

	ASSERT(O.num_rows() == n);
	ASSERT(O.num_cols() == m);

	for (dim_t i = 0; i < n; i++) {
		for (dim_t j = 0; j < m; j++) {
			// Producto escalar
			// O(i, j) = A(i, :) * B(:, j)
			scalar_t sum = 0;

			for (dim_t k = 0; k < p; k++) {
				sum += A(i, k) * B(k, j);
			}

			O(i, j) = sum;
		}
	}

}

void tri_solve(Matrix& A, const Matrix& B, Matrix& X, bool tri_lower)
{
	dim_t n = A.num_rows();
	dim_t m = B.num_cols();

	ASSERT(A.is_square());
	ASSERT(B.num_rows() == n);
	ASSERT(X.num_rows() == n);
	ASSERT(X.num_cols() == m);

	// Podemos tratar por separado el caso 0, porque no hace falta hacer
	// ningun producto, pero por uniformidad, para hacer mas sencillo el hardware
	// utilizaremos
	
	//for (dim_t k = 0; k != m; k++) {
	//	X(tri_lower ? 0 : n - 1, k) = B(tri_lower ? 0 : n - 1, k);
	//}

	// Si separamos el primer caso, seria
	//	for (dim_t i = tri_lower ? 1 : n - 2; tri_lower ? i != n : i >= 0; tri_lower ? i++ : i--) {
	for (dim_t i = tri_lower ? 0 : n - 1; tri_lower ? i != n : i >= 0; tri_lower ? i++ : i--) {
		for (dim_t k = 0; k != m; k++) {
			// Si tri_lower:
			//X(i, k) = B(i, k) - A(i, 1:i - 1) * X(1:i - 1, k);
			
			// Si tri_upper:
			//X(i, k) = B(i, k) - X((i + 1) : n, k)' * A((i+1):n, i);

			X(i, k) = B(i, k);

			if (tri_lower) {
				for (dim_t l = 0; l < i; l++) {
					X(i, k) = X(i, k) - A(i, l) * X(l, k);
				}
			} else {
				for (dim_t l = i + 1; l < n; l++) {
					X(i, k) = X(i, k) - A(l, i) * X(l, k);
				}
			}
		}
	}
}

// Solve L* X = B, where L = tril(A)
// size(A) = [n, n]
// size(B) = [n, m]
// size(X) = [n, m]
void tril_solve(Matrix& A, const Matrix& B, Matrix& X)
{
	dim_t n = A.num_rows();
	dim_t m = B.num_cols();

	ASSERT(A.is_square());
	ASSERT(B.num_rows() == n);
	ASSERT(X.num_rows() == n);
	ASSERT(X.num_cols() == m);

	// Podemos tratar por separado el caso 0, porque no hace falta hacer
	// ningun producto 

	// X(1, :) = B(1, :);
	for (dim_t k = 0; k != m; k++) {
		X(0, k) = B(0, k);
	}

	for (dim_t i = 1; i != n; i++) {
		for (dim_t k = 0; k != m; k++) {
			//W(i, k) = B(i, k) - L(i, 1:i - 1) * W(1:i - 1, k);
			X(i, k) = B(i, k);
			for (dim_t l = 0; l < i; l++) {
				X(i, k) = X(i, k) - A(i, l) * X(l, k);
			}
		}
	}
}

//Solve L'*X = B, where L = tril(A)
void triu_solve(Matrix& A, const Matrix& B, Matrix& X)
{
	dim_t n = A.num_rows();
	dim_t m = B.num_cols();

	ASSERT(A.is_square());
	ASSERT(B.num_rows() == n);
	ASSERT(X.num_rows() == n);
	ASSERT(X.num_cols() == m);

	for (dim_t j = 0; j < m; j++) {
		X(n - 1, j) = B(n - 1, j);
	}

	for (dim_t i = n - 1; i >= 0; i--) {
		for (dim_t k = 0; k != m; k++) {
			//X(i, k) = W2(i, k) - X((i + 1) : n, k)' * L((i+1):n, i);

			X(i, k) = B(i, k);
			for (dim_t l = i + 1; l < n; l++) {
				X(i, k) = X(i, k) - X(l, k) * A(l, i);
			}
		}
	}
}

void ldl_solve(Matrix& A, const Matrix& B, Matrix& X) 
{
	dim_t n = A.num_rows();
	dim_t m = B.num_cols();

	ASSERT(A.is_square());
	ASSERT(X.num_rows() == n);
	ASSERT(X.num_cols() == m);

	Vector d(n);

	ldl(A, d);

	// Just rename to L after ldl call, but it's still stored in A
	Matrix& L = A;

	Matrix W(n, m);

	// We start solving L*W = B
	//tril_solve(A, B, W);
	tri_solve(A, B, W, true);

	// Now we solve D*W2 = W
	// We overwite W2 in W
	// It is more efficient to store W2 at the same place that W
	
	// W2(:, k) = W(:, k) ./ d;
	for (dim_t row = 0; row != n; row++) {
		for (dim_t col = 0; col != m; col++) {
			W(row, col) = W(row, col) / d(row);
		}
	}

	// Finally we solve L'*X = W2
	// We remember that W2 is actually stored in W now

	// X(n, :) = W2(n, :);
	//triu_solve(A, W, X);
	tri_solve(A, W, X, false);
}

// Only uses the lower triagonal part of A,
// so it only uses A = tril(A), the upper part may be garbage.
// L will be the lower triagonal part of A
// A = L*D*L'
void ldl(Matrix& A, Vector& d)
{
	dim_t n = A.num_rows();

	ASSERT(A.is_square());
	ASSERT(d.size() == n);

	Vector v(n);


	// NOTE: Changed < to != for hardware efficency.
	for (dim_t j = 0; j != n; j++) {
		//v(1:j-1) = A(j, 1:j-1) .* d(1:j-1)';

		// When implementing in Verilog, be careful with the case j=0, as j-1 will be negative (handle comparison properly)
		for (dim_t k = 0; k != j; k++) {
			v(k) = A(j, k) * d(k);
		}

		//d(j) = A(j, j) - A(j, 1:j - 1) * v(1:j - 1);
		d(j) = A(j, j);
		for (dim_t k = 0; k != j; k++) {
			d(j) = d(j) - A(j, k) * v(k);
		}

		for (dim_t k = j+1; k != n; k++) {
			//A(k, j) = (A(k, j) - A(k, 1:j - 1) * v(1:j - 1)) / d(j);
			for (dim_t l = 0; l != j; l++) {
				A(k, j) = A(k, j) - A(k, l) * v(l);
			}
			A(k, j) = A(k, j) / d(j);
		}
	}

	//Set diagonal of A to 1
	
	// (Not needed for LDL solving)
	
	//for (dim_t k = 0; k < n; k++) {
	//	A(k, k) = 1;
	//}
}