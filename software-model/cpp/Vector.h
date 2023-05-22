#pragma once

#include <initializer_list>
#include "Matrix.h"

class Vector : Matrix
{
public:
	
	Vector(dim_t size)
		: Matrix(size, 1)
	{}

	inline Vector(std::initializer_list<const scalar_t> list)
		: Matrix(list.size(), 1)
	{		
		dim_t idx = 0;
		for (const scalar_t& el : list) {
			el_(idx) = el;
			idx++;
		}
	}

	dim_t size() const {
		return num_rows();
	}

	inline scalar_t& el_(dim_t idx) {
		return Matrix::el_(idx, 0);
	}

	inline const scalar_t& el_(dim_t idx) const {
		return Matrix::el_(idx, 0);
	}

	inline scalar_t& operator() (dim_t idx) {
		return el_(idx);
	}

	inline const scalar_t& operator() (dim_t idx) const {
		return el_(idx);
	}
};

std::ostream& operator<<(std::ostream& os, const Vector& v);