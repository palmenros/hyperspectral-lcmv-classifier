#include "Matrix.h"
#include <ostream>

Matrix::Matrix(dim_t n_rows, dim_t n_columns)
	: n_rows(n_rows), n_columns(n_columns)
{
	data = new scalar_t[n_rows * n_columns];
}

Matrix::Matrix(std::initializer_list<std::initializer_list<scalar_t>> list)
{
	n_rows = list.size();
	
	if (n_rows == 0) {
		throw std::invalid_argument("Invalid matrix dimensions");
	}

	bool first = true;
	
	dim_t row_n = 0;

	for (std::initializer_list<scalar_t> row : list) {
		if (first) {
			n_columns = row.size();
			if (n_columns == 0) {
				throw std::invalid_argument("Invalid matrix dimensions");
			}
			data = new scalar_t[n_rows * n_columns];
			first = false;
		} else {
			if (n_columns != row.size()) {
				throw std::invalid_argument("Matrix: Different rows have different dimensions");
			}
		}

		dim_t col_n = 0;
		for (scalar_t el : row) {
			el_(row_n, col_n) = el;
			col_n++;
		}

		row_n++;
	}

}

Matrix::Matrix(const Matrix& other)
{
	n_rows = other.n_rows;
	n_columns = other.n_columns;

	data = new scalar_t[n_rows * n_columns];
	memcpy(data, other.data, sizeof(scalar_t) * n_rows * n_columns);
}

Matrix& Matrix::operator=(const Matrix& other)
{
	//Delete possibly existing data
	if (data) {
		delete[] data;
	}

	n_rows = other.n_rows;
	n_columns = other.n_columns;

	data = new scalar_t[n_rows * n_columns];
	memcpy(data, other.data, sizeof(scalar_t) * n_rows * n_columns);
	
	return *this;
}

Matrix Matrix::transpose() const 
{
	Matrix res(n_columns, n_rows);

	for (dim_t i = 0; i < n_rows; ++i) {
		for (dim_t j = 0; j < n_columns; ++j) {
			res(j, i) = el_(i, j);
		}
	}

	return res;
}

Matrix::~Matrix()
{
	delete[] data;
}

std::ostream & operator<<(std::ostream & os, const Matrix & matrix)
{
	for (int r = 0; r < matrix.num_rows(); r++) {
		os << matrix(r, 0);
		for (int c = 1; c < matrix.num_cols(); c++)
		{
			os << " " << matrix(r, c);
		}
		os << std::endl;
	}
	return os;
}
