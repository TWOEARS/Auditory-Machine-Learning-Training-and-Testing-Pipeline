/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD
license as described in the file LICENSE.
 */
#pragma once
#include "label_parser.h"

struct example;
struct vw;

namespace COST_SENSITIVE
{
struct wclass
{ float x;
  uint32_t class_index;
  float partial_prediction;  // a partial prediction: new!
  float wap_value;  // used for wap to store values derived from costs
  bool operator==(wclass j) {return class_index == j.class_index;}
};
/* if class_index > 0, then this is a "normal" example
   if class_index == 0, then:
     if x == -FLT_MAX then this is a 'shared' example
     if x > 0 then this is a label feature vector for (size_t)x
*/

struct label
{ v_array<wclass> costs;
};

void output_example(vw& all, example& ec);
extern label_parser cs_label;

bool is_test_label(label& ld);
bool example_is_test(example& ec);

void print_update(vw& all, bool is_test, example& ec, const v_array<example*> *ec_seq, bool multilabel, uint32_t prediction);
bool ec_is_example_header(example& ec);  // example headers look like "0:-1" or just "shared"
}
