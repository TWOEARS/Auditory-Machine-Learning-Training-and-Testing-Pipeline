// On Windows, exp(-infinity) incorrectly returns -infinity instead of 0.
// So we replace it with our own version that checks for this condition.

#pragma once

#include <math.h>

#ifdef _WIN32
// this is a bug in VS2013, fixed in VS2015 runtime
template<typename T>
T correctedExp(T exponent)
{ if (isinf(exponent) && exponent < T(0))
  { return T(0);
  }
  else
  { return exp(exponent);
  }
}
#else
#define correctedExp exp
#endif
