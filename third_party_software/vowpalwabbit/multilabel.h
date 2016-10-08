/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD
license as described in the file LICENSE.
 */
#pragma once
#include "label_parser.h"

struct example;
struct vw;

namespace MULTILABEL
{
struct labels
{ v_array<uint32_t> label_v;
};

void output_example(vw& all, example& ec);
extern label_parser multilabel;

bool example_is_test(example& ec);

void print_update(vw& all, bool is_test, example& ec, const v_array<example*> *ec_seq);
void print_multilabel(int f, labels& mls, v_array<char>& tag);
}
