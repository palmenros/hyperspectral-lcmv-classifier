#pragma once

#include "Types.h"
#include <stdexcept>
#include <initializer_list>

/*
*	A matrix contains the data structures needed
*/
class Matrix
{
public:

	// Constructors, destructors and copy constructors
	Matrix(dim_t n_rows, dim_t n_columns);
	Matrix(std::initializer_list<std::initializer_list<scalar_t>> list);
	Matrix(const Matrix& other);
	Matrix& operator=(const Matrix& other);
	~Matrix();

	Matrix transpose() const;

	// Getters
	inline dim_t num_rows() const {
		return n_rows;
	}

	inline dim_t num_cols() const {
		return n_columns;
	}

	inline bool is_square() const {
		return n_columns == n_rows;
	}

	inline scalar_t& operator() (dim_t row, dim_t col)
	{
		return el_(row, col);
	}

	inline const scalar_t& operator() (dim_t row, dim_t col) const
	{
		return el_(row, col);
	}

protected:

	inline scalar_t& el_(dim_t row, dim_t col) {
		if (row >= n_rows || col >= n_columns) {
			throw std::out_of_range("Matrix subscript out of bounds");
		}
		return data[n_columns * row + col];
	}

	inline const scalar_t& el_(dim_t row, dim_t col) const {
		if (row >= n_rows || col >= n_columns) {
			throw std::out_of_range("Matrix subscript out of bounds");
		}
		return data[n_columns * row + col];
	}

private:

	dim_t n_rows = 0;
	dim_t n_columns = 0;

	scalar_t* data = nullptr;
};

std::ostream& operator<<(std::ostream& os, const Matrix& matrix);