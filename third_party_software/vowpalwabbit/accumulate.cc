/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD (revised)
license as described in the file LICENSE.
 */
/*
This implements the allreduce function of MPI.  Code primarily by
Alekh Agarwal and John Langford, with help Olivier Chapelle.
*/

#include <iostream>
#include <sys/timeb.h>
#include <cmath>
#include <stdint.h>
#include "global_data.h"
#include "vw_allreduce.h"

using namespace std;

void add_float(float& c1, const float& c2) { c1 += c2; }

void accumulate(vw& all, regressor& reg, size_t o)
{ uint32_t length = 1 << all.num_bits; //This is size of gradient
  size_t stride = 1 << all.reg.stride_shift;
  float* local_grad = new float[length];
  weight* weights = reg.weight_vector;
  for(uint32_t i = 0; i < length; i++)
    local_grad[i] = weights[stride*i+o];

  all_reduce<float, add_float>(all, local_grad, length);
  for (uint32_t i = 0; i < length; i++)
    weights[stride*i+o] = local_grad[i];
  delete[] local_grad;
}

float accumulate_scalar(vw& all, float local_sum)
{ float temp = local_sum;
  all_reduce<float, add_float>(all, &temp, 1);
  return temp;
}

void accumulate_avg(vw& all, regressor& reg, size_t o)
{ uint32_t length = 1 << all.num_bits; //This is size of gradient
  size_t stride = 1 << all.reg.stride_shift;
  float* local_grad = new float[length];
  weight* weights = reg.weight_vector;
  float numnodes = (float)all.all_reduce->total;

  for(uint32_t i = 0; i < length; i++)
    local_grad[i] = weights[stride*i+o];

  all_reduce<float, add_float>(all, local_grad, length);
  for (uint32_t i = 0; i < length; i++)
    weights[stride*i+o] = local_grad[i]/numnodes;
  delete[] local_grad;
}

float max_elem(float* arr, int length)
{ float max = arr[0];
  for(int i = 1; i < length; i++)
    if(arr[i] > max) max = arr[i];
  return max;
}

float min_elem(float* arr, int length)
{ float min = arr[0];
  for(int i = 1; i < length; i++)
    if(arr[i] < min && arr[i] > 0.001) min = arr[i];
  return min;
}

void accumulate_weighted_avg(vw& all, regressor& reg)
{ if(!all.adaptive)
  { cerr<<"Weighted averaging is implemented only for adaptive gradient, use accumulate_avg instead\n";
    return;
  }
  uint32_t length = 1 << all.num_bits; //This is the number of parameters
  size_t stride = 1 << all.reg.stride_shift;
  weight* weights = reg.weight_vector;
  float* local_weights = new float[length];

  for(uint32_t i = 0; i < length; i++)
    local_weights[i] = weights[stride*i+1];

  //First compute weights for averaging
  all_reduce<float, add_float>(all, local_weights, length);

  for(uint32_t i = 0; i < length; i++) //Compute weighted versions
    if(local_weights[i] > 0)
    { float ratio = weights[stride*i+1]/local_weights[i];
      local_weights[i] = weights[stride*i] * ratio;
      weights[stride*i] *= ratio;
      weights[stride*i+1] *= ratio; //A crude max
      if (all.normalized_updates)
        weights[stride*i+all.normalized_idx] *= ratio; //A crude max
    }
    else
    { local_weights[i] = 0;
      weights[stride*i] = 0;
    }

  all_reduce<float, add_float>(all, weights, length*stride);

  delete[] local_weights;
}

