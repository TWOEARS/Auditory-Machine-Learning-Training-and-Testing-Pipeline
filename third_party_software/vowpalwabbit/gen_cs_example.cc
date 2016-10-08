/*
  Copyright (c) by respective owners including Yahoo!, Microsoft, and
  individual contributors. All rights reserved.  Released under a BSD (revised)
  license as described in the file LICENSE.
*/
#include <float.h>

#include "vw.h"
#include "reductions.h"
#include "cb_algs.h"
#include "vw_exception.h"
#include "gen_cs_example.h"

namespace GEN_CS {
using namespace LEARNER;
  using namespace CB_ALGS;
using namespace CB;

inline bool observed_cost(cb_class* cl)
{ //cost observed for this action if it has non zero probability and cost != FLT_MAX
  return (cl != nullptr && cl->cost != FLT_MAX && cl->probability > .0);
}

cb_class* get_observed_cost(CB::label& ld)
{
  for (auto& cl : ld.costs)
    if (observed_cost(&cl))
      return &cl;
  return nullptr;
}

  void gen_cs_example_dr(COST_SENSITIVE::label& pred_scores, CB::cb_class& known_cost, v_array<example*> examples, v_array<COST_SENSITIVE::label>& cs_labels, base_learner* scorer)
{ //size_t mysize = examples.size();
  if (cs_labels.size() < examples.size())
  { cs_labels.resize(examples.size());
    cs_labels.end() = cs_labels.end_array;
  }

  pred_scores.costs.erase();

  bool shared = CB::ec_is_example_header(*examples[0]);
  int startK = 0;
  if (shared) startK = 1;

  for (size_t i = 0; i < examples.size(); i++)
  { if (example_is_newline_not_header(*examples[i])) continue;

    COST_SENSITIVE::wclass wc;
    wc.class_index = 0;

    if (known_cost.action + startK == i)
    { int known_index = known_cost.action;
      known_cost.action = 0;
      //get cost prediction for this label
      // num_actions should be 1 effectively.
      // my get_cost_pred function will use 1 for 'index-1+base'
      wc.x = CB_ALGS::get_cost_pred<true>(scorer, &(known_cost), *(examples[i]), 0, 2);
      known_cost.action = known_index;
    }
    else
      wc.x = CB_ALGS::get_cost_pred<true>(scorer, nullptr, *(examples[i]), 0, 2);

    if (shared)
      wc.class_index = (uint32_t)i - 1;
    else
      wc.class_index = (uint32_t)i;
    pred_scores.costs.push_back(wc); // done

    //add correction if we observed cost for this action and regressor is wrong
    if (known_cost.probability != -1 && known_cost.action + startK == i)
    { wc.x += (known_cost.cost - wc.x) / known_cost.probability;
    }
    cs_labels[i].costs.erase();
    cs_labels[i].costs.push_back(wc);
  }
  COST_SENSITIVE::wclass wc;
  wc.class_index = 0;
  wc.x = FLT_MAX;
  cs_labels[examples.size() - 1].costs.erase();
  cs_labels[examples.size() - 1].costs.push_back(wc); //trigger end of multiline example.

  if (shared)//take care of shared examples
  { cs_labels[0].costs[0].class_index = 0;
    cs_labels[0].costs[0].x = -FLT_MAX;
  }
}

//Multiline version
void gen_cs_example_ips(v_array<example*> examples, v_array<COST_SENSITIVE::label>& cs_labels)
{ if (cs_labels.size() < examples.size())
  { cs_labels.resize(examples.size());
    // TODO: introduce operation
    cs_labels.end() = cs_labels.end_array;
  }
  bool shared = CB::ec_is_example_header(*examples[0]);
  for (uint32_t i = 0; i < examples.size(); i++)
  { CB::label ld = examples[i]->l.cb;

    COST_SENSITIVE::wclass wc = {0.,i,0.,0.};
    if (shared && i > 0)
      wc.class_index = (uint32_t)i-1;
    if (ld.costs.size() == 1 && ld.costs[0].cost != FLT_MAX)
      wc.x = ld.costs[0].cost / ld.costs[0].probability;
    cs_labels[i].costs.erase();
    cs_labels[i].costs.push_back(wc);
  }
  cs_labels[examples.size() - 1].costs[0].x = FLT_MAX; //trigger end of multiline example.

  if (shared)//take care of shared examples
  { cs_labels[0].costs[0].class_index = 0;
    cs_labels[0].costs[0].x = -FLT_MAX;
  }
}

//single line version
void gen_cs_example_ips(cb_to_cs& c, CB::label& ld, COST_SENSITIVE::label& cs_ld)
{ //this implements the inverse propensity score method, where cost are importance weighted by the probability of the chosen action
  //generate cost-sensitive example
  cs_ld.costs.erase();
  if (ld.costs.size() == 1 && !is_test_label(ld))   //this is a typical example where we can perform all actions
    { //in this case generate cost-sensitive example with all actions
      for (uint32_t i = 1; i <= c.num_actions; i++)
	{
	  COST_SENSITIVE::wclass wc = {0.,i,0.,0.};
	  if (c.known_cost != nullptr && i == c.known_cost->action)
	    {
	      wc.x = c.known_cost->cost / c.known_cost->probability; //use importance weighted cost for observed action, 0 otherwise
	      //ips can be thought as the doubly robust method with a fixed regressor that predicts 0 costs for everything
	      //update the loss of this regressor
	      c.nb_ex_regressors++;
	      c.avg_loss_regressors += (1.0f / c.nb_ex_regressors)*((c.known_cost->cost)*(c.known_cost->cost) - c.avg_loss_regressors);
	      c.last_pred_reg = 0;
	      c.last_correct_cost = c.known_cost->cost;
	    }

	  cs_ld.costs.push_back(wc);
	}
    }
  else   //this is an example where we can only perform a subset of the actions
    { //in this case generate cost-sensitive example with only allowed actions
      for (auto& cl : ld.costs)
	{
	  COST_SENSITIVE::wclass wc = {0., cl.action, 0., 0.};
	  if (c.known_cost != nullptr && cl.action == c.known_cost->action)
	    {
	      wc.x = c.known_cost->cost / c.known_cost->probability; //use importance weighted cost for observed action, 0 otherwise

	      //ips can be thought as the doubly robust method with a fixed regressor that predicts 0 costs for everything
	      //update the loss of this regressor
	      c.nb_ex_regressors++;
	      c.avg_loss_regressors += (1.0f / c.nb_ex_regressors)*((c.known_cost->cost)*(c.known_cost->cost) - c.avg_loss_regressors);
	      c.last_pred_reg = 0;
	      c.last_correct_cost = c.known_cost->cost;
	    }

	  cs_ld.costs.push_back(wc);
	}
    }
}

