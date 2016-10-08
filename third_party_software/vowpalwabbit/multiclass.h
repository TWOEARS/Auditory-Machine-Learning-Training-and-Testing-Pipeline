/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD
license as described in the file LICENSE.
 */
#pragma once
#include "label_parser.h"

struct example;
struct vw;

namespace MULTICLASS
{
struct label_t
{ uint32_t label;
  float weight;
};

extern label_parser mc_label;

void print_update_with_probability(vw& all, example &ec, uint32_t prediction);

void finish_example(vw& all, example& ec);

template <class T> void finish_example(vw& all, T&, example& ec) { finish_example(all, ec); }

inline bool label_is_test(label_t* ld)
{ return ld->label == (uint32_t)-1; }
}
