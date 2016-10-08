/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD (revised)
license as described in the file LICENSE.
 */
#include <sstream>
#include <float.h>
#include "reductions.h"
#include "v_array.h"
using namespace std;
struct interact
{ unsigned char n1, n2;  //namespaces to interact
  features feat_store;
  vw *all;
  float n1_feat_sq;
  float total_sum_feat_sq;
  size_t num_features;
};

bool contains_valid_namespaces(features& f_src1, features& f_src2, interact& in)
{ // first feature must be 1 so we're sure that the anchor feature is present
  if (f_src1.size() == 0 || f_src2.size() == 0)
    return false;

  if (f_src1.values[0] != 1)
  { cerr << "Namespace '" << (char)in.n1 << "' misses anchor feature with value 1";
    return false;
  }

  if (f_src2.values[0] != 1)
  { cerr << "Namespace '" << (char)in.n2 << "' misses anchor feature with value 1";
    return false;
  }

  return true;
}

void multiply(features& f_dest, features& f_src2, interact& in)
{ f_dest.erase();
  features& f_src1 = in.feat_store;
  vw* all = in.all;
  uint64_t weight_mask = all->reg.weight_mask;
  uint64_t base_id1 = f_src1.indicies[0] & weight_mask;
  uint64_t base_id2 = f_src2.indicies[0] & weight_mask;

  f_dest.push_back(f_src1.values[0]*f_src2.values[0], f_src1.indicies[0]);

  uint64_t prev_id1 = 0;
  uint64_t prev_id2 = 0;

  for(size_t i1 = 1, i2 = 1; i1 < f_src1.size() && i2 < f_src2.size();)
  { // calculating the relative offset from the namespace offset used to match features
    uint64_t cur_id1 = (uint64_t)(((f_src1.indicies[i1] & weight_mask) - base_id1) & weight_mask);
    uint64_t cur_id2 = (uint64_t)(((f_src2.indicies[i2] & weight_mask) - base_id2) & weight_mask);

    // checking for sorting requirement
    if (cur_id1 < prev_id1)
    { cout << "interact features are out of order: " << cur_id1 << " > " << prev_id1 << ". Skipping features." << endl;
      return;
    }

    if (cur_id2 < prev_id2)
    { cout << "interact features are out of order: " << cur_id2 << " > " << prev_id2 << ". Skipping features." << endl;
      return;
    }

    if(cur_id1 == cur_id2)
      { f_dest.push_back(f_src1.values[i1]*f_src2.values[i2], f_src1.indicies[i1]);
        i1++;
        i2++;
      }
    else if (cur_id1 < cur_id2)
      i1++;
    else
      i2++;
  }
}

template <bool is_learn, bool print_all>
void predict_or_learn(interact& in, LEARNER::base_learner& base, example& ec)
{ features& f1 = ec.feature_space[in.n1];
  features& f2 = ec.feature_space[in.n2];

  if (!contains_valid_namespaces(f1, f2, in))
    { if (is_learn)
        base.learn(ec);
      else
        base.predict(ec);

      return;
    }

  in.num_features = ec.num_features;
  in.total_sum_feat_sq = ec.total_sum_feat_sq;
  ec.total_sum_feat_sq -= f1.sum_feat_sq;
  ec.total_sum_feat_sq -= f2.sum_feat_sq;
  ec.num_features -= f1.size();
  ec.num_features -= f2.size();

  in.feat_store.deep_copy_from(f1);

  multiply(f1, f2, in);
  ec.total_sum_feat_sq += f1.sum_feat_sq;
  ec.num_features += f1.size();

  /*for(uint64_t i = 0;i < f1.size();i++)
    cout<<f1[i].weight_index<<":"<<f1[i].x<<" ";
    cout<<endl;*/

  // remove 2nd namespace
  int n2_i = -1;
  for (size_t i = 0; i < ec.indices.size(); i++)
  { if (ec.indices[i] == in.n2)
    { n2_i = (int)i;
      memmove(&ec.indices[n2_i], &ec.indices[n2_i + 1], sizeof(unsigned char) * (ec.indices.size() - n2_i - 1));
      ec.indices.decr();
      break;
    }
  }

  base.predict(ec);
  if (is_learn)
    base.learn(ec);

  // re-insert namespace into the right position
  ec.indices.incr();
  memmove(&ec.indices[n2_i + 1], &ec.indices[n2_i], sizeof(unsigned char) * (ec.indices.size() - n2_i - 1));
  ec.indices[n2_i] = in.n2;

  f1.deep_copy_from(in.feat_store);
  ec.total_sum_feat_sq = in.total_sum_feat_sq;
  ec.num_features = in.num_features;
}

void finish(interact& in) { in.feat_store.delete_v(); }

LEARNER::base_learner* interact_setup(vw& all)
{ if(missing_option<string, true>(all, "interact", "Put weights on feature products from namespaces <n1> and <n2>"))
    return nullptr;
  string s = all.vm["interact"].as<string>();
  if(s.length() != 2)
    { cerr<<"Need two namespace arguments to interact: " << s << " won't do EXITING\n";
    return nullptr;
    }

  interact& data = calloc_or_throw<interact>();

  data.n1 = (unsigned char) s[0];
  data.n2 = (unsigned char) s[1];
  if (!all.quiet)
    cerr <<"Interacting namespaces "<<data.n1<<" and "<<data.n2<<endl;
  data.all = &all;

  LEARNER::learner<interact>* l;
  l = &LEARNER::init_learner(&data, setup_base(all), predict_or_learn<true, true>, predict_or_learn<false, true>, 1);

  l->set_finish(finish);
  return make_base(*l);
}
