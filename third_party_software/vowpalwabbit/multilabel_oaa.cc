/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD (revised)
license as described in the file LICENSE.
 */
#include <sstream>
#include <float.h>
#include "reductions.h"
#include "vw.h"

using namespace std;

struct multi_oaa
{ size_t k;
};

template <bool is_learn>
void predict_or_learn(multi_oaa& o, LEARNER::base_learner& base, example& ec)
{ MULTILABEL::labels multilabels = ec.l.multilabels;
  MULTILABEL::labels preds = ec.pred.multilabels;
  preds.label_v.erase();

  ec.l.simple = {FLT_MAX, 1.f, 0.f};
  uint32_t multilabel_index = 0;
  for (uint32_t i = 0; i < o.k; i++)
  { if (is_learn)
    { ec.l.simple.label = -1.f;
      if (multilabels.label_v.size() > multilabel_index
          && multilabels.label_v[multilabel_index] == i)
      { ec.l.simple.label = 1.f;
        multilabel_index++;
      }
      base.learn(ec, i);
    }
    else
      base.predict(ec, i);
    if (ec.pred.scalar > 0.)
      preds.label_v.push_back(i);
  }
  if (is_learn && multilabel_index < multilabels.label_v.size())
    cout << "label " << multilabels.label_v[multilabel_index] << " is not in {0," << o.k-1 << "} This won't work right." << endl;

  ec.pred.multilabels = preds;
  ec.l.multilabels = multilabels;
}

void finish_example(vw& all, multi_oaa&, example& ec)
{ MULTILABEL::output_example(all, ec);
  VW::finish_example(all, &ec);
}

LEARNER::base_learner* multilabel_oaa_setup(vw& all)
{ if (missing_option<size_t, true>(all, "multilabel_oaa", "One-against-all multilabel with <k> labels"))
    return nullptr;

  multi_oaa& data = calloc_or_throw<multi_oaa>();
  data.k = all.vm["multilabel_oaa"].as<size_t>();

  LEARNER::learner<multi_oaa>& l = LEARNER::init_learner(&data, setup_base(all), predict_or_learn<true>,
                                   predict_or_learn<false>, data.k);
  l.set_finish_example(finish_example);
  all.p->lp = MULTILABEL::multilabel;
  all.delete_prediction = MULTILABEL::multilabel.delete_label;

  return make_base(l);
}