  void gen_cs_example_MTR(uint64_t& action_sum, uint64_t& event_sum, uint32_t& mtr_example, v_array<example*>& ec_seq, v_array<example*>& mtr_ec_seq, v_array<COST_SENSITIVE::label>& mtr_cs_labels)
{ mtr_ec_seq.erase();
  bool shared = CB::ec_is_example_header(*(ec_seq[0]));
  action_sum += ec_seq.size()-2; //-1 for shared -1 for end example
  if (!shared)
    action_sum += 1;
  event_sum++;
  uint32_t keep_count = 0;

  for (size_t i = 0; i < ec_seq.size(); i++)
  { CB::label ld = ec_seq[i]->l.cb;

    COST_SENSITIVE::wclass wc = {0, 0};

    bool keep_example = false;
    if (shared && i == 0)
    { wc.x = -FLT_MAX;
      keep_example = true;
    }
    else if (ld.costs.size() == 1 && ld.costs[0].cost != FLT_MAX)
    { wc.x = ld.costs[0].cost;
      mtr_example = (uint32_t)i;
      keep_example = true;
    }

    else if (i == ec_seq.size() - 1)
    { wc.x = FLT_MAX; //trigger end of multiline example.
      keep_example = true;
    }

    if (keep_example)
    { mtr_ec_seq.push_back(ec_seq[i]);
      mtr_cs_labels[keep_count].costs.erase();
      mtr_cs_labels[keep_count++].costs.push_back(wc);
    }
  }
}
}
