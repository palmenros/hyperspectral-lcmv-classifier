#include "Vector.h"
#include <ostream>

std::ostream& operator<<(std::ostream& os, const Vector& v)
{
	os << "(";

	bool first = true;

	for (dim_t i = 0; i < v.size(); i++) {
		if (first) {
			first = false;
		} else {
			os << ", ";
		}
		os << v(i);
	}

	os << ")";

	return os;
}
