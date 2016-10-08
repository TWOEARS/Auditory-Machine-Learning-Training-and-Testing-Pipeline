/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD (revised)
license as described in the file LICENSE.
 */
#include <float.h>
#include <string.h>
#include <math.h>
#include "vw.h"
#include "rand48.h"
#include "reductions.h"
#include "gd.h" // for GD::foreach_feature
#include "search_sequencetask.h"
#include "search_multiclasstask.h"
#include "search_dep_parser.h"
#include "search_entityrelationtask.h"
#include "search_hooktask.h"
#include "search_graph.h"
#include "search_meta.h"
#include "csoaa.h"
#include "active.h"
#include "label_dictionary.h"
#include "vw_exception.h"

using namespace LEARNER;
using namespace std;
namespace CS = COST_SENSITIVE;
namespace MC = MULTICLASS;

#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))

namespace Search
{
search_task* all_tasks[] =
{ &SequenceTask::task,
  &SequenceSpanTask::task,
  &SequenceTaskCostToGo::task,
  &ArgmaxTask::task,
  &SequenceTask_DemoLDF::task,
  &MulticlassTask::task,
  &DepParserTask::task,
  &EntityRelationTask::task,
  &HookTask::task,
  &GraphTask::task,
  nullptr
};   // must nullptr terminate!

search_metatask* all_metatasks[] =
{ &DebugMT::metatask,
  &SelectiveBranchingMT::metatask,
  nullptr
};   // must nullptr terminate!

const bool PRINT_UPDATE_EVERY_EXAMPLE =0;
const bool PRINT_UPDATE_EVERY_PASS =0;
const bool PRINT_CLOCK_TIME =0;

string   neighbor_feature_space("neighbor");
string   condition_feature_space("search_condition");

uint32_t AUTO_CONDITION_FEATURES = 1, AUTO_HAMMING_LOSS = 2, EXAMPLES_DONT_CHANGE = 4, IS_LDF = 8, NO_CACHING = 16, ACTION_COSTS = 32;
enum SearchState { INITIALIZE, INIT_TEST, INIT_TRAIN, LEARN, GET_TRUTH_STRING };
enum RollMethod { POLICY, ORACLE, MIX_PER_STATE, MIX_PER_ROLL, NO_ROLLOUT };

// a data structure to hold conditioning information
struct prediction
{ ptag    me;     // the id of the current prediction (the one being memoized)
  size_t  cnt;    // how many variables are we conditioning on?
  ptag*   tags;   // which variables are they?
  action* acts;   // and which actions were taken at each?
  uint32_t hash;  // a hash of the above
};

// parameters for auto-conditioning
struct auto_condition_settings
{ size_t max_bias_ngram_length;   // add a "bias" feature for each ngram up to and including this length. eg., if it's 1, then you get a single feature for each conditional
  size_t max_quad_ngram_length;   // add bias *times* input features for each ngram up to and including this length
  float  feature_value;           // how much weight should the conditional features get?
  bool   use_passthrough_repr;    // should we ask lower-level reductions for their internal state?
};

struct scored_action
{ action a;  // the action
  float  s;  // the predicted cost of this action
  //v_array<feature> repr;
  scored_action(action _a = (action)-1, float _s = 0) : a(_a), s(_s) {} // , repr(v_init<feature>()) {}
  //scored_action(action _a, float _s, v_array<feature>& _repr) : a(_a), s(_s), repr(_repr) {}
  //scored_action() { a = (action)-1; s = 0.; }
};
std::ostream& operator << (std::ostream& os, const scored_action& x) { os << x.a << ':' << x.s; return os; }

struct action_repr
{ action a;
  features *repr;
  action_repr(action _a, features* _repr) : a(_a)
  { if(_repr!=nullptr)
    { repr = new features(); 
      repr->deep_copy_from(*_repr);
    }
    else
      repr = nullptr;
  }
  action_repr(action _a) : a(_a), repr(nullptr) {}
};

struct action_cache
{ float min_cost;
  action k;
  bool is_opt;
  float cost;
  action_cache(float _min_cost, action _k, bool _is_opt, float _cost) : min_cost(_min_cost), k(_k), is_opt(_is_opt), cost(_cost) {}
};
std::ostream& operator << (std::ostream& os, const action_cache& x) { os << x.k << ':' << x.cost; if (x.is_opt) os << '*'; return os; }

struct search_private
{ vw* all;

  bool auto_condition_features;  // do you want us to automatically add conditioning features?
  bool auto_hamming_loss;        // if you're just optimizing hamming loss, we can do it for you!
  bool examples_dont_change;     // set to true if you don't do any internal example munging
  bool is_ldf;                   // user declared ldf
  bool use_action_costs;         // task promises to define per-action rollout-by-ref costs

  v_array<int32_t> neighbor_features; // ugly encoding of neighbor feature requirements
  auto_condition_settings acset; // settings for auto-conditioning
  size_t history_length;         // value of --search_history_length, used by some tasks, default 1

  size_t A;                      // total number of actions, [1..A]; 0 means ldf
  size_t num_learners;           // total number of learners;
  bool cb_learner;               // do contextual bandit learning on action (was "! rollout_all_actions" which was confusing)
  SearchState state;             // current state of learning
  size_t learn_learner_id;       // we allow user to use different learners for different states
  int mix_per_roll_policy;       // for MIX_PER_ROLL, we need to choose a policy to use; this is where it's stored (-2 means "not selected yet")
  bool no_caching;               // turn off caching
  size_t rollout_num_steps;      // how many calls of "loss" before we stop really predicting on rollouts and switch to oracle (0 means "infinite")
  bool linear_ordering;          // insist that examples are generated in linear order (rather that the default hoopla permutation)
  bool (*label_is_test)(polylabel&); // tell me if the label data from an example is test

  size_t t;                      // current search step
  size_t T;                      // length of root trajectory
  v_array<example> learn_ec_copy;// copy of example(s) at learn_t
  example* learn_ec_ref;         // reference to example at learn_t, when there's no example munging
  size_t learn_ec_ref_cnt;       // how many are there (for LDF mode only; otherwise 1)
  v_array<ptag> learn_condition_on;      // a copy of the tags used for conditioning at the training position
  v_array<action_repr>learn_condition_on_act;// the actions taken
  v_array<char>   learn_condition_on_names;// the names of the actions
  v_array<action> learn_allowed_actions; // which actions were allowed at training time?
  v_array<action_repr> ptag_to_action;// tag to action mapping for conditioning
  vector<action> test_action_sequence; // if test-mode was run, what was the corresponding action sequence; it's a vector cuz we might expose it to the library
  action learn_oracle_action;    // store an oracle action for debugging purposes
  features last_action_repr;

  polylabel* allowed_actions_cache;

  size_t loss_declared_cnt;      // how many times did run declare any loss (implicitly or explicitly)?
  v_array<scored_action> train_trajectory; // the training trajectory
  size_t learn_t;                // what time step are we learning on?
  size_t learn_a_idx;            // what action index are we trying?
  bool done_with_all_actions;    // set to true when there are no more learn_a_idx to go

  float test_loss;               // loss incurred when run INIT_TEST
  float learn_loss;              // loss incurred when run LEARN
  float train_loss;              // loss incurred when run INIT_TRAIN

  bool last_example_was_newline; // used so we know when a block of examples has passed
  bool hit_new_pass;             // have we hit a new pass?
  bool force_oracle;             // insist on using the oracle to make predictions
  float perturb_oracle;          // with this probability, choose a random action instead of oracle action

  // if we're printing to stderr we need to remember if we've printed the header yet
  // (i.e., we do this if we're driving)
  bool printed_output_header;

  // various strings for different search states
  bool should_produce_string;
  stringstream *pred_string;
  stringstream *truth_string;
  stringstream *bad_string_stream;

  // parameters controlling interpolation
  float  beta;                   // interpolation rate
  float  alpha;                  // parameter used to adapt beta for dagger (see above comment), should be in (0,1)

  RollMethod rollout_method;
  RollMethod rollin_method;
  float subsample_timesteps;     // train at every time step or just a (random) subset?
  bool xv;           // train three separate policies -- two for providing examples to the other and a third training on the union (which will be used at test time -- TODO)

  bool   allow_current_policy;   // should the current policy be used for training? true for dagger
  bool   adaptive_beta;          // used to implement dagger-like algorithms. if true, beta = 1-(1-alpha)^n after n updates, and policy is mixed with oracle as \pi' = (1-beta)\pi^* + beta \pi
  size_t passes_per_policy;      // if we're not in dagger-mode, then we need to know how many passes to train a policy

  uint32_t current_policy;       // what policy are we training right now?

  // various statistics for reporting
  size_t num_features;
  uint32_t total_number_of_policies;
  size_t read_example_last_id;
  size_t passes_since_new_policy;
  size_t read_example_last_pass;
  size_t total_examples_generated;
  size_t total_predictions_made;
  size_t total_cache_hits;

  vector<example*> ec_seq;  // the collected examples
  v_hashmap<unsigned char*, scored_action> cache_hash_map;

  // for foreach_feature temporary storage for conditioning
  uint64_t dat_new_feature_idx;
  example* dat_new_feature_ec;
  stringstream dat_new_feature_audit_ss;
  size_t dat_new_feature_namespace;
  string* dat_new_feature_feature_space;
  float dat_new_feature_value;

  // to reduce memory allocation
  string rawOutputString;
  stringstream* rawOutputStringStream;
  CS::label ldf_test_label;
  v_array<action_repr> condition_on_actions;
  v_array<size_t> timesteps;
  polylabel learn_losses;
  polylabel gte_label;
  v_array< pair<float,size_t> > active_uncertainty;

  LEARNER::base_learner* base_learner;
  clock_t start_clock_time;

  example* empty_example;
  CS::label empty_cs_label;

  search_task* task;    // your task!
  search_metatask* metatask;  // your (optional) metatask
  BaseTask* metaoverride;
  size_t meta_t;  // the metatask has it's own notion of time. meta_t+t, during a single run, is the way to think about the "real" decision step but this really only matters for caching purposes
  v_array< v_array<action_cache>* > memo_foreach_action; // when foreach_action is on, we need to cache TRAIN trajectory actions for LEARN
};

string   audit_feature_space("conditional");
uint64_t conditional_constant = 8290743;

void clear_memo_foreach_action(search_private& priv)
{ for (size_t i=0; i<priv.memo_foreach_action.size(); i++)
    if (priv.memo_foreach_action[i])
    { priv.memo_foreach_action[i]->delete_v();
      delete priv.memo_foreach_action[i];
    }
  priv.memo_foreach_action.erase();
}

inline bool need_memo_foreach_action(search_private& priv)
{ return
    (priv.state == INIT_TRAIN) &&
    (priv.metatask) &&
    (priv.metaoverride); // &&
  //        (priv.metaoverride->_foreach_action || priv.metaoverride->_post_prediction);
}

int random_policy(search_private& priv, bool allow_current, bool allow_optimal, bool advance_prng=true)
{ if (priv.beta >= 1)
  { if (allow_current) return (int)priv.current_policy;
    if (priv.current_policy > 0) return (((int)priv.current_policy)-1);
    if (allow_optimal) return -1;
    std::cerr << "internal error (bug): no valid policies to choose from!  defaulting to current" << std::endl;
    return (int)priv.current_policy;
  }

  int num_valid_policies = (int)priv.current_policy + allow_optimal + allow_current;
  int pid = -1;

  if (num_valid_policies == 0)
  { std::cerr << "internal error (bug): no valid policies to choose from!  defaulting to current" << std::endl;
    return (int)priv.current_policy;
  }
  else if (num_valid_policies == 1)
    pid = 0;
  else if (num_valid_policies == 2)
    pid = (advance_prng ? frand48() : frand48_noadvance()) >= priv.beta;
  else
  { // SPEEDUP this up in the case that beta is small!
    float r = (advance_prng ? frand48() : frand48_noadvance());
    pid = 0;

    if (r > priv.beta)
    { r -= priv.beta;
      while ((r > 0) && (pid < num_valid_policies-1))
      { pid ++;
        r -= priv.beta * powf(1.f - priv.beta, (float)pid);
      }
    }
  }
  // figure out which policy pid refers to
  if (allow_optimal && (pid == num_valid_policies-1))
    return -1; // this is the optimal policy

  pid = (int)priv.current_policy - pid;
  if (!allow_current)
    pid--;

  return pid;
}

// for two-fold cross validation, we double the number of learners
// and send examples to one or the other depending on the xor of
// (is_training) and (example_id % 2)
int select_learner(search_private& priv, int policy, size_t learner_id, bool is_training, bool is_local)
{ if (policy<0) return policy;  // optimal policy
  else
  { if (priv.xv)
    { learner_id *= 3;
      if (! is_local)
        learner_id += 1 + (size_t)( is_training ^ (priv.all->sd->example_number % 2 == 1) );
    }
    int p = (int) (policy*priv.num_learners+learner_id);
    return p;
  }
}


bool should_print_update(vw& all, bool hit_new_pass=false)
{ //uncomment to print out final loss after all examples processed
  //commented for now so that outputs matches make test

  if (PRINT_UPDATE_EVERY_EXAMPLE) return true;
  if (PRINT_UPDATE_EVERY_PASS && hit_new_pass) return true;
  return (all.sd->weighted_examples >= all.sd->dump_interval) && !all.quiet && !all.bfgs;
}


bool might_print_update(vw& all)
{ // basically do should_print_update but check me and the next
  // example because of off-by-ones

  if (PRINT_UPDATE_EVERY_EXAMPLE) return true;
  if (PRINT_UPDATE_EVERY_PASS) return true;  // SPEEDUP: make this better
  return (all.sd->weighted_examples + 1. >= all.sd->dump_interval) && !all.quiet && !all.bfgs;
}

bool must_run_test(vw&all, vector<example*>ec, bool is_test_ex)
{ return
    (all.final_prediction_sink.size() > 0) ||   // if we have to produce output, we need to run this
    might_print_update(all) ||                  // if we have to print and update to stderr
    (all.raw_prediction > 0) ||                 // we need raw predictions
    ((!all.vw_is_main) && (is_test_ex)) ||      // library needs predictions
    // or:
    //   it's not quiet AND
    //     current_pass == 0
    //     OR holdout is off
    //     OR it's a test example
    ( (! all.quiet || ! all.vw_is_main) &&  // had to disable this because of library mode!
      (! is_test_ex) &&
      ( all.holdout_set_off ||                    // no holdout
        ec[0]->test_only ||
        (all.current_pass == 0)                   // we need error rates for progressive cost
      ) )
    ;
}

void clear_seq(vw&all, search_private& priv)
{ if (priv.ec_seq.size() > 0)
    for (size_t i=0; i < priv.ec_seq.size(); i++)
      VW::finish_example(all, priv.ec_seq[i]);
  priv.ec_seq.clear();
}

float safediv(float a,float b) { if (b == 0.f) return 0.f; else return (a/b); }

void to_short_string(string in, size_t max_len, char*out)
{ for (size_t i=0; i<max_len; i++)
    out[i] = ((i >= in.length()) || (in[i] == '\n') || (in[i] == '\t')) ? ' ' : in[i];

  if (in.length() > max_len)
  { out[max_len-2] = '.';
    out[max_len-1] = '.';
  }
  out[max_len] = 0;
}

void number_to_natural(size_t big, char* c)
{ if      (big > 9999999999) sprintf(c, "%dg", (int)(big / 1000000000));
  else if (big >    9999999) sprintf(c, "%dm", (int)(big /    1000000));
  else if (big >       9999) sprintf(c, "%dk", (int)(big /       1000));
  else                       sprintf(c, "%d",  (int)(big));
}

void print_update(search_private& priv)
{ vw& all = *priv.all;
  if (!priv.printed_output_header && !all.quiet)
  { const char * header_fmt = "%-10s %-10s %8s%24s %22s %5s %5s  %7s  %7s  %7s  %-8s\n";
    fprintf(stderr, header_fmt, "average", "since", "instance", "current true",  "current predicted", "cur",  "cur", "predic", "cache", "examples", "");
    fprintf(stderr, header_fmt, "loss",    "last",  "counter",  "output prefix",  "output prefix",    "pass", "pol", "made",    "hits",  "gener", "beta");
    std::cerr.precision(5);
    priv.printed_output_header = true;
  }

  if (!should_print_update(all, priv.hit_new_pass))
    return;

  char true_label[21];
  char pred_label[21];
  to_short_string(priv.truth_string->str(), 20, true_label);
  to_short_string(priv.pred_string->str() , 20, pred_label);

  float avg_loss = 0.;
  float avg_loss_since = 0.;
  bool use_heldout_loss = (!all.holdout_set_off && all.current_pass >= 1) && (all.sd->weighted_holdout_examples > 0);
  if (use_heldout_loss)
  { avg_loss       = safediv((float)all.sd->holdout_sum_loss, (float)all.sd->weighted_holdout_examples);
    avg_loss_since = safediv((float)all.sd->holdout_sum_loss_since_last_dump, (float)all.sd->weighted_holdout_examples_since_last_dump);

    all.sd->weighted_holdout_examples_since_last_dump = 0;
    all.sd->holdout_sum_loss_since_last_dump = 0.0;
  }
  else
  { avg_loss       = safediv((float)all.sd->sum_loss, (float)all.sd->weighted_examples);
    avg_loss_since = safediv((float)all.sd->sum_loss_since_last_dump, (float) (all.sd->weighted_examples - all.sd->old_weighted_examples));
  }

  char inst_cntr[9];  number_to_natural((size_t)all.sd->example_number, inst_cntr);
  char total_pred[8]; number_to_natural(priv.total_predictions_made, total_pred);
  char total_cach[8]; number_to_natural(priv.total_cache_hits, total_cach);
  char total_exge[8]; number_to_natural(priv.total_examples_generated, total_exge);

  fprintf(stderr, "%-10.6f %-10.6f %8s  [%s] [%s] %5d %5d  %7s  %7s  %7s  %-8f",
          avg_loss,
          avg_loss_since,
          inst_cntr,
          true_label,
          pred_label,
          (int)priv.read_example_last_pass,
          (int)priv.current_policy,
          total_pred,
          total_cach,
          total_exge,
          priv.beta);

  if (PRINT_CLOCK_TIME)
    { size_t num_sec = (size_t)(((float)(clock() - priv.start_clock_time)) / CLOCKS_PER_SEC);
      cerr <<" "<< num_sec << "sec";
    }

  if (use_heldout_loss)
    fprintf(stderr, " h");

  fprintf(stderr, "\n");
  fflush(stderr);
  all.sd->update_dump_interval(all.progress_add, all.progress_arg);
}

void add_new_feature(search_private& priv, float val, uint64_t idx)
{ uint64_t mask = priv.all->reg.weight_mask;
  size_t ss   = priv.all->reg.stride_shift;
  uint64_t idx2 = ((idx & mask) >> ss) & mask;
  features& fs = priv.dat_new_feature_ec->feature_space[priv.dat_new_feature_namespace];
  fs.push_back(val * priv.dat_new_feature_value, ((priv.dat_new_feature_idx + idx2) << ss) );
  cdbg << "adding: " << fs.indicies.last() << ':' << fs.values.last() << endl;
  if (priv.all->audit)
  {
    stringstream temp;
    temp << "fid=" << ((idx & mask) >> ss) << "_" << priv.dat_new_feature_audit_ss.str();
    fs.space_names.push_back(audit_strings_ptr(new audit_strings(*priv.dat_new_feature_feature_space, temp.str())));
  }
}

void del_features_in_top_namespace(search_private& priv, example& ec, size_t ns)
{ if ((ec.indices.size() == 0) || (ec.indices.last() != ns))
  { if (ec.indices.size() == 0)
      { THROW("internal error (bug): expecting top namespace to be '" << ns << "' but it was empty"); }
    else
      { THROW("internal error (bug): expecting top namespace to be '" << ns << "' but it was " << (size_t)ec.indices.last()); }
  }
  features& fs = ec.feature_space[ns];
  ec.indices.decr();
  ec.num_features -= fs.size();
  ec.total_sum_feat_sq -= fs.sum_feat_sq;
  fs.erase();
}

void add_neighbor_features(search_private& priv)
{ vw& all = *priv.all;
  if (priv.neighbor_features.size() == 0) return;

  for (size_t n=0; n<priv.ec_seq.size(); n++)    // iterate over every example in the sequence
  { example& me = *priv.ec_seq[n];
    for (size_t n_id=0; n_id < priv.neighbor_features.size(); n_id++)
    { int32_t offset = priv.neighbor_features[n_id] >> 24;
      size_t  ns     = priv.neighbor_features[n_id] & 0xFF;

      priv.dat_new_feature_ec = &me;
      priv.dat_new_feature_value = 1.;
      priv.dat_new_feature_idx = priv.neighbor_features[n_id] * 13748127;
      priv.dat_new_feature_namespace = neighbor_namespace;
      if (priv.all->audit)
      { priv.dat_new_feature_feature_space = &neighbor_feature_space;
        priv.dat_new_feature_audit_ss.str("");
        priv.dat_new_feature_audit_ss << '@' << ((offset > 0) ? '+' : '-') << (char)(abs(offset) + '0');
        if (ns != ' ') priv.dat_new_feature_audit_ss << (char)ns;
      }

      //cerr << "n=" << n << " offset=" << offset << endl;
      if ((offset < 0) && (n < (uint64_t)(-offset))) // add <s> feature
        add_new_feature(priv, 1., 925871901 << priv.all->reg.stride_shift);
      else if (n + offset >= priv.ec_seq.size()) // add </s> feature
        add_new_feature(priv, 1., 3824917 << priv.all->reg.stride_shift);
      else   // this is actually a neighbor
      { example& other = *priv.ec_seq[n + offset];
        GD::foreach_feature<search_private,add_new_feature>(all.reg.weight_vector, all.reg.weight_mask, other.feature_space[ns], priv, me.ft_offset);
      }
    }

    features& fs = me.feature_space[neighbor_namespace];
    size_t sz = fs.size();
    if ((sz > 0) && (fs.sum_feat_sq > 0.))
      { me.indices.push_back(neighbor_namespace);
        me.total_sum_feat_sq += fs.sum_feat_sq;
        me.num_features += sz;
      }
    else
      fs.erase();
  }
}

void del_neighbor_features(search_private& priv)
{ if (priv.neighbor_features.size() == 0) return;
  for (size_t n=0; n<priv.ec_seq.size(); n++)
    del_features_in_top_namespace(priv, *priv.ec_seq[n], neighbor_namespace);
}

void reset_search_structure(search_private& priv)
{ // NOTE: make sure do NOT reset priv.learn_a_idx
  priv.t = 0;
  priv.meta_t = 0;
  priv.loss_declared_cnt = 0;
  priv.done_with_all_actions = false;
  priv.test_loss = 0.;
  priv.learn_loss = 0.;
  priv.train_loss = 0.;
  priv.num_features = 0;
  priv.should_produce_string = false;
  priv.mix_per_roll_policy = -2;
  if (priv.adaptive_beta)
  { float x = - log1pf(- priv.alpha) * (float)priv.total_examples_generated;
    static const float log_of_2 = (float)0.6931471805599453;
    priv.beta = (x <= log_of_2) ? -expm1f(-x) : (1-expf(-x)); // numerical stability
    //float priv_beta = 1.f - powf(1.f - priv.alpha, (float)priv.total_examples_generated);
    //assert( fabs(priv_beta - priv.beta) < 1e-2 );
    if (priv.beta > 1) priv.beta = 1;
  }
  for (Search::action_repr& ar : priv.ptag_to_action)
  { if(ar.repr !=nullptr)
    { ar.repr->delete_v();
      delete ar.repr;
    }
  }
  priv.ptag_to_action.erase();

  if (! priv.cb_learner)   // was: if rollout_all_actions
  { uint32_t seed = (uint32_t)(priv.read_example_last_id * 147483 + 4831921) * 2147483647;
    msrand48(seed);
  }
}

void search_declare_loss(search_private& priv, float loss)
{ priv.loss_declared_cnt++;
  switch (priv.state)
  { case INIT_TEST:  priv.test_loss  += loss; break;
    case INIT_TRAIN: priv.train_loss += loss; break;
    case LEARN:
      if ((priv.rollout_num_steps == 0) || (priv.loss_declared_cnt <= priv.rollout_num_steps))
      { priv.learn_loss += loss;
        cdbg << "priv.learn_loss += " << loss << " (now = " << priv.learn_loss << ")" << endl;
      }
      break;
    default: break; // get rid of the warning about missing cases (danger!)
  }
}


template<class T> void cdbg_print_array(string str, v_array<T>& A) { cdbg << str << " = ["; for (size_t i=0; i<A.size(); i++) cdbg << " " << A[i]; cdbg << " ]" << endl; }
template<class T> void cerr_print_array(string str, v_array<T>& A) { std::cerr << str << " = ["; for (size_t i=0; i<A.size(); i++) std::cerr << " " << A[i]; std::cerr << " ]" << endl; }


size_t random(size_t max) { return (size_t)(frand48() * (float)max); }
template<class T> bool array_contains(T target, const T*A, size_t n)
{ if (A == nullptr) return false;
  for (size_t i=0; i<n; i++)
    if (A[i] == target) return true;
  return false;
}

// priv.learn_condition_on_act or priv.condition_on_actions
void add_example_conditioning(search_private& priv, example& ec, size_t condition_on_cnt, const char* condition_on_names, action_repr* condition_on_actions)
{ if (condition_on_cnt == 0) return;

  uint64_t extra_offset=0;
  if (priv.is_ldf)
    if (ec.l.cs.costs.size() > 0)
      extra_offset = 3849017 * ec.l.cs.costs[0].class_index;

  size_t I = condition_on_cnt;
  size_t N = max(priv.acset.max_bias_ngram_length, priv.acset.max_quad_ngram_length);
  for (size_t i=0; i<I; i++)   // position in conditioning
  { uint64_t fid = 71933 + 8491087 * extra_offset;
    if (priv.all->audit)
    { priv.dat_new_feature_audit_ss.str("");
      priv.dat_new_feature_audit_ss.clear();
      priv.dat_new_feature_feature_space = &condition_feature_space;
    }

    for (size_t n=0; n<N; n++)   // length of ngram
    { if (i + n >= I) break; // no more ngrams
      // we're going to add features for the ngram condition_on_actions[i .. i+N]
      char name = condition_on_names[i+n];
      fid = fid * 328901 + 71933 * ((condition_on_actions[i+n].a + 349101) * (name + 38490137));

      priv.dat_new_feature_ec  = &ec;
      priv.dat_new_feature_idx = fid * quadratic_constant;
      priv.dat_new_feature_namespace = conditioning_namespace;
      priv.dat_new_feature_value = priv.acset.feature_value;

      if (priv.all->audit)
      { if (n > 0) priv.dat_new_feature_audit_ss << ',';
        if ((33 <= name) && (name <= 126)) priv.dat_new_feature_audit_ss << name;
        else priv.dat_new_feature_audit_ss << '#' << (int)name;
        priv.dat_new_feature_audit_ss << '=' << condition_on_actions[i+n].a;
      }

      // add the single bias feature
      if (n < priv.acset.max_bias_ngram_length)
        add_new_feature(priv, 1., 4398201 << priv.all->reg.stride_shift);

      // add the quadratic features
      if (n < priv.acset.max_quad_ngram_length)
        GD::foreach_feature<search_private,uint64_t,add_new_feature>(*priv.all, ec, priv);
    }
  }

  if (priv.acset.use_passthrough_repr)
  { cdbg << "BEGIN adding passthrough features" << endl;
    for (size_t i=0; i<I; i++)
    { if (condition_on_actions[i].repr == nullptr) continue;
      features& fs = *(condition_on_actions[i].repr);
      char name = condition_on_names[i];
      for (size_t k=0; k<fs.size(); k++)
        if ((fs.values[k] > 1e-10) || (fs.values[k] < -1e-10))
        { uint64_t fid = 84913 + 48371803 * (extra_offset + 8392817 * name) + 840137 * (4891 + fs.indicies[k]);
          if (priv.all->audit)
          { priv.dat_new_feature_audit_ss.str("");
            priv.dat_new_feature_audit_ss.clear();
            priv.dat_new_feature_audit_ss << "passthrough_repr_" << i << '_' << k;
          }
          
          priv.dat_new_feature_ec  = &ec;
          priv.dat_new_feature_idx = fid;
          priv.dat_new_feature_namespace = conditioning_namespace;
          priv.dat_new_feature_value = fs.values[k];
          add_new_feature(priv, 1., 4398201 << priv.all->reg.stride_shift);
        }
    }
    cdbg << "END adding passthrough features" << endl;
  }

  features& con_fs = ec.feature_space[conditioning_namespace];
  if ((con_fs.size() > 0) && (con_fs.sum_feat_sq > 0.))
    { ec.indices.push_back(conditioning_namespace);
      ec.total_sum_feat_sq += con_fs.sum_feat_sq;
      ec.num_features += con_fs.size();
    }
  else
    con_fs.erase();
}

void del_example_conditioning(search_private& priv, example& ec)
{ if ((ec.indices.size() > 0) && (ec.indices.last() == conditioning_namespace))
    del_features_in_top_namespace(priv, ec, conditioning_namespace);
}

inline size_t cs_get_costs_size(bool isCB, polylabel& ld)
{ return isCB ? ld.cb.costs.size()
         : ld.cs.costs.size();
}

inline uint32_t cs_get_cost_index(bool isCB, polylabel& ld, size_t k)
{ return isCB ? ld.cb.costs[k].action
         : ld.cs.costs[k].class_index;
}

inline float cs_get_cost_partial_prediction(bool isCB, polylabel& ld, size_t k)
{ return isCB ? ld.cb.costs[k].partial_prediction
         : ld.cs.costs[k].partial_prediction;
}

inline void cs_set_cost_loss(bool isCB, polylabel& ld, size_t k, float val)
{ if (isCB) ld.cb.costs[k].cost = val;
  else      ld.cs.costs[k].x    = val;
}

inline void cs_costs_erase(bool isCB, polylabel& ld)
{ if (isCB) ld.cb.costs.erase();
  else      ld.cs.costs.erase();
}

inline void cs_costs_resize(bool isCB, polylabel& ld, size_t new_size)
{ if (isCB) ld.cb.costs.resize(new_size);
  else      ld.cs.costs.resize(new_size);
}

inline void cs_cost_push_back(bool isCB, polylabel& ld, uint32_t index, float value)
{ if (isCB) { CB::cb_class cost = { value, index, 0., 0. }; ld.cb.costs.push_back(cost); }
  else      { CS::wclass   cost = { value, index, 0., 0. }; ld.cs.costs.push_back(cost); }
}

polylabel& allowed_actions_to_ld(search_private& priv, size_t ec_cnt, const action* allowed_actions, size_t allowed_actions_cnt, const float* allowed_actions_cost)
{ bool isCB = priv.cb_learner;
  polylabel& ld = *priv.allowed_actions_cache;
  uint32_t num_costs = (uint32_t)cs_get_costs_size(isCB, ld);

  if (priv.is_ldf)    // LDF version easier
  { if (num_costs > ec_cnt)
      cs_costs_resize(isCB, ld, ec_cnt);
    else if (num_costs < ec_cnt)
      for (action k = num_costs; k < ec_cnt; k++)
        cs_cost_push_back(isCB, ld, k, FLT_MAX);

  }
  else if (priv.use_action_costs)
  { // TODO: Weight
    if (allowed_actions == nullptr)
    { if (cs_get_costs_size(isCB, ld) != priv.A)
      { cs_costs_erase(isCB, ld);
        for (action k=0; k<priv.A; k++)
          cs_cost_push_back(isCB, ld, k+1, 0.);
      }
      for (action k=0; k<priv.A; k++)
        cs_set_cost_loss(isCB, ld, k, allowed_actions_cost[k]);
    }
    else     // manually specified actions
    { cs_costs_erase(isCB, ld);
      for (action k=0; k<allowed_actions_cnt; k++)
        cs_cost_push_back(isCB, ld, allowed_actions[k], allowed_actions_cost[k]);
    }
  }
  else     // non-LDF version, no action costs
  { if ((allowed_actions == nullptr) || (allowed_actions_cnt == 0))   // any action is allowed
    { if (num_costs != priv.A)    // if there are already A-many actions, they must be the right ones, unless the user did something stupid like putting duplicate allowed_actions...
      { cs_costs_erase(isCB, ld);
        for (action k = 0; k < priv.A; k++)
          cs_cost_push_back(isCB, ld, k+1, FLT_MAX);  //+1 because MC is 1-based
      }
    }
    else     // we need to peek at allowed_actions
    { cs_costs_erase(isCB, ld);
      for (size_t i = 0; i < allowed_actions_cnt; i++)
        cs_cost_push_back(isCB, ld, allowed_actions[i], FLT_MAX);
    }
  }

  return ld;
}

void allowed_actions_to_label(search_private& priv, size_t ec_cnt, const action* allowed_actions, size_t allowed_actions_cnt, const float* allowed_actions_cost, const action* oracle_actions, size_t oracle_actions_cnt, polylabel& lab)
{ bool isCB = priv.cb_learner;
  if (priv.is_ldf)   // LDF version easier
  { cs_costs_erase(isCB, lab);
    for (action k=0; k<ec_cnt; k++)
      cs_cost_push_back(isCB, lab, k, array_contains<action>(k, oracle_actions, oracle_actions_cnt) ? 0.f : 1.f );
    //cerr << "lab = ["; for (size_t i=0; i<lab.cs.costs.size(); i++) cdbg << ' ' << lab.cs.costs[i].class_index << ':' << lab.cs.costs[i].x; cdbg << " ]" << endl;
  }
  else if (priv.use_action_costs)
  { // TODO: Weight
    if (allowed_actions == nullptr)
    { if (cs_get_costs_size(isCB, lab) != priv.A)
      { cs_costs_erase(isCB, lab);
        for (action k=0; k<priv.A; k++)
          cs_cost_push_back(isCB, lab, k+1, 0.);
      }
      for (action k=0; k<priv.A; k++)
        cs_set_cost_loss(isCB, lab, k, allowed_actions_cost[k]);
    }
    else     // manually specified actions
    { cs_costs_erase(isCB, lab);
      for (action k=0; k<allowed_actions_cnt; k++)
        cs_cost_push_back(isCB, lab, allowed_actions[k], allowed_actions_cost[k]);
    }
  }
  else     // non-LDF, no action costs
  { if ((allowed_actions == nullptr) || (allowed_actions_cnt == 0))   // any action is allowed
    { bool set_to_one = false;
      if (cs_get_costs_size(isCB, lab) != priv.A)
      { cs_costs_erase(isCB, lab);
        for (action k=0; k<priv.A; k++)
          cs_cost_push_back(isCB, lab, k+1, 1.);
        set_to_one = true;
      }
      //cerr << "lab = ["; for (size_t i=0; i<lab.cs.costs.size(); i++) cdbg << ' ' << lab.cs.costs[i].class_index << ':' << lab.cs.costs[i].x; cdbg << " ]" << endl;
      if (oracle_actions_cnt <= 1)   // common case to speed up
      { if (! set_to_one)
          for (action k=0; k<priv.A; k++)
            cs_set_cost_loss(isCB, lab, k, 1.);
        if (oracle_actions_cnt == 1)
          cs_set_cost_loss(isCB, lab, oracle_actions[0]-1, 0.);
      }
      else
      { for (action k=0; k<priv.A; k++)
          cs_set_cost_loss(isCB, lab, k, array_contains<action>(k+1, oracle_actions, oracle_actions_cnt) ? 0.f : 1.f);
      }
    }
    else     // only some actions are allowed
    { cs_costs_erase(isCB, lab);
      float w = 1.; // array_contains<action>(3, oracle_actions, oracle_actions_cnt) ? 5.f : 1.f;
      for (size_t i=0; i<allowed_actions_cnt; i++)
      { action k = allowed_actions[i];
        cs_cost_push_back(isCB, lab, k, (array_contains<action>(k, oracle_actions, oracle_actions_cnt)) ? 0.f : w); // 1.f );
      }
    }
  }
}

template<class T>
void ensure_size(v_array<T>& A, size_t sz)
{ if ((size_t)(A.end_array - A.begin()) < sz)
    A.resize(sz*2+1);
  A.end() = A.begin() + sz;
}

template<class T> void push_at(v_array<T>& v, T item, size_t pos)
{ if (v.size() > pos)
    v.begin()[pos] = item;
  else
  { if (v.end_array > v.begin() + pos)
    { // there's enough memory, just not enough filler
      memset(v.end(), 0, sizeof(T) * (pos - v.size()));
      v.begin()[pos] = item;
      v.end() = v.begin() + pos + 1;
    }
    else
    { // there's not enough memory
      v.resize(2 * pos + 3);
      v.begin()[pos] = item;
      v.end() = v.begin() + pos + 1;
    }
  }
}

action choose_oracle_action(search_private& priv, size_t ec_cnt, const action* oracle_actions, size_t oracle_actions_cnt, const action* allowed_actions, size_t allowed_actions_cnt, const float* allowed_actions_cost)
{ action a = (action)-1;
  if (priv.use_action_costs)
  { size_t K = (allowed_actions == nullptr) ? priv.A : allowed_actions_cnt;
    cdbg << "costs = ["; for (size_t k=0; k<K; k++) cdbg << ' ' << allowed_actions_cost[k]; cdbg << " ]" << endl;
    float min_cost = FLT_MAX;
    for (size_t k=0; k<K; k++)
      min_cost = min(min_cost, allowed_actions_cost[k]);
    cdbg << "min_cost = " << min_cost;
    if (min_cost < FLT_MAX)
    { size_t count = 0;
      for (size_t k=0; k<K; k++)
        if (allowed_actions_cost[k] <= min_cost)
        { cdbg << ", hit @ " << k;
          count++;
          if ((count == 1) || (frand48() < 1./(float)count))
          { a = (allowed_actions == nullptr) ? (uint32_t)(k+1) : allowed_actions[k];
            cdbg << "***";
          }
        }
    }
    cdbg << endl;
  }

  if (a == (action)-1)
  { if ((priv.perturb_oracle > 0.) && (priv.state == INIT_TRAIN) && (frand48() < priv.perturb_oracle))
      oracle_actions_cnt = 0;
    a = ( oracle_actions_cnt > 0) ?  oracle_actions[random(oracle_actions_cnt )] :
        (allowed_actions_cnt > 0) ? allowed_actions[random(allowed_actions_cnt)] :
        priv.is_ldf ? (action)random(ec_cnt) :
        (action)(1 + random(priv.A));
  }
  cdbg << "choose_oracle_action from oracle_actions = ["; for (size_t i=0; i<oracle_actions_cnt; i++) cdbg << " " << oracle_actions[i]; cdbg << " ], ret=" << a << endl;
  if (need_memo_foreach_action(priv) && (priv.state == INIT_TRAIN))
  { v_array<action_cache>* this_cache = new v_array<action_cache>();
    *this_cache = v_init<action_cache>();
    // TODO we don't really need to construct this polylabel
    polylabel l = allowed_actions_to_ld(priv, 1, allowed_actions, allowed_actions_cnt, allowed_actions_cost);
    size_t K = cs_get_costs_size(priv.cb_learner, l);
    for (size_t k = 0; k < K; k++)
    { action cl = cs_get_cost_index(priv.cb_learner, l, k);
      float cost = array_contains(cl, oracle_actions, oracle_actions_cnt) ? 0.f : 1.f;
      this_cache->push_back( action_cache(0., cl, cl==a, cost) );
    }
    assert( priv.memo_foreach_action.size() == priv.meta_t + priv.t - 1 );
    priv.memo_foreach_action.push_back(this_cache);
    cdbg << "memo_foreach_action[" << priv.meta_t + priv.t -1 << "] = " << this_cache << " from oracle" << endl;
  }
  return a;
}

action single_prediction_notLDF(search_private& priv, example& ec, int policy, const action* allowed_actions, size_t allowed_actions_cnt, const float* allowed_actions_cost, float& a_cost, action override_action)    // if override_action != -1, then we return it as the action and a_cost is set to the appropriate cost for that action
{ vw& all = *priv.all;
  polylabel old_label = ec.l;
  bool need_partial_predictions = need_memo_foreach_action(priv) || (priv.metaoverride && priv.metaoverride->_foreach_action) || (override_action != (action)-1);
  if ((allowed_actions_cnt > 0) || need_partial_predictions)
    ec.l = allowed_actions_to_ld(priv, 1, allowed_actions, allowed_actions_cnt, allowed_actions_cost);
  else
    ec.l.cs = priv.empty_cs_label;

  cdbg << "allowed_actions_cnt=" << allowed_actions_cnt << ", ec.l = ["; for (size_t i=0; i<ec.l.cs.costs.size(); i++) cdbg << ' ' << ec.l.cs.costs[i].class_index << ':' << ec.l.cs.costs[i].x; cdbg << " ]" << endl;

  priv.base_learner->predict(ec, policy);
  uint32_t act = ec.pred.multiclass;
  cdbg << "a=" << act << " from"; if (allowed_actions) { for (size_t ii=0; ii<allowed_actions_cnt; ii++) cdbg << ' ' << allowed_actions[ii]; } cdbg << endl;
  a_cost = ec.partial_prediction;
  cdbg << "a_cost = " << a_cost << endl;

  if (override_action != (action)-1)
    act = override_action;

  if (need_partial_predictions)
  { size_t K = cs_get_costs_size(priv.cb_learner, ec.l);
    float min_cost = FLT_MAX;
    for (size_t k = 0; k < K; k++)
    { float cost = cs_get_cost_partial_prediction(priv.cb_learner, ec.l, k);
      if (cost < min_cost) min_cost = cost;
    }
    v_array<action_cache>* this_cache = nullptr;
    if (need_memo_foreach_action(priv) && (override_action == (action)-1))
    { this_cache = new v_array<action_cache>();
      *this_cache = v_init<action_cache>();
    }
    for (size_t k = 0; k < K; k++)
    { action cl = cs_get_cost_index(priv.cb_learner, ec.l, k);
      float cost = cs_get_cost_partial_prediction(priv.cb_learner, ec.l, k);
      if (priv.metaoverride && priv.metaoverride->_foreach_action)
        priv.metaoverride->_foreach_action(*priv.metaoverride->sch, priv.t-1, min_cost, cl, cl==act, cost);
      if (override_action == cl)
        a_cost = cost;
      if (this_cache)
        this_cache->push_back( action_cache(min_cost, cl, cl==act, cost) );
    }
    if (this_cache)
    {
      assert( priv.memo_foreach_action.size() == priv.meta_t + priv.t - 1 );
      priv.memo_foreach_action.push_back(this_cache);
      cdbg << "memo_foreach_action[" << priv.meta_t + priv.t -1 << "] = " << this_cache << endl;
    }
  }

  if ((priv.state == INIT_TRAIN) && (priv.subsample_timesteps <= -1))   // active learning
  { size_t K = cs_get_costs_size(priv.cb_learner, ec.l);
    float min_cost = FLT_MAX, min_cost2 = FLT_MAX;
    for (size_t k = 0; k < K; k++)
    { float cost = cs_get_cost_partial_prediction(priv.cb_learner, ec.l, k);
      if (cost < min_cost) { min_cost2 = min_cost; min_cost = cost; }
      else if (cost < min_cost2) { min_cost2 = cost; }
    }
    if (min_cost2 < FLT_MAX)
      priv.active_uncertainty.push_back( make_pair(min_cost2 - min_cost, priv.t+priv.meta_t) );
  }

  // generate raw predictions if necessary
  if ((priv.state == INIT_TEST) && (all.raw_prediction > 0))
  { priv.rawOutputStringStream->str("");
    for (size_t k = 0; k < cs_get_costs_size(priv.cb_learner, ec.l); k++)
    { if (k > 0) (*priv.rawOutputStringStream) << ' ';
      (*priv.rawOutputStringStream) << cs_get_cost_index(priv.cb_learner, ec.l, k) << ':' << cs_get_cost_partial_prediction(priv.cb_learner, ec.l, k);
    }
    all.print_text(all.raw_prediction, priv.rawOutputStringStream->str(), ec.tag);
  }

  ec.l = old_label;

  priv.total_predictions_made++;
  priv.num_features += ec.num_features;

  return act;
}

action single_prediction_LDF(search_private& priv, example* ecs, size_t ec_cnt, int policy, float& a_cost, action override_action)    // if override_action != -1, then we return it as the action and a_cost is set to the appropriate cost for that action
{ bool need_partial_predictions = need_memo_foreach_action(priv) || (priv.metaoverride && priv.metaoverride->_foreach_action) || (override_action != (action)-1);

  CS::cs_label.default_label(&priv.ldf_test_label);
  CS::wclass wc = { 0., 1, 0., 0. };
  priv.ldf_test_label.costs.push_back(wc);

  // keep track of best (aka chosen) action
  float  best_prediction = 0.;
  action best_action = 0;

  size_t start_K = (priv.is_ldf && COST_SENSITIVE::ec_is_example_header(ecs[0])) ? 1 : 0;

  v_array<action_cache>* this_cache = nullptr;
  if (need_partial_predictions)
  { this_cache = new v_array<action_cache>();
    *this_cache = v_init<action_cache>();
  }

  for (action a= (uint32_t)start_K; a<ec_cnt; a++)
  { cdbg << "== single_prediction_LDF a=" << a << "==" << endl;
    if (start_K > 0)
      LabelDict::add_example_namespaces_from_example(ecs[a], ecs[0]);

    polylabel old_label = ecs[a].l;
    ecs[a].l.cs = priv.ldf_test_label;
    priv.base_learner->predict(ecs[a], policy);

    priv.empty_example->in_use = true;
    priv.base_learner->predict(*priv.empty_example);

    cdbg << "partial_prediction[" << a << "] = " << ecs[a].partial_prediction << endl;

    if (override_action != (action)-1)
    { if (a == override_action)
        a_cost = ecs[a].partial_prediction;
    }
    else if ((a == start_K) || (ecs[a].partial_prediction < best_prediction))
    { best_prediction = ecs[a].partial_prediction;
      best_action     = a;
      a_cost          = best_prediction;
    }
    if (this_cache)
      this_cache->push_back( action_cache(0., a, false, ecs[a].partial_prediction) );

    priv.num_features += ecs[a].num_features;
    ecs[a].l = old_label;
    if (start_K > 0)
      LabelDict::del_example_namespaces_from_example(ecs[a], ecs[0]);
  }
  if (override_action != (action)-1)
    best_action = override_action;
  else
    a_cost = best_prediction;

  if (this_cache)
  { for (size_t i=0; i<this_cache->size(); i++)
    { action_cache& ac = this_cache->get(i);
      ac.min_cost = a_cost;
      ac.is_opt = (ac.k == best_action);
      if (priv.metaoverride && priv.metaoverride->_foreach_action)
        priv.metaoverride->_foreach_action(*priv.metaoverride->sch, priv.t-1, ac.min_cost, ac.k, ac.is_opt, ac.cost);
    }
    if (need_memo_foreach_action(priv) && (override_action == (action)-1))
      priv.memo_foreach_action.push_back(this_cache);
    else
    { this_cache->delete_v();
      delete this_cache;
    }
  }

  // TODO: generate raw predictions if necessary

  priv.total_predictions_made++;
  return best_action;
}

int choose_policy(search_private& priv, bool advance_prng=true)
{ RollMethod method = (priv.state == INIT_TEST ) ? POLICY :
                      (priv.state == LEARN     ) ? priv.rollout_method :
                      (priv.state == INIT_TRAIN) ? priv.rollin_method :
                      NO_ROLLOUT;   // this should never happen
  switch (method)
  { case POLICY:
      return random_policy(priv, priv.allow_current_policy || (priv.state == INIT_TEST), false, advance_prng);

    case ORACLE:
      return -1;

    case MIX_PER_STATE:
      return random_policy(priv, priv.allow_current_policy, true, advance_prng);

    case MIX_PER_ROLL:
      if (priv.mix_per_roll_policy == -2) // then we have to choose one!
        priv.mix_per_roll_policy = random_policy(priv, priv.allow_current_policy, true, advance_prng);
      return priv.mix_per_roll_policy;

    case NO_ROLLOUT:
    default:
      THROW("internal error (bug): trying to rollin or rollout with NO_ROLLOUT");
  }
}

bool cached_item_equivalent(unsigned char*& A, unsigned char*& B)
{ size_t sz_A = *A;
  size_t sz_B = *B;
  if (sz_A != sz_B) return false;
  return memcmp(A, B, sz_A) == 0;
}

void free_key(unsigned char* mem, scored_action) { free(mem); } // sa.repr.delete_v(); }
void clear_cache_hash_map(search_private& priv)
{ priv.cache_hash_map.iter(free_key);
  priv.cache_hash_map.clear();
}

// returns true if found and do_store is false. if do_store is true, always returns true.
bool cached_action_store_or_find(search_private& priv, ptag mytag, const ptag* condition_on, const char* condition_on_names, action_repr* condition_on_actions, size_t condition_on_cnt, int policy, size_t learner_id, action &a, bool do_store, float& a_cost)
{ if (priv.no_caching) return do_store;
  if (mytag == 0) return do_store; // don't attempt to cache when tag is zero

  size_t sz  = sizeof(size_t) + sizeof(ptag) + sizeof(int) + sizeof(size_t) + sizeof(size_t) + condition_on_cnt * (sizeof(ptag) + sizeof(action) + sizeof(char));
  if (sz % 4 != 0)
    sz += 4 - (sz % 4); // make sure sz aligns to 4 so that uniform_hash does the right thing

  unsigned char* item = calloc_or_throw<unsigned char>(sz);
  unsigned char* here = item;
  *here = (unsigned char)sz; here += sizeof(size_t);
  *here = mytag;             here += sizeof(ptag);
  *here = policy;            here += sizeof(int);
  *here = (unsigned char)learner_id;        here += sizeof(size_t);
  *here = (unsigned char)condition_on_cnt;  here += sizeof(size_t);
  for (size_t i=0; i<condition_on_cnt; i++)
  { *here = condition_on[i];             here += sizeof(ptag);
    *here = condition_on_actions[i].a;   here += sizeof(action);
    *here = condition_on_names[i];       here += sizeof(char);  // SPEEDUP: should we align this at 4?
  }
  uint64_t hash = uniform_hash(item, sz, 3419);

  if (do_store)
  { priv.cache_hash_map.put(item, hash, scored_action(a, a_cost));
    return true;
  }
  else     // its a find
  { scored_action sa = priv.cache_hash_map.get(item, hash);
    a = sa.a;
    a_cost = sa.s;
    free(item);
    return a != (action)-1;
  }
}

void generate_training_example(search_private& priv, polylabel& losses, float weight, bool add_conditioning=true, float min_loss=FLT_MAX)    // min_loss = FLT_MAX means "please compute it for me as the actual min"; any other value means to use this
{ // should we really subtract out min-loss?
  //float min_loss = FLT_MAX;
  if (priv.cb_learner)
  { if (min_loss == FLT_MAX)
      for (size_t i=0; i<losses.cb.costs.size(); i++) min_loss = MIN(min_loss, losses.cb.costs[i].cost);
    for (size_t i=0; i<losses.cb.costs.size(); i++) losses.cb.costs[i].cost = losses.cb.costs[i].cost - min_loss;
  }
  else
  { if (min_loss == FLT_MAX)
      for (size_t i=0; i<losses.cs.costs.size(); i++) min_loss = MIN(min_loss, losses.cs.costs[i].x);
    for (size_t i=0; i<losses.cs.costs.size(); i++) losses.cs.costs[i].x = (losses.cs.costs[i].x - min_loss) * weight;
  }
  //cdbg << "losses = ["; for (size_t i=0; i<losses.cs.costs.size(); i++) cdbg << ' ' << losses.cs.costs[i].class_index << ':' << losses.cs.costs[i].x; cdbg << " ], min_loss=" << min_loss << endl;

  if (!priv.is_ldf)     // not LDF
  { // since we're not LDF, it should be the case that ec_ref_cnt == 1
    // and learn_ec_ref[0] is a pointer to a single example
    assert(priv.learn_ec_ref_cnt == 1);
    assert(priv.learn_ec_ref != nullptr);

    example& ec = priv.learn_ec_ref[0];
    polylabel old_label = ec.l;
    ec.l = losses; // labels;
    if (add_conditioning) add_example_conditioning(priv, ec, priv.learn_condition_on.size(), priv.learn_condition_on_names.begin(), priv.learn_condition_on_act.begin());
    for (size_t is_local=0; is_local<= (size_t)priv.xv; is_local++)
    { int learner = select_learner(priv, priv.current_policy, priv.learn_learner_id, true, is_local > 0);
      ec.in_use = true;
      priv.base_learner->learn(ec, learner);
    }
    if (add_conditioning) del_example_conditioning(priv, ec);
    ec.l = old_label;
    priv.total_examples_generated++;
  }
  else                  // is  LDF
  { assert(cs_get_costs_size(priv.cb_learner, losses) == priv.learn_ec_ref_cnt);
    size_t start_K = (priv.is_ldf && COST_SENSITIVE::ec_is_example_header(priv.learn_ec_ref[0])) ? 1 : 0;

    // TODO: weight
    if (add_conditioning)
      for (action a= (uint32_t)start_K; a<priv.learn_ec_ref_cnt; a++)
      { example& ec = priv.learn_ec_ref[a];
        add_example_conditioning(priv, ec, priv.learn_condition_on.size(), priv.learn_condition_on_names.begin(), priv.learn_condition_on_act.begin());
      }

    for (size_t is_local=0; is_local<= (size_t)priv.xv; is_local++)
    { int learner = select_learner(priv, priv.current_policy, priv.learn_learner_id, true, is_local > 0);

      for (action a= (uint32_t)start_K; a<priv.learn_ec_ref_cnt; a++)
      { example& ec = priv.learn_ec_ref[a];

        CS::label& lab = ec.l.cs;
        if (lab.costs.size() == 0)
        { CS::wclass wc = { 0., a - (uint32_t)start_K, 0., 0. };
          lab.costs.push_back(wc);
        }
        lab.costs[0].x = losses.cs.costs[a-start_K].x;
        //cerr << "cost[" << a << "] = " << losses[a] << " - " << min_loss << " = " << lab.costs[0].x << endl;
        ec.in_use = true;
        priv.base_learner->learn(ec, learner);

        cdbg << "generate_training_example called learn on action a=" << a << ", costs.size=" << lab.costs.size() << " ec=" << &ec << endl;
        priv.total_examples_generated++;
      }

      priv.base_learner->learn(*priv.empty_example, learner);
      cdbg << "generate_training_example called learn on empty_example" << endl;
    }

    if (add_conditioning)
      for (action a= (uint32_t)start_K; a<priv.learn_ec_ref_cnt; a++)
      { example& ec = priv.learn_ec_ref[a];
        del_example_conditioning(priv, ec);
      }
  }
}

bool search_predictNeedsExample(search_private& priv)
{ // this is basically copied from the logic of search_predict()
  switch (priv.state)
  { case INITIALIZE: return false;
    case GET_TRUTH_STRING: return false;
    case INIT_TEST:
      return true;
    case INIT_TRAIN:
      // TODO: do we need to do something here for metatasks?
      //if (priv.beam && (priv.t < priv.beam_actions.size()))
      //  return false;
      if (priv.rollout_method == NO_ROLLOUT) return true;
      break;
    case LEARN:
      if (priv.t+priv.meta_t < priv.learn_t) return false;  // TODO: in meta search mode with foreach feature we'll need it even here
      if (priv.t+priv.meta_t == priv.learn_t) return true;  // SPEEDUP: we really only need it on the last learn_a, but this is hard to know...
      // t > priv.learn_t
      if ((priv.rollout_num_steps > 0) && (priv.loss_declared_cnt >= priv.rollout_num_steps)) return false; // skipping
      break;
  }

  int pol = choose_policy(priv, false); // choose a policy but don't advance prng
  return (pol != -1);
}

void foreach_action_from_cache(search_private& priv, size_t t, action override_a=(action)-1)
{ cdbg << "foreach_action_from_cache: t=" << t << ", memo_foreach_action.size()=" << priv.memo_foreach_action.size() << ", override_a=" << override_a << endl;
  assert(t < priv.memo_foreach_action.size());
  v_array<action_cache>* cached = priv.memo_foreach_action[t];
  if (!cached) return; // the only way this can happen is if the metatask overrode this action
  cdbg << "memo_foreach_action size = " << cached->size() << endl;
  for (size_t id=0; id<cached->size(); id++)
  { action_cache& ac = cached->get(id);
    priv.metaoverride->_foreach_action(*priv.metaoverride->sch,
                                       t-priv.meta_t,
                                       ac.min_cost,
                                       ac.k,
                                       (override_a == (action)-1) ? ac.is_opt : (ac.k == override_a),
                                       ac.cost);
  }
}

// note: ec_cnt should be 1 if we are not LDF
action search_predict(search_private& priv, example* ecs, size_t ec_cnt, ptag mytag, const action* oracle_actions, size_t oracle_actions_cnt, const ptag* condition_on, const char* condition_on_names, const action* allowed_actions, size_t allowed_actions_cnt, const float* allowed_actions_cost, size_t learner_id, float& a_cost, float weight)
{ size_t condition_on_cnt = condition_on_names ? strlen(condition_on_names) : 0;
  size_t t = priv.t + priv.meta_t;
  priv.t++;

  // make sure parameters come in pairs correctly
  assert((oracle_actions  == nullptr) == (oracle_actions_cnt  == 0));
  assert((condition_on    == nullptr) == (condition_on_names  == nullptr));
  assert(((allowed_actions == nullptr) && (allowed_actions_cost == nullptr)) == (allowed_actions_cnt == 0));
  assert(priv.use_action_costs == (allowed_actions_cost != nullptr));
  if (allowed_actions_cost != nullptr) assert(oracle_actions == nullptr);

  // if we're just after the string, choose an oracle action
  if ((priv.state == GET_TRUTH_STRING) || priv.force_oracle)
  { action a = choose_oracle_action(priv, ec_cnt, oracle_actions, oracle_actions_cnt, allowed_actions, allowed_actions_cnt, allowed_actions_cost);
    //if (priv.metaoverride && priv.metaoverride->_post_prediction)
    //  priv.metaoverride->_post_prediction(*priv.metaoverride->sch, t-priv.meta_t, a, 0.);
    a_cost = 0.;
    return a;
  }

  // if we're in LEARN mode and before learn_t, return the train action
  if ((priv.state == LEARN) && (t < priv.learn_t))
  { assert(t < priv.train_trajectory.size());
    action a = priv.train_trajectory[t].a;
    a_cost   = priv.train_trajectory[t].s;
    cdbg << "LEARN " << t << " < priv.learn_t ==> a=" << a << ", a_cost=" << a_cost << endl;
    if (priv.metaoverride && priv.metaoverride->_foreach_action)
      foreach_action_from_cache(priv, t);
    if (priv.metaoverride && priv.metaoverride->_post_prediction)
      priv.metaoverride->_post_prediction(*priv.metaoverride->sch, t-priv.meta_t, a, a_cost);
    return a;
  }

  // for LDF, # of valid actions is ec_cnt; otherwise it's either allowed_actions_cnt or A
  size_t valid_action_cnt = priv.is_ldf ? ec_cnt :
                            (allowed_actions_cnt > 0) ? allowed_actions_cnt : priv.A;

  // if we're in LEARN mode and _at_ learn_t, then:
  //   - choose the next action
  //   - decide if we're done
  //   - if we are, then copy/mark the example ref
  if ((priv.state == LEARN) && (t == priv.learn_t))
  { action a = (action)priv.learn_a_idx;
    priv.loss_declared_cnt = 0;

    cdbg << "LEARN " << t << " = priv.learn_t ==> a=" << a << endl;

    priv.learn_a_idx++;

    // check to see if we're done with available actions
    if (priv.learn_a_idx >= valid_action_cnt)
    { priv.done_with_all_actions = true;
      priv.learn_learner_id = learner_id;

      // set reference or copy example(s)
      if (oracle_actions_cnt > 0) priv.learn_oracle_action = oracle_actions[0];
      priv.learn_ec_ref_cnt = ec_cnt;
      if (priv.examples_dont_change)
        priv.learn_ec_ref = ecs;
      else
      { size_t label_size = priv.is_ldf ? sizeof(CS::label) : sizeof(MC::label_t);
        void (*label_copy_fn)(void*,void*) = priv.is_ldf ? CS::cs_label.copy_label : nullptr;

        ensure_size(priv.learn_ec_copy, ec_cnt);
        for (size_t i=0; i<ec_cnt; i++)
          VW::copy_example_data(priv.all->audit, priv.learn_ec_copy.begin()+i, ecs+i, label_size, label_copy_fn);

        priv.learn_ec_ref = priv.learn_ec_copy.begin();
      }

      // copy conditioning stuff and allowed actions
      if (priv.auto_condition_features)
      { ensure_size(priv.learn_condition_on,     condition_on_cnt);
        ensure_size(priv.learn_condition_on_act, condition_on_cnt);

        priv.learn_condition_on.end() = priv.learn_condition_on.begin() + condition_on_cnt;   // allow .size() to be used in lieu of _cnt

        memcpy(priv.learn_condition_on.begin(), condition_on, condition_on_cnt * sizeof(ptag));

        for (size_t i=0; i<condition_on_cnt; i++)
          push_at(priv.learn_condition_on_act
                  , action_repr(((1 <= condition_on[i]) && (condition_on[i] < priv.ptag_to_action.size())) ? priv.ptag_to_action[condition_on[i]] : 0)
                  , i);

        if (condition_on_names == nullptr)
        { ensure_size(priv.learn_condition_on_names, 1);
          priv.learn_condition_on_names[0] = 0;
        }
        else
        { ensure_size(priv.learn_condition_on_names, strlen(condition_on_names)+1);
          strcpy(priv.learn_condition_on_names.begin(), condition_on_names);
        }
      }

      if (allowed_actions && (allowed_actions_cnt > 0))
      { ensure_size(priv.learn_allowed_actions, allowed_actions_cnt);
        memcpy(priv.learn_allowed_actions.begin(), allowed_actions, allowed_actions_cnt*sizeof(action));
        cdbg_print_array("in LEARN, learn_allowed_actions", priv.learn_allowed_actions);
      }
    }

    assert((allowed_actions_cnt == 0) || (a < allowed_actions_cnt));

    a_cost = 0.;
    action a_name = (allowed_actions && (allowed_actions_cnt > 0)) ? allowed_actions[a] : priv.is_ldf ? a : (a+1);
    if (priv.metaoverride && priv.metaoverride->_foreach_action)
    { foreach_action_from_cache(priv,t,a_name);
      if (priv.memo_foreach_action[t])
      { cdbg << "@ memo_foreach_action: t=" << t << ", a=" << a << ", cost=" << priv.memo_foreach_action[t]->get(a).cost << endl;
        a_cost = priv.memo_foreach_action[t]->get(a).cost;
      }
    }

    a = a_name;

    if (priv.metaoverride && priv.metaoverride->_post_prediction)
      priv.metaoverride->_post_prediction(*priv.metaoverride->sch, t-priv.meta_t, a, a_cost);
    return a;
  }

  if ((priv.state == LEARN) && (t > priv.learn_t) && (priv.rollout_num_steps > 0) && (priv.loss_declared_cnt >= priv.rollout_num_steps))
  { cdbg << "... skipping" << endl;
    action a = priv.is_ldf ? 0 : ((allowed_actions && (allowed_actions_cnt > 0)) ? allowed_actions[0] : 1);
    if (priv.metaoverride && priv.metaoverride->_post_prediction)
      priv.metaoverride->_post_prediction(*priv.metaoverride->sch, t-priv.meta_t, a, 0.);
    if (priv.metaoverride && priv.metaoverride->_foreach_action)
      foreach_action_from_cache(priv, t);
    a_cost = 0.;
    return a;
  }


  if ((priv.state == INIT_TRAIN) ||
      (priv.state == INIT_TEST) ||
      ((priv.state == LEARN) && (t > priv.learn_t)))
  { // we actually need to run the policy

    int policy = choose_policy(priv);
    action a = 0;

    cdbg << "executing policy " << policy << endl;

    bool gte_here = (priv.state == INIT_TRAIN) && (priv.rollout_method == NO_ROLLOUT) && ((oracle_actions_cnt > 0) || (priv.use_action_costs));
    a_cost = 0.;
    bool skip = false;

    if (priv.metaoverride && priv.metaoverride->_maybe_override_prediction && (priv.state != LEARN))   // if LEARN and t>learn_t,then we cannot allow overrides!
    { skip = priv.metaoverride->_maybe_override_prediction(*priv.metaoverride->sch, t-priv.meta_t, a, a_cost);
      cdbg << "maybe_override_prediction --> " << skip << ", a=" << a << ", a_cost=" << a_cost << endl;
      if (skip && need_memo_foreach_action(priv))
        priv.memo_foreach_action.push_back(nullptr);
    }

    if ((!skip) && (policy == -1))
      a = choose_oracle_action(priv, ec_cnt, oracle_actions, oracle_actions_cnt, allowed_actions, allowed_actions_cnt, allowed_actions_cost);   // TODO: we probably want to actually get costs for oracle actions???

    bool need_fea = (policy == -1) && priv.metaoverride && priv.metaoverride->_foreach_action;

    if ((policy >= 0) || gte_here || need_fea)   // the last case is we need to do foreach action
    { int learner = select_learner(priv, policy, learner_id, false, priv.state != INIT_TEST);

      ensure_size(priv.condition_on_actions, condition_on_cnt);
      for (size_t i=0; i<condition_on_cnt; i++)
        priv.condition_on_actions[i] = ((1 <= condition_on[i]) && (condition_on[i] < priv.ptag_to_action.size())) ? priv.ptag_to_action[condition_on[i]] : 0;

      bool not_test = priv.all->training && !ecs[0].test_only;

      if ((!skip) && (!need_fea) && not_test && cached_action_store_or_find(priv, mytag, condition_on, condition_on_names, priv.condition_on_actions.begin(), condition_on_cnt, policy, learner_id, a, false, a_cost))
        // if this succeeded, 'a' has the right action
        priv.total_cache_hits++;
      else   // we need to predict, and then cache, and maybe run foreach_action
      { size_t start_K = (priv.is_ldf && COST_SENSITIVE::ec_is_example_header(ecs[0])) ? 1 : 0;
        priv.last_action_repr.erase();
        if (priv.auto_condition_features)
          for (size_t n=start_K; n<ec_cnt; n++)
            add_example_conditioning(priv, ecs[n], condition_on_cnt, condition_on_names, priv.condition_on_actions.begin());

        if (((!skip) && (policy >= 0)) || need_fea)    // only make a prediction if we're going to use the output
        { if (priv.auto_condition_features && priv.acset.use_passthrough_repr)
          { if (priv.is_ldf)  { std::cerr << "search cannot use state representations in ldf mode" << endl; throw exception(); }
            if (ecs[0].passthrough) { std::cerr << "search cannot passthrough" << endl; throw exception(); }
            ecs[0].passthrough = &priv.last_action_repr;
          }
          a = priv.is_ldf ? single_prediction_LDF(priv, ecs, ec_cnt, learner, a_cost, need_fea ? a : (action)-1)
                : single_prediction_notLDF(priv, *ecs, learner, allowed_actions, allowed_actions_cnt, allowed_actions_cost, a_cost, need_fea ? a : (action)-1);

          cdbg << "passthrough = ["; for (size_t kk=0; kk<priv.last_action_repr.size(); kk++) cdbg << ' ' << priv.last_action_repr.indicies[kk] << ':' << priv.last_action_repr.values[kk]; cdbg << " ]" << endl;

          ecs[0].passthrough = nullptr;
        }

        if (need_fea)
        { // TODO this

        }

        if (gte_here)
        { cdbg << "INIT_TRAIN, NO_ROLLOUT, at least one oracle_actions, a=" << a << endl;
          // we can generate a training example _NOW_ because we're not doing rollouts
          //allowed_actions_to_losses(priv, ec_cnt, allowed_actions, allowed_actions_cnt, oracle_actions, oracle_actions_cnt, losses);
          allowed_actions_to_label(priv, ec_cnt, allowed_actions, allowed_actions_cnt, allowed_actions_cost, oracle_actions, oracle_actions_cnt, priv.gte_label);
          cdbg << "priv.gte_label = ["; for (size_t i=0; i<priv.gte_label.cs.costs.size(); i++) cdbg << ' ' << priv.gte_label.cs.costs[i].class_index << ':' << priv.gte_label.cs.costs[i].x; cdbg << " ]" << endl;

          priv.learn_ec_ref = ecs;
          priv.learn_ec_ref_cnt = ec_cnt;
          if (allowed_actions)
          { ensure_size(priv.learn_allowed_actions, allowed_actions_cnt); // TODO: do we really need this?
            memcpy(priv.learn_allowed_actions.begin(), allowed_actions, allowed_actions_cnt * sizeof(action));
          }
          size_t old_learner_id = priv.learn_learner_id;
          priv.learn_learner_id = learner_id;
          generate_training_example(priv, priv.gte_label, 1., false);  // this is false because the conditioning has already been added!
          priv.learn_learner_id = old_learner_id;
        }

        if (priv.auto_condition_features)
          for (size_t n=start_K; n<ec_cnt; n++)
            del_example_conditioning(priv, ecs[n]);

        if (not_test && (!skip))
          cached_action_store_or_find(priv, mytag, condition_on, condition_on_names, priv.condition_on_actions.begin(), condition_on_cnt, policy, learner_id, a, true, a_cost);
      }
    }

    if (priv.state == INIT_TRAIN)
      priv.train_trajectory.push_back( scored_action(a, a_cost) ); // note the action for future reference

    if (priv.metaoverride && priv.metaoverride->_post_prediction)
      priv.metaoverride->_post_prediction(*priv.metaoverride->sch, t-priv.meta_t, a, a_cost);

    return a;
  }

  THROW("error: predict called in unknown state");
}

inline bool cmp_size_t(const size_t a, const size_t b) { return a < b; }
inline bool cmp_size_t_pair(const pair<size_t,size_t>& a, const pair<size_t,size_t>& b) { return ((a.first == b.first) && (a.second < b.second)) || (a.first < b.first); }

inline size_t absdiff(size_t a, size_t b) { return (a < b) ? (b-a) : (a-b); }

void hoopla_permute(size_t* B, size_t* end)
{ // from Curtis IPL 2004, "Darts and hoopla board design"
  // first sort
  size_t N = end - B;
  std::sort(B, end, cmp_size_t);
  // make some temporary space
  size_t* A = calloc_or_throw<size_t>((N+1)*2);
  A[N  ] = B[0];    // arbitrarily choose the maximum in the middle
  A[N+1] = B[N-1];  // so the maximum goes next to it
  size_t lo  = N, hi = N+1;  // which parts of A have we filled in? [lo,hi]
  size_t i   = 0, j  = N-1;  // which parts of B have we already covered? [0,i] and [j,N-1]
  while (i+1 < j)
  { // there are four options depending on where things get placed
    size_t d1 = absdiff(A[lo], B[i+1]);  // put B[i+1] at the bottom
    size_t d2 = absdiff(A[lo], B[j-1]);  // put B[j-1] at the bottom
    size_t d3 = absdiff(A[hi], B[i+1]);  // put B[i+1] at the top
    size_t d4 = absdiff(A[hi], B[j-1]);  // put B[j-1] at the top
    size_t mx = max(max(d1,d2),max(d3,d4));
    if      (d1 >= mx) A[--lo] = B[++i];
    else if (d2 >= mx) A[--lo] = B[--j];
    else if (d3 >= mx) A[++hi] = B[++i];
    else               A[++hi] = B[--j];
  }
  // copy it back to B
  memcpy(B, A+lo, N*sizeof(size_t));
  // clean up
  free(A);
}


void get_training_timesteps(search_private& priv, v_array<size_t>& timesteps)
{ timesteps.erase();

  // if there's active learning, we need to
  if (priv.subsample_timesteps <= -1)
  { for (size_t i=0; i<priv.active_uncertainty.size(); i++)
      if (frand48() > priv.active_uncertainty[i].first)
        timesteps.push_back(priv.active_uncertainty[i].second - 1);
    /*
    float k = (float)priv.total_examples_generated;
    priv.ec_seq[t]->revert_weight = priv.all->loss->getRevertingWeight(priv.all->sd, priv.ec_seq[t].pred.scalar, priv.all->eta / powf(k, priv.all->power_t));
    float importance = query_decision(active_str, *priv.ec_seq[t], k);
    if (importance > 0.)
    timesteps.push_back(pair<size_t,size_t>(0,t));
    */
  }
  // if there's no subsampling to do, just return [0,T)
  else if (priv.subsample_timesteps <= 0)
    for (size_t t=0; t<priv.T; t++)
      timesteps.push_back(t);

  // if subsample in (0,1) then pick steps with that probability, but ensuring there's at least one!
  else if (priv.subsample_timesteps < 1)
  { for (size_t t=0; t<priv.T; t++)
      if (frand48() <= priv.subsample_timesteps)
        timesteps.push_back(t);

    if (timesteps.size() == 0) // ensure at least one
      timesteps.push_back((size_t)(frand48() * priv.T));
  }

  // finally, if subsample >= 1, then pick (int) that many uniformly at random without replacement; could use an LFSR but why? :P
  else
  { while ((timesteps.size() < (size_t)priv.subsample_timesteps) &&
           (timesteps.size() < priv.T))
    { size_t t = (size_t)(frand48() * (float)priv.T);
      if (! v_array_contains(timesteps, t))
        timesteps.push_back(t);
    }
    std::sort(timesteps.begin(), timesteps.end(), cmp_size_t);
  }

  if (! priv.linear_ordering)
    hoopla_permute(timesteps.begin(), timesteps.end());
}

struct final_item
{ v_array<scored_action> * prefix;
  string str;
  float total_cost;
  final_item(v_array<scored_action>*p,string s,float ic) : prefix(p), str(s), total_cost(ic) {}
};


void free_final_item(final_item* p)
{ p->prefix->delete_v();
  delete p->prefix;
  delete p;
}

void BaseTask::Run()
{ search_private& priv = *sch->priv;
  // make sure output is correct
  bool old_should_produce_string = priv.should_produce_string;
  if (! _final_run && ! _with_output_string) priv.should_produce_string = false;
  // if this isn't a final run, it shouldn't count for loss
  float old_test_loss = priv.test_loss;
  //float old_learn_loss = priv.learn_loss;
  priv.learn_loss *= 0.5;
  float old_train_loss = priv.train_loss;

  if (priv.should_produce_string)
    priv.pred_string->str("");

  priv.t = 0;
  priv.metaoverride = this;
  priv.task->run(*sch, ec);
  priv.metaoverride = nullptr;
  priv.meta_t += priv.t;

  // restore
  if (_with_output_string && old_should_produce_string)
    _with_output_string(*sch, *priv.pred_string);

  priv.should_produce_string = old_should_produce_string;
  if (! _final_run)
  { priv.test_loss = old_test_loss;
    //priv.learn_loss = old_learn_loss;
    priv.train_loss = old_train_loss;
  }
}

void run_task(search& sch, vector<example*>& ec)
{ search_private& priv = *sch.priv;
  if (priv.metatask && (priv.state != GET_TRUTH_STRING))
    priv.metatask->run(sch, ec);
  else
    priv.task->run(sch, ec);
}

template <bool is_learn>
void train_single_example(search& sch, bool is_test_ex, bool is_holdout_ex)
{ search_private& priv = *sch.priv;
  vw&all = *priv.all;
  bool ran_test = false;  // we must keep track so that even if we skip test, we still update # of examples seen

  //if (! priv.no_caching)
  clear_cache_hash_map(priv);

  cdbg << "is_test_ex=" << is_test_ex << " vw_is_main=" << all.vw_is_main << endl;
  cdbg << "must_run_test = " << must_run_test(all, priv.ec_seq, is_test_ex) << endl;
  // do an initial test pass to compute output (and loss)
  if (must_run_test(all, priv.ec_seq, is_test_ex))
  { cdbg << "======================================== INIT TEST (" << priv.current_policy << "," << priv.read_example_last_pass << ") ========================================" << endl;

    ran_test = true;

    // do the prediction
    reset_search_structure(priv);
    priv.state = INIT_TEST;
    priv.should_produce_string = might_print_update(all) || (all.final_prediction_sink.size() > 0) || (all.raw_prediction > 0);
    priv.pred_string->str("");
    priv.test_action_sequence.clear();
    run_task(sch, priv.ec_seq);

    // accumulate loss
    if (! is_test_ex)
      all.sd->update(priv.ec_seq[0]->test_only, priv.test_loss, 1.f, priv.num_features);

    // generate output
    for (int sink : all.final_prediction_sink)
      all.print_text((int)sink, priv.pred_string->str(), priv.ec_seq[0]->tag);

    if (all.raw_prediction > 0)
      all.print_text(all.raw_prediction, "", priv.ec_seq[0]->tag);
  }

  // if we're not training, then we're done!
  if ((!is_learn) || is_test_ex || is_holdout_ex || priv.ec_seq[0]->test_only || (!priv.all->training))
    return;

  // SPEEDUP: if the oracle was never called, we can skip this!

  // do a pass over the data allowing oracle
  cdbg << "======================================== INIT TRAIN (" << priv.current_policy << "," << priv.read_example_last_pass << ") ========================================" << endl;
  //cerr << "training" << endl;

  clear_cache_hash_map(priv);
  reset_search_structure(priv);
  clear_memo_foreach_action(priv);
  priv.state = INIT_TRAIN;
  priv.active_uncertainty.erase();
  priv.train_trajectory.erase();  // this is where we'll store the training sequence
  run_task(sch, priv.ec_seq);

  if (!ran_test)    // was  && !priv.ec_seq[0]->test_only) { but we know it's not test_only
  { all.sd->weighted_examples += 1.f;
    all.sd->total_features += priv.num_features;
    all.sd->sum_loss += priv.test_loss;
    all.sd->sum_loss_since_last_dump += priv.test_loss;
    all.sd->example_number++;
  }

  // if there's nothing to train on, we're done!
  if ((priv.loss_declared_cnt == 0) || (priv.t+priv.meta_t == 0) || (priv.rollout_method == NO_ROLLOUT))  // TODO: make sure NO_ROLLOUT works with beam!
  { return;
  }

  // otherwise, we have some learn'in to do!
  cdbg << "======================================== LEARN (" << priv.current_policy << "," << priv.read_example_last_pass << ") ========================================" << endl;
  priv.T = priv.metatask ? priv.meta_t : priv.t;
  get_training_timesteps(priv, priv.timesteps);
  cdbg << "train_trajectory.size() = " << priv.train_trajectory.size() << ":\t";
  cdbg_print_array<scored_action>("", priv.train_trajectory);
  //cdbg << "memo_foreach_action = " << priv.memo_foreach_action << endl;
  for (size_t i=0; i<priv.memo_foreach_action.size(); i++)
  { cdbg << "memo_foreach_action[" << i << "] = ";
    if (priv.memo_foreach_action[i]) cdbg << *priv.memo_foreach_action[i];
    else cdbg << "null";
    cdbg << endl;
  }

  if (priv.cb_learner) priv.learn_losses.cb.costs.erase();
  else                 priv.learn_losses.cs.costs.erase();

  for (size_t tid=0; tid<priv.timesteps.size(); tid++)
  { cdbg << "timestep = " << priv.timesteps[tid] << " [" << tid << "/" << priv.timesteps.size() << "]" << endl;

    if (priv.metatask && !priv.memo_foreach_action[tid])
    { cdbg << "skipping because it looks like this was overridden by metatask" << endl;
      continue;
    }

    priv.learn_a_idx = 0;
    priv.done_with_all_actions = false;
    // for each action, roll out to get a loss
    while (! priv.done_with_all_actions)
    { reset_search_structure(priv);

      priv.state = LEARN;
      priv.learn_t = priv.timesteps[tid];
      cdbg << "-------------------------------------------------------------------------------------" << endl;
      cdbg << "learn_t = " << priv.learn_t << ", learn_a_idx = " << priv.learn_a_idx << endl;
      run_task(sch, priv.ec_seq);
      //cerr_print_array("in GENER, learn_allowed_actions", priv.learn_allowed_actions);
      float this_loss = priv.learn_loss;
      cs_cost_push_back(priv.cb_learner, priv.learn_losses, priv.is_ldf ? (uint32_t)(priv.learn_a_idx - 1) : (uint32_t)priv.learn_a_idx, this_loss);
      //                          (priv.learn_allowed_actions.size() > 0) ? priv.learn_allowed_actions[priv.learn_a_idx-1] : priv.is_ldf ? (priv.learn_a_idx-1) : (priv.learn_a_idx),
      //                           priv.learn_loss);
    }
    // now we can make a training example
    if (priv.learn_allowed_actions.size() > 0)
    { for (size_t i=0; i<priv.learn_allowed_actions.size(); i++)
      { priv.learn_losses.cs.costs[i].class_index = priv.learn_allowed_actions[i];
      }
    }
    //float min_loss = 0.;
    //if (priv.metatask)
    //  for (size_t aid=0; aid<priv.memo_foreach_action[tid]->size(); aid++)
    //    min_loss = MIN(min_loss, priv.memo_foreach_action[tid]->get(aid).cost);
    generate_training_example(priv, priv.learn_losses, 1., true); // , min_loss);  // TODO: weight
    if (! priv.examples_dont_change)
      for (size_t n=0; n<priv.learn_ec_copy.size(); n++)
      { if (sch.priv->is_ldf) CS::cs_label.delete_label(&priv.learn_ec_copy[n].l.cs);
        else                  MC::mc_label.delete_label(&priv.learn_ec_copy[n].l.multi);
      }
    if (priv.cb_learner) priv.learn_losses.cb.costs.erase();
    else                 priv.learn_losses.cs.costs.erase();
  }
}


template <bool is_learn>
void do_actual_learning(vw&all, search& sch)
{ search_private& priv = *sch.priv;

  if (priv.ec_seq.size() == 0)
    return;  // nothing to do :)

  bool is_test_ex = false;
  bool is_holdout_ex = false;
  for (size_t i=0; i<priv.ec_seq.size(); i++)
  { is_test_ex |= priv.label_is_test(priv.ec_seq[i]->l);
    is_holdout_ex |= priv.ec_seq[i]->test_only;
    if (is_test_ex && is_holdout_ex) break;
  }

  if (priv.task->run_setup) priv.task->run_setup(sch, priv.ec_seq);

  // if we're going to have to print to the screen, generate the "truth" string
  cdbg << "======================================== GET TRUTH STRING (" << priv.current_policy << "," << priv.read_example_last_pass << ") ========================================" << endl;
  if (might_print_update(all))
  { if (is_test_ex)
      priv.truth_string->str("**test**");
    else
    { reset_search_structure(*sch.priv);
      priv.state = GET_TRUTH_STRING;
      priv.should_produce_string = true;
      priv.truth_string->str("");
      run_task(sch, priv.ec_seq);
    }
  }

  add_neighbor_features(priv);
  train_single_example<is_learn>(sch, is_test_ex, is_holdout_ex);
  del_neighbor_features(priv);

  if (priv.task->run_takedown) priv.task->run_takedown(sch, priv.ec_seq);
}

template <bool is_learn>
void search_predict_or_learn(search& sch, base_learner& base, example& ec)
{ search_private& priv = *sch.priv;
  vw* all = priv.all;
  priv.base_learner = &base;
  bool is_real_example = true;

  if (priv.auto_condition_features)
  { // turn off auto-condition if it's irrelevant
    if ((priv.history_length == 0) || (priv.acset.feature_value == 0.f))
    { std::cerr << "warning: turning off AUTO_CONDITION_FEATURES because settings make it useless" << endl;
      priv.auto_condition_features = false;
    }
  }

  if (example_is_newline(ec) || priv.ec_seq.size() >= all->p->ring_size - 2)
  { if (priv.ec_seq.size() >= all->p->ring_size - 2) // -2 to give some wiggle room
      std::cerr << "warning: length of sequence at " << ec.example_counter << " exceeds ring size; breaking apart" << std::endl;

    do_actual_learning<is_learn>(*all, sch);

    priv.hit_new_pass = false;
    priv.last_example_was_newline = true;
    is_real_example = false;
  }
  else
  { if (priv.last_example_was_newline)
      priv.ec_seq.clear();
    priv.ec_seq.push_back(&ec);
    priv.last_example_was_newline = false;
  }

  if (is_real_example)
    priv.read_example_last_id = ec.example_counter;
}

void end_pass(search& sch)
{ search_private& priv = *sch.priv;
  vw* all = priv.all;
  priv.hit_new_pass = true;
  priv.read_example_last_pass++;
  priv.passes_since_new_policy++;

  if (priv.passes_since_new_policy >= priv.passes_per_policy)
  { priv.passes_since_new_policy = 0;
    if(all->training)
      priv.current_policy++;
    if (priv.current_policy > priv.total_number_of_policies)
    { std::cerr << "internal error (bug): too many policies; not advancing" << std::endl;
      priv.current_policy = priv.total_number_of_policies;
    }
    //reset search_trained_nb_policies in options_from_file so it is saved to regressor file later
    std::stringstream ss;
    ss << priv.current_policy;
    VW::cmd_string_replace_value(all->file_options,"--search_trained_nb_policies", ss.str());
  }
}

void finish_example(vw& all, search& sch, example& ec)
{ if (ec.end_pass || example_is_newline(ec) || sch.priv->ec_seq.size() >= all.p->ring_size - 2)
  { print_update(*sch.priv);
    VW::finish_example(all, &ec);
    clear_seq(all, *sch.priv);
  }
}

void end_examples(search& sch)
{ search_private& priv = *sch.priv;
  vw* all    = priv.all;

  do_actual_learning<true>(*all, sch);

  if( all->training )
  { std::stringstream ss1;
    std::stringstream ss2;
    ss1 << ((priv.passes_since_new_policy == 0) ? priv.current_policy : (priv.current_policy+1));
    //use cmd_string_replace_value in case we already loaded a predictor which had a value stored for --search_trained_nb_policies
    VW::cmd_string_replace_value(all->file_options,"--search_trained_nb_policies", ss1.str());
    ss2 << priv.total_number_of_policies;
    //use cmd_string_replace_value in case we already loaded a predictor which had a value stored for --search_total_nb_policies
    VW::cmd_string_replace_value(all->file_options,"--search_total_nb_policies", ss2.str());
  }
}

bool mc_label_is_test(polylabel& lab)
{ return MC::label_is_test(&lab.multi);
}

void search_initialize(vw* all, search& sch)
{ search_private& priv = *sch.priv;//priv is zero initialized by default
  priv.all = all;

  priv.label_is_test = mc_label_is_test;

  priv.A = 1;
  priv.num_learners = 1;
  priv.state = INITIALIZE;
  priv.mix_per_roll_policy = -2;

  priv.pred_string  = new stringstream();
  priv.truth_string = new stringstream();
  priv.bad_string_stream = new stringstream();
  priv.bad_string_stream->clear(priv.bad_string_stream->badbit);

  priv.beta = 0.5;
  priv.alpha = 1e-10f;

  priv.rollout_method = MIX_PER_ROLL;
  priv.rollin_method  = MIX_PER_ROLL;

  priv.allow_current_policy = true;
  priv.adaptive_beta = true;
  priv.passes_per_policy = 1;     //this should be set to the same value as --passes for dagger

  priv.total_number_of_policies = 1;

  priv.history_length = 1;
  priv.acset.max_bias_ngram_length = 1;

  priv.acset.feature_value = 1.;

  scored_action sa((action)-1,0.);
  new (&priv.cache_hash_map) v_hashmap<unsigned char*, scored_action>();
  priv.cache_hash_map.set_default_value(sa);
  priv.cache_hash_map.set_equivalent(cached_item_equivalent);

  sch.task_data = nullptr;

  priv.empty_example = VW::alloc_examples(sizeof(CS::label), 1);
  CS::cs_label.default_label(&priv.empty_example->l.cs);
  priv.empty_example->in_use = true;
  CS::cs_label.default_label(&priv.empty_cs_label);

  new (&priv.rawOutputString) string();
  priv.rawOutputStringStream = new stringstream(priv.rawOutputString);
  new (&priv.ec_seq) vector<example*>();
  new (&priv.test_action_sequence) vector<action>();
  new (&priv.dat_new_feature_audit_ss) stringstream();
}

void search_finish(search& sch)
{ search_private& priv = *sch.priv;
  cdbg << "search_finish" << endl;

  clear_cache_hash_map(priv);

  delete priv.truth_string;
  delete priv.pred_string;
  delete priv.bad_string_stream;
  priv.cache_hash_map.~v_hashmap<unsigned char*, scored_action>();
  priv.rawOutputString.~string();
  priv.ec_seq.~vector<example*>();
  priv.test_action_sequence.~vector<action>();
  priv.dat_new_feature_audit_ss.~stringstream();
  priv.neighbor_features.delete_v();
  priv.timesteps.delete_v();
  if (priv.cb_learner) priv.learn_losses.cb.costs.delete_v();
  else                 priv.learn_losses.cs.costs.delete_v();
  if (priv.cb_learner) priv.gte_label.cb.costs.delete_v();
  else                 priv.gte_label.cs.costs.delete_v();

  priv.condition_on_actions.delete_v();
  priv.learn_allowed_actions.delete_v();
  priv.ldf_test_label.costs.delete_v();
  priv.last_action_repr.delete_v();

  if (priv.cb_learner)
    priv.allowed_actions_cache->cb.costs.delete_v();
  else
    priv.allowed_actions_cache->cs.costs.delete_v();

  priv.train_trajectory.delete_v();
  for (Search::action_repr& ar : priv.ptag_to_action)
  { if(ar.repr !=nullptr)
    { ar.repr->delete_v();
      delete ar.repr;
      cdbg << "delete_v" << endl;
    }
  }
  priv.ptag_to_action.delete_v();
  clear_memo_foreach_action(priv);
  priv.memo_foreach_action.delete_v();

  VW::dealloc_example(CS::cs_label.delete_label, *(priv.empty_example));
  free(priv.empty_example);

  priv.ec_seq.clear();

  // destroy copied examples if we needed them
  if (! priv.examples_dont_change)
  { void (*delete_label)(void*) = priv.is_ldf ? CS::cs_label.delete_label : MC::mc_label.delete_label;
    for(example& ec : priv.learn_ec_copy)
      VW::dealloc_example(delete_label, ec);
    priv.learn_ec_copy.delete_v();
  }
  priv.learn_condition_on_names.delete_v();
  priv.learn_condition_on.delete_v();
  priv.learn_condition_on_act.delete_v();

  if (priv.task->finish) priv.task->finish(sch);
  if (priv.metatask && priv.metatask->finish) priv.metatask->finish(sch);

  free(priv.allowed_actions_cache);
  delete priv.rawOutputStringStream;
  free (sch.priv);
}

void ensure_param(float &v, float lo, float hi, float def, const char* string)
{ if ((v < lo) || (v > hi))
  { std::cerr << string << endl;
    v = def;
  }
}

bool string_equal(string a, string b) { return a.compare(b) == 0; }
bool float_equal(float a, float b) { return fabs(a-b) < 1e-6; }
bool uint32_equal(uint32_t a, uint32_t b) { return a==b; }
bool size_equal(size_t a, size_t b) { return a==b; }

void check_option(bool& ret, vw&all, po::variables_map& vm, const char* opt_name, bool /*default_to_cmdline*/, const char* /*mismatch_error_string*/)
{ if (vm.count(opt_name))
  { ret = true;
    *all.file_options << " --" << opt_name;
  }
  else
    ret = false;
}

void handle_condition_options(vw& vw, auto_condition_settings& acset)
{ new_options(vw, "Search Auto-conditioning Options")
  ("search_max_bias_ngram_length",   po::value<size_t>(), "add a \"bias\" feature for each ngram up to and including this length. eg., if it's 1 (default), then you get a single feature for each conditional")
  ("search_max_quad_ngram_length",   po::value<size_t>(), "add bias *times* input features for each ngram up to and including this length (def: 0)")
  ("search_condition_feature_value", po::value<float> (), "how much weight should the conditional features get? (def: 1.)")
  ("search_use_passthrough_repr",                         "should we use lower-level reduction _internal state_ as additional features? (def: no)");
  add_options(vw);

  po::variables_map& vm = vw.vm;

  check_option<size_t>(acset.max_bias_ngram_length, vw, vm, "search_max_bias_ngram_length", false, size_equal,
                       "warning: you specified a different value for --search_max_bias_ngram_length than the one loaded from regressor. proceeding with loaded value: ", "");

  check_option<size_t>(acset.max_quad_ngram_length, vw, vm, "search_max_quad_ngram_length", false, size_equal,
                       "warning: you specified a different value for --search_max_quad_ngram_length than the one loaded from regressor. proceeding with loaded value: ", "");

  check_option<float> (acset.feature_value, vw, vm, "search_condition_feature_value", false, float_equal,
                       "warning: you specified a different value for --search_condition_feature_value than the one loaded from regressor. proceeding with loaded value: ", "");

  check_option(acset.use_passthrough_repr, vw, vm, "search_use_passthrough_repr", false, "warning: you specified a different value for --search_use_passthrough_repr than the one loaded from regressor. proceeding with loaded value: ");
}

v_array<CS::label> read_allowed_transitions(action A, const char* filename)
{ FILE *f = fopen(filename, "r");
  if (f == nullptr)
    THROW("error: could not read file " << filename << " (" << strerror(errno) << "); assuming all transitions are valid");

  bool* bg = calloc_or_throw<bool>((A+1)*(A+1));
  int rd,from,to,count=0;
  while ((rd = fscanf(f, "%d:%d", &from, &to)) > 0)
  { if ((from < 0) || (from > (int)A)) { std::cerr << "warning: ignoring transition from " << from << " because it's out of the range [0," << A << "]" << endl; }
    if ((to   < 0) || (to   > (int)A)) { std::cerr << "warning: ignoring transition to "   << to   << " because it's out of the range [0," << A << "]" << endl; }
    bg[from * (A+1) + to] = true;
    count++;
  }
  fclose(f);

  v_array<CS::label> allowed = v_init<CS::label>();

  for (size_t from=0; from<A; from++)
  { v_array<CS::wclass> costs = v_init<CS::wclass>();

    for (size_t to=0; to<A; to++)
      if (bg[from * (A+1) + to])
      { CS::wclass c = { FLT_MAX, (action)to, 0., 0. };
        costs.push_back(c);
      }

    CS::label ld = { costs };
    allowed.push_back(ld);
  }
  free(bg);

  std::cerr << "read " << count << " allowed transitions from " << filename << endl;

  return allowed;
}


void parse_neighbor_features(string& nf_string, search&sch)
{ search_private& priv = *sch.priv;
  priv.neighbor_features.erase();
  size_t len = nf_string.length();
  if (len == 0) return;

  char * cstr = new char [len+1];
  strcpy(cstr, nf_string.c_str());

  char * p = strtok(cstr, ",");
  v_array<substring> cmd = v_init<substring>();
  while (p != 0)
  { cmd.erase();
    substring me = { p, p+strlen(p) };
    tokenize(':', me, cmd, true);

    int32_t posn = 0;
    char ns = ' ';
    if (cmd.size() == 1)
    { posn = int_of_substring(cmd[0]);
      ns   = ' ';
    }
    else if (cmd.size() == 2)
    { posn = int_of_substring(cmd[0]);
      ns   = (cmd[1].end > cmd[1].begin) ? cmd[1].begin[0] : ' ';
    }
    else
    { std::cerr << "warning: ignoring malformed neighbor specification: '" << p << "'" << endl;
    }
    int32_t enc = (posn << 24) | (ns & 0xFF);
    priv.neighbor_features.push_back(enc);

    p = strtok(nullptr, ",");
  }
  cmd.delete_v();

  delete[] cstr;
}

base_learner* setup(vw&all)
{ if (missing_option<size_t, false>(all, "search", "Use learning to search, argument=maximum action id or 0 for LDF"))
    return nullptr;
  new_options(all, "Search Options")
  ("search_task",              po::value<string>(), "the search task (use \"--search_task list\" to get a list of available tasks)")
  ("search_metatask",          po::value<string>(), "the search metatask (use \"--search_metatask list\" to get a list of available metatasks)")
  ("search_interpolation",     po::value<string>(), "at what level should interpolation happen? [*data|policy]")
  ("search_rollout",           po::value<string>(), "how should rollouts be executed?           [policy|oracle|*mix_per_state|mix_per_roll|none]")
  ("search_rollin",            po::value<string>(), "how should past trajectories be generated? [policy|oracle|*mix_per_state|mix_per_roll]")

  ("search_passes_per_policy", po::value<size_t>(), "number of passes per policy (only valid for search_interpolation=policy)     [def=1]")
  ("search_beta",              po::value<float>(),  "interpolation rate for policies (only valid for search_interpolation=policy) [def=0.5]")

  ("search_alpha",             po::value<float>(),  "annealed beta = 1-(1-alpha)^t (only valid for search_interpolation=data)     [def=1e-10]")

  ("search_total_nb_policies", po::value<size_t>(), "if we are going to train the policies through multiple separate calls to vw, we need to specify this parameter and tell vw how many policies are eventually going to be trained")

  ("search_trained_nb_policies", po::value<size_t>(), "the number of trained policies in a file")

  ("search_allowed_transitions",po::value<string>(),"read file of allowed transitions [def: all transitions are allowed]")
  ("search_subsample_time",    po::value<float>(),  "instead of training at all timesteps, use a subset. if value in (0,1), train on a random v%. if v>=1, train on precisely v steps per example, if v<=-1, use active learning")
  ("search_neighbor_features", po::value<string>(), "copy features from neighboring lines. argument looks like: '-1:a,+2' meaning copy previous line namespace a and next next line from namespace _unnamed_, where ',' separates them")
  ("search_rollout_num_steps", po::value<size_t>(), "how many calls of \"loss\" before we stop really predicting on rollouts and switch to oracle (def: 0 means \"infinite\")")
  ("search_history_length",    po::value<size_t>(), "some tasks allow you to specify how much history their depend on; specify that here [def: 1]")

  ("search_no_caching",                             "turn off the built-in caching ability (makes things slower, but technically more safe)")
  ("search_xv",                                     "train two separate policies, alternating prediction/learning")
  ("search_perturb_oracle",    po::value<float>(),  "perturb the oracle on rollin with this probability (def: 0)")
  ("search_linear_ordering",                        "insist on generating examples in linear order (def: hoopla permutation)")
  ;
  add_options(all);
  po::variables_map& vm = all.vm;

  bool has_hook_task = false;
  for (size_t i=0; i<all.args.size()-1; i++)
    if (all.args[i] == "--search_task" && all.args[i+1] == "hook")
      has_hook_task = true;
  if (has_hook_task)
    for (int i = (int)all.args.size()-2; i >= 0; i--)
      if (all.args[i] == "--search_task" && all.args[i+1] != "hook")
        all.args.erase(all.args.begin() + i, all.args.begin() + i + 2);

  search& sch = calloc_or_throw<search>();
  sch.priv = &calloc_or_throw<search_private>();
  search_initialize(&all, sch);
  search_private& priv = *sch.priv;

  std::string task_string;
  std::string metatask_string;
  std::string interpolation_string = "data";
  std::string rollout_string = "mix_per_state";
  std::string rollin_string = "mix_per_state";

  check_option<string>(task_string, all, vm, "search_task", false, string_equal,
                       "warning: specified --search_task different than the one loaded from regressor. using loaded value of: ",
                       "error: you must specify a task using --search_task");

  check_option<string>(metatask_string, all, vm, "search_metatask", false, string_equal,
                       "warning: specified --search_metatask different than the one loaded from regressor. using loaded value of: ", "");

  check_option<string>(interpolation_string, all, vm, "search_interpolation", false, string_equal,
                       "warning: specified --search_interpolation different than the one loaded from regressor. using loaded value of: ", "");

  if (vm.count("search_passes_per_policy"))       priv.passes_per_policy    = vm["search_passes_per_policy"].as<size_t>();
  if (vm.count("search_xv"))                      priv.xv       = true;
  if (vm.count("search_perturb_oracle"))          priv.perturb_oracle       = vm["search_perturb_oracle"].as<float>();
  if (vm.count("search_linear_ordering"))         priv.linear_ordering      = true;

  if (vm.count("search_alpha"))                   priv.alpha                = vm["search_alpha"            ].as<float>();
  if (vm.count("search_beta"))                    priv.beta                 = vm["search_beta"             ].as<float>();

  if (vm.count("search_subsample_time"))          priv.subsample_timesteps  = vm["search_subsample_time"].as<float>();
  if (vm.count("search_no_caching"))              priv.no_caching           = true;
  if (vm.count("search_rollout_num_steps"))       priv.rollout_num_steps    = vm["search_rollout_num_steps"].as<size_t>();

  priv.A = vm["search"].as<size_t>();

  string neighbor_features_string;
  check_option<string>(neighbor_features_string, all, vm, "search_neighbor_features", false, string_equal,
                       "warning: you specified a different feature structure with --search_neighbor_features than the one loaded from predictor. using loaded value of: ", "");
  parse_neighbor_features(neighbor_features_string, sch);

  if (interpolation_string.compare("data") == 0)   // run as dagger
  { priv.adaptive_beta = true;
    priv.allow_current_policy = true;
    priv.passes_per_policy = all.numpasses;
    if (priv.current_policy > 1) priv.current_policy = 1;
  }
  else if (interpolation_string.compare("policy") == 0)
  {
  }
  else
    THROW("error: --search_interpolation must be 'data' or 'policy'");

  if (vm.count("search_rollout")) rollout_string = vm["search_rollout"].as<string>();
  if (vm.count("search_rollin" )) rollin_string  = vm["search_rollin" ].as<string>();

  if      ((rollout_string.compare("policy") == 0)       || (rollout_string.compare("learn") == 0))          priv.rollout_method = POLICY;
  else if ((rollout_string.compare("oracle") == 0)       || (rollout_string.compare("ref") == 0))            priv.rollout_method = ORACLE;
  else if ((rollout_string.compare("mix_per_state") == 0))                                                   priv.rollout_method = MIX_PER_STATE;
  else if ((rollout_string.compare("mix_per_roll") == 0) || (rollout_string.compare("mix") == 0))            priv.rollout_method = MIX_PER_ROLL;
  else if ((rollout_string.compare("none") == 0))          { priv.rollout_method = NO_ROLLOUT; priv.no_caching = true; }
  else
    THROW("error: --search_rollout must be 'learn', 'ref', 'mix', 'mix_per_state' or 'none'");

  if      ((rollin_string.compare("policy") == 0)       || (rollin_string.compare("learn") == 0))          priv.rollin_method = POLICY;
  else if ((rollin_string.compare("oracle") == 0)       || (rollin_string.compare("ref") == 0))            priv.rollin_method = ORACLE;
  else if ((rollin_string.compare("mix_per_state") == 0))                                                  priv.rollin_method = MIX_PER_STATE;
  else if ((rollin_string.compare("mix_per_roll") == 0) || (rollin_string.compare("mix") == 0))            priv.rollin_method = MIX_PER_ROLL;
  else
    THROW("error: --search_rollin must be 'learn', 'ref', 'mix' or 'mix_per_state'");

  check_option<size_t>(priv.A, all, vm, "search", false, size_equal,
                       "warning: you specified a different number of actions through --search than the one loaded from predictor. using loaded value of: ", "");

  check_option<size_t>(priv.history_length, all, vm, "search_history_length", false, size_equal,
                       "warning: you specified a different history length through --search_history_length than the one loaded from predictor. using loaded value of: ", "");

  //check if the base learner is contextual bandit, in which case, we dont rollout all actions.
  priv.allowed_actions_cache = &calloc_or_throw<polylabel>();
  if (vm.count("cb"))
  { priv.cb_learner = true;
    CB::cb_label.default_label(priv.allowed_actions_cache);
    priv.learn_losses.cb.costs = v_init<CB::cb_class>();
    priv.gte_label.cb.costs = v_init<CB::cb_class>();
  }
  else
  { priv.cb_learner = false;
    CS::cs_label.default_label(priv.allowed_actions_cache);
    priv.learn_losses.cs.costs = v_init<CS::wclass>();
    priv.gte_label.cs.costs = v_init<CS::wclass>();
  }

  //if we loaded a regressor with -i option, --search_trained_nb_policies contains the number of trained policies in the file
  // and --search_total_nb_policies contains the total number of policies in the file
  if (vm.count("search_total_nb_policies"))
    priv.total_number_of_policies = (uint32_t)vm["search_total_nb_policies"].as<size_t>();

  ensure_param(priv.beta , 0.0, 1.0, 0.5, "warning: search_beta must be in (0,1); resetting to 0.5");
  ensure_param(priv.alpha, 0.0, 1.0, 1e-10f, "warning: search_alpha must be in (0,1); resetting to 1e-10");

  //compute total number of policies we will have at end of training
  // we add current_policy for cases where we start from an initial set of policies loaded through -i option
  uint32_t tmp_number_of_policies = priv.current_policy;
  if( all.training )
    tmp_number_of_policies += (int)ceil(((float)all.numpasses) / ((float)priv.passes_per_policy));

  //the user might have specified the number of policies that will eventually be trained through multiple vw calls,
  //so only set total_number_of_policies to computed value if it is larger
  cdbg << "current_policy=" << priv.current_policy << " tmp_number_of_policies=" << tmp_number_of_policies << " total_number_of_policies=" << priv.total_number_of_policies << endl;
  if( tmp_number_of_policies > priv.total_number_of_policies )
  { priv.total_number_of_policies = tmp_number_of_policies;
    if( priv.current_policy > 0 ) //we loaded a file but total number of policies didn't match what is needed for training
      std::cerr << "warning: you're attempting to train more classifiers than was allocated initially. Likely to cause bad performance." << endl;
  }

  //current policy currently points to a new policy we would train
  //if we are not training and loaded a bunch of policies for testing, we need to subtract 1 from current policy
  //so that we only use those loaded when testing (as run_prediction is called with allow_current to true)
  if( !all.training && priv.current_policy > 0 )
    priv.current_policy--;

  std::stringstream ss1, ss2;
  ss1 << priv.current_policy;           VW::cmd_string_replace_value(all.file_options,"--search_trained_nb_policies", ss1.str());
  ss2 << priv.total_number_of_policies; VW::cmd_string_replace_value(all.file_options,"--search_total_nb_policies",   ss2.str());

  cdbg << "search current_policy = " << priv.current_policy << " total_number_of_policies = " << priv.total_number_of_policies << endl;

  if (task_string.compare("list") == 0)
  { std::cerr << endl << "available search tasks:" << endl;
    for (search_task** mytask = all_tasks; *mytask != nullptr; mytask++)
      std::cerr << "  " << (*mytask)->task_name << endl;
    std::cerr << endl;
    exit(0);
  }
  if (metatask_string.compare("list") == 0)
  { std::cerr << endl << "available search metatasks:" << endl;
    for (search_metatask** mytask = all_metatasks; *mytask != nullptr; mytask++)
      std::cerr << "  " << (*mytask)->metatask_name << endl;
    std::cerr << endl;
    exit(0);
  }
  for (search_task** mytask = all_tasks; *mytask != nullptr; mytask++)
    if (task_string.compare((*mytask)->task_name) == 0)
    { priv.task = *mytask;
      sch.task_name = (*mytask)->task_name;
      break;
    }
  if (priv.task == nullptr)
  { if (! vm.count("help"))
      THROW("fail: unknown task for --search_task '" << task_string << "'; use --search_task list to get a list");
  }
  priv.metatask = nullptr;
  for (search_metatask** mytask = all_metatasks; *mytask != nullptr; mytask++)
    if (metatask_string.compare((*mytask)->metatask_name) == 0)
    { priv.metatask = *mytask;
      sch.metatask_name = (*mytask)->metatask_name;
      break;
    }
  all.p->emptylines_separate_examples = true;

  if (count(all.args.begin(), all.args.end(),"--csoaa") == 0
      && count(all.args.begin(), all.args.end(),"--csoaa_ldf") == 0
      && count(all.args.begin(), all.args.end(),"--wap_ldf") == 0
      &&  count(all.args.begin(), all.args.end(),"--cb") == 0)
  { all.args.push_back("--csoaa");
    stringstream ss;
    ss << vm["search"].as<size_t>();
    all.args.push_back(ss.str());
  }
  base_learner* base = setup_base(all);

  // default to OAA labels unless the task wants to override this (which they can do in initialize)
  all.p->lp = MC::mc_label;
  if (priv.task && priv.task->initialize)
    priv.task->initialize(sch, priv.A, vm);
  if (priv.metatask && priv.metatask->initialize)
    priv.metatask->initialize(sch, priv.A, vm);
  priv.meta_t = 0;

  if (vm.count("search_allowed_transitions"))     read_allowed_transitions((action)priv.A, vm["search_allowed_transitions"].as<string>().c_str());

  // set up auto-history (used to only do this if AUTO_CONDITION_FEATURES was on, but that doesn't work for hooktask)
  handle_condition_options(all, priv.acset);

  if (!priv.allow_current_policy) // if we're not dagger
    all.check_holdout_every_n_passes = priv.passes_per_policy;

  all.searchstr = &sch;

  priv.start_clock_time = clock();

  if (priv.xv) priv.num_learners *= 3;

  cdbg << "num_learners = " << priv.num_learners << endl;

  learner<search>& l = init_learner(&sch, base,
                                    search_predict_or_learn<true>,
                                    search_predict_or_learn<false>,
                                    priv.total_number_of_policies * priv.num_learners);
  l.set_finish_example(finish_example);
  l.set_end_examples(end_examples);
  l.set_finish(search_finish);
  l.set_end_pass(end_pass);

  return make_base(l);
}

float action_hamming_loss(action a, const action* A, size_t sz)
{ if (sz == 0) return 0.;   // latent variables have zero loss
  for (size_t i=0; i<sz; i++)
    if (a == A[i]) return 0.;
  return 1.;
}

float action_cost_loss(action a, const action* act, const float* costs, size_t sz)
{ if (act == nullptr) return costs[a-1];
  for (size_t i=0; i<sz; i++)
    if (act[i] == a) return costs[i];
  THROW("action_cost_loss got action that wasn't allowed: " << a);
}

// the interface:
bool search::is_ldf() { return priv->is_ldf; }

action search::predict(example& ec, ptag mytag, const action* oracle_actions, size_t oracle_actions_cnt, const ptag* condition_on, const char* condition_on_names, const action* allowed_actions, size_t allowed_actions_cnt, const float* allowed_actions_cost, size_t learner_id, float weight)
{ float a_cost = 0.;
  action a = search_predict(*priv, &ec, 1, mytag, oracle_actions, oracle_actions_cnt, condition_on, condition_on_names, allowed_actions, allowed_actions_cnt, allowed_actions_cost, learner_id, a_cost, weight);
  if (priv->state == INIT_TEST) priv->test_action_sequence.push_back(a);
  if (mytag != 0)
  { if (mytag < priv->ptag_to_action.size())
    { cdbg << "delete_v at " << mytag << endl;
      if(priv->ptag_to_action[mytag].repr != nullptr)
      { priv->ptag_to_action[mytag].repr->delete_v();
        delete priv->ptag_to_action[mytag].repr;
      }
    }
    if (priv->acset.use_passthrough_repr)
    { assert((mytag >= priv->ptag_to_action.size()) || (priv->ptag_to_action[mytag].repr ==  nullptr));
      push_at(priv->ptag_to_action, action_repr(a, &(priv->last_action_repr)), mytag);
    } else
      push_at(priv->ptag_to_action, action_repr(a, (features*)nullptr), mytag);
    cdbg << "push_at " << mytag << endl;
  }
  if (priv->auto_hamming_loss)
    loss( priv->use_action_costs
          ? action_cost_loss(a, allowed_actions, allowed_actions_cost, allowed_actions_cnt)
          : action_hamming_loss(a, oracle_actions, oracle_actions_cnt));
  cdbg << "predict returning " << a << endl;
  return a;
}

action search::predictLDF(example* ecs, size_t ec_cnt, ptag mytag, const action* oracle_actions, size_t oracle_actions_cnt, const ptag* condition_on, const char* condition_on_names, size_t learner_id, float weight)
{ float a_cost = 0.;
  // TODO: action costs for ldf
  action a = search_predict(*priv, ecs, ec_cnt, mytag, oracle_actions, oracle_actions_cnt, condition_on, condition_on_names, nullptr, 0, nullptr, learner_id, a_cost, weight);
  if (priv->state == INIT_TEST) priv->test_action_sequence.push_back(a);
  if ((mytag != 0) && ecs[a].l.cs.costs.size() > 0)
  { if (mytag < priv->ptag_to_action.size())
    { cdbg << "delete_v at " << mytag << endl;
      if(priv->ptag_to_action[mytag].repr != nullptr)
      { priv->ptag_to_action[mytag].repr->delete_v();
        delete priv->ptag_to_action[mytag].repr;
      }
    }
    push_at(priv->ptag_to_action, action_repr(ecs[a].l.cs.costs[0].class_index, &(priv->last_action_repr)), mytag);
  }
  if (priv->auto_hamming_loss)
    loss(action_hamming_loss(a, oracle_actions, oracle_actions_cnt)); // TODO: action costs
  cdbg << "predict returning " << a << endl;
  return a;
}

void search::loss(float loss) { search_declare_loss(*this->priv, loss); }

bool search::predictNeedsExample() { return search_predictNeedsExample(*this->priv); }

stringstream& search::output()
{ if      (!this->priv->should_produce_string    ) return *(this->priv->bad_string_stream);
  else if ( this->priv->state == GET_TRUTH_STRING) return *(this->priv->truth_string);
  else                                             return *(this->priv->pred_string);
}

void  search::set_options(uint32_t opts)
{ if (this->priv->all->vw_is_main && (this->priv->state != INITIALIZE))
    std::cerr << "warning: task should not set options except in initialize function!" << endl;
  if ((opts & AUTO_CONDITION_FEATURES) != 0) this->priv->auto_condition_features = true;
  if ((opts & AUTO_HAMMING_LOSS)       != 0) this->priv->auto_hamming_loss = true;
  if ((opts & EXAMPLES_DONT_CHANGE)    != 0) this->priv->examples_dont_change = true;
  if ((opts & IS_LDF)                  != 0) this->priv->is_ldf = true;
  if ((opts & NO_CACHING)              != 0) this->priv->no_caching = true;
  if ((opts & ACTION_COSTS)            != 0) this->priv->use_action_costs = true;

  if (this->priv->is_ldf && this->priv->use_action_costs)
    THROW("using LDF and actions costs is not yet implemented; turn off action costs"); // TODO fix

  if (this->priv->use_action_costs && (this->priv->rollout_method != NO_ROLLOUT))
    cerr << "warning: task is designed to use rollout costs, but this only works when --search_rollout none is specified" << endl;
}

void search::set_label_parser(label_parser&lp, bool (*is_test)(polylabel&))
{ if (this->priv->all->vw_is_main && (this->priv->state != INITIALIZE))
    std::cerr << "warning: task should not set label parser except in initialize function!" << endl;
  this->priv->all->p->lp = lp;
  this->priv->label_is_test = is_test;
}

void search::get_test_action_sequence(vector<action>& V)
{ V.clear();
  for (size_t i=0; i<this->priv->test_action_sequence.size(); i++)
    V.push_back(this->priv->test_action_sequence[i]);
}


void search::set_num_learners(size_t num_learners) { this->priv->num_learners = num_learners; }
void search::add_program_options(po::variables_map& /*vw*/, po::options_description& opts) { add_options( *this->priv->all, opts ); }

uint64_t search::get_mask() { return this->priv->all->reg.weight_mask;}
size_t search::get_stride_shift() { return this->priv->all->reg.stride_shift;}
uint32_t search::get_history_length() { return (uint32_t)this->priv->history_length; }

string search::pretty_label(action a)
{ if (this->priv->all->sd->ldict)
  { substring ss = this->priv->all->sd->ldict->get(a);
    return string(ss.begin, ss.end-ss.begin);
  }
  else
  { ostringstream os;
    os << a;
    return os.str();
  }
}

vw& search::get_vw_pointer_unsafe() { return *this->priv->all; }
void search::set_force_oracle(bool force) { this->priv->force_oracle = force; }

// predictor implementation
predictor::predictor(search& sch, ptag my_tag) : is_ldf(false), my_tag(my_tag), ec(nullptr), ec_cnt(0), ec_alloced(false), weight(1.), oracle_is_pointer(false), allowed_is_pointer(false), allowed_cost_is_pointer(false), learner_id(0), sch(sch)
{ oracle_actions = v_init<action>();
  condition_on_tags = v_init<ptag>();
  condition_on_names = v_init<char>();
  allowed_actions = v_init<action>();
  allowed_actions_cost = v_init<float>();
}

void predictor::free_ec()
{ if (ec_alloced)
  { if (is_ldf)
      for (size_t i=0; i<ec_cnt; i++)
        VW::dealloc_example(CS::cs_label.delete_label, ec[i]);
    else
      VW::dealloc_example(nullptr, *ec);
    free(ec);
  }
}

predictor::~predictor()
{ if (! oracle_is_pointer) oracle_actions.delete_v();
  if (! allowed_is_pointer) allowed_actions.delete_v();
  if (! allowed_cost_is_pointer) allowed_actions_cost.delete_v();
  free_ec();
  condition_on_tags.delete_v();
  condition_on_names.delete_v();
}
predictor& predictor::reset()
{ this->erase_oracles();
  this->erase_alloweds();
  condition_on_tags.erase();
  condition_on_names.erase();
  free_ec();
  return *this;
}

predictor& predictor::set_input(example&input_example)
{ free_ec();
  is_ldf = false;
  ec = &input_example;
  ec_cnt = 1;
  ec_alloced = false;
  return *this;
}

predictor& predictor::set_input(example*input_example, size_t input_length)
{ free_ec();
  is_ldf = true;
  ec = input_example;
  ec_cnt = input_length;
  ec_alloced = false;
  return *this;
}

void predictor::set_input_length(size_t input_length)
{ is_ldf = true;
  if (ec_alloced)
  { example* temp = (example*)realloc(ec, input_length * sizeof(example));
    if (temp != nullptr)
      ec = temp;
    else
      THROW("realloc failed in search.cc");
  }
  else            ec = calloc_or_throw<example>(input_length);
  ec_cnt = input_length;
  ec_alloced = true;
}
void predictor::set_input_at(size_t posn, example&ex)
{ if (!ec_alloced)
    THROW("call to set_input_at without previous call to set_input_length");

  if (posn >= ec_cnt)
    THROW("call to set_input_at with too large a position: posn (" << posn << ") >= ec_cnt(" << ec_cnt << ")");

  VW::copy_example_data(false, ec+posn, &ex, CS::cs_label.label_size, CS::cs_label.copy_label); // TODO: the false is "audit"
}

template<class T>
void predictor::make_new_pointer(v_array<T>& A, size_t new_size)
{ size_t old_size      = A.size();
  T* old_pointer  = A.begin();
  A.begin()     = calloc_or_throw<T>(new_size);
  A.end()       = A.begin() + new_size;
  A.end_array = A.end();
  memcpy(A.begin(), old_pointer, old_size * sizeof(T));
}

template<class T>
predictor& predictor::add_to(v_array<T>& A, bool& A_is_ptr, T a, bool clear_first)
{ if (A_is_ptr)   // we need to make our own memory
  { if (clear_first)
      A.end() = A.begin();
    size_t new_size = clear_first ? 1 : (A.size() + 1);
    make_new_pointer<T>(A, new_size);
    A_is_ptr = false;
    A[new_size-1] = a;
  }
  else     // we've already allocated our own memory
  { if (clear_first) A.erase();
    A.push_back(a);
  }
  return *this;
}

template<class T>
predictor& predictor::add_to(v_array<T>&A, bool& A_is_ptr, T*a, size_t count, bool clear_first)
{ size_t old_size = A.size();
  if (old_size > 0)
  { if (A_is_ptr)   // we need to make our own memory
    { if (clear_first)
      { A.end() = A.begin();
        old_size = 0;
      }
      size_t new_size = old_size + count;
      make_new_pointer<T>(A, new_size);
      A_is_ptr = false;
      if (a != nullptr) memcpy(A.begin() + old_size, a, count * sizeof(T));
    }
    else     // we already have our own memory
    { if (clear_first) A.erase();
      if (a != nullptr) push_many<T>(A, a, count);
    }
  }
  else     // old_size == 0, clear_first is irrelevant
  { if (! A_is_ptr)
      A.delete_v(); // avoid memory leak

    A.begin() = a;
    if (a != nullptr) // a is not nullptr
      A.end() = a + count;
    else
      A.end() = a;
    A.end_array = A.end();
    A_is_ptr = true;
  }
  return *this;
}

predictor& predictor::erase_oracles() { if (oracle_is_pointer) oracle_actions.end() = oracle_actions.begin(); else oracle_actions.erase(); return *this; }
predictor& predictor::add_oracle(action a) { return add_to(oracle_actions, oracle_is_pointer, a, false); }
predictor& predictor::add_oracle(action*a, size_t action_count) { return add_to(oracle_actions, oracle_is_pointer, a, action_count, false); }
predictor& predictor::add_oracle(v_array<action>& a) { return add_to(oracle_actions, oracle_is_pointer, a.begin(), a.size(), false); }

predictor& predictor::set_oracle(action a) { return add_to(oracle_actions, oracle_is_pointer, a, true); }
predictor& predictor::set_oracle(action*a, size_t action_count) { return add_to(oracle_actions, oracle_is_pointer, a, action_count, true); }
predictor& predictor::set_oracle(v_array<action>& a) { return add_to(oracle_actions, oracle_is_pointer, a.begin(), a.size(), true); }

predictor& predictor::set_weight(float w) { weight = w; return *this; }

predictor& predictor::erase_alloweds()
{ if (allowed_is_pointer) allowed_actions.end() = allowed_actions.begin(); else allowed_actions.erase();
  if (allowed_cost_is_pointer) allowed_actions_cost.end() = allowed_actions_cost.begin(); else allowed_actions_cost.erase();
  return *this;
}
predictor& predictor::add_allowed(action a) { return add_to(allowed_actions, allowed_is_pointer, a, false); }
predictor& predictor::add_allowed(action*a, size_t action_count) { return add_to(allowed_actions, allowed_is_pointer, a, action_count, false); }
predictor& predictor::add_allowed(v_array<action>& a) { return add_to(allowed_actions, allowed_is_pointer, a.begin(), a.size(), false); }

predictor& predictor::set_allowed(action a) { return add_to(allowed_actions, allowed_is_pointer, a, true); }
predictor& predictor::set_allowed(action*a, size_t action_count) { return add_to(allowed_actions, allowed_is_pointer, a, action_count, true); }
predictor& predictor::set_allowed(v_array<action>& a) { return add_to(allowed_actions, allowed_is_pointer, a.begin(), a.size(), true); }

predictor& predictor::add_allowed(action a, float cost)
{ add_to(allowed_actions_cost, allowed_cost_is_pointer, cost, false);
  return add_to(allowed_actions, allowed_is_pointer, a, false);
}

predictor& predictor::add_allowed(action*a, float*costs, size_t action_count)
{ add_to(allowed_actions_cost, allowed_cost_is_pointer, costs, action_count, false);
  return add_to(allowed_actions, allowed_is_pointer, a, action_count, false);
}
predictor& predictor::add_allowed(v_array< pair<action,float> >& a)
{ for (size_t i=0; i<a.size(); i++)
  { add_to(allowed_actions,      allowed_is_pointer,      a[i].first,  false);
    add_to(allowed_actions_cost, allowed_cost_is_pointer, a[i].second, false);
  }
  return *this;
}
predictor& predictor::add_allowed(vector< pair<action,float> >& a)
{ for (size_t i=0; i<a.size(); i++)
  { add_to(allowed_actions,      allowed_is_pointer,      a[i].first,  false);
    add_to(allowed_actions_cost, allowed_cost_is_pointer, a[i].second, false);
  }
  return *this;
}

predictor& predictor::set_allowed(action a, float cost)
{ add_to(allowed_actions_cost, allowed_cost_is_pointer, cost, true);
  return add_to(allowed_actions, allowed_is_pointer, a, true);
}

predictor& predictor::set_allowed(action*a, float*costs, size_t action_count)
{ add_to(allowed_actions_cost, allowed_cost_is_pointer, costs, action_count, true);
  return add_to(allowed_actions, allowed_is_pointer, a, action_count, true);
}
predictor& predictor::set_allowed(v_array< pair<action,float> >& a) { erase_alloweds(); return add_allowed(a); }
predictor& predictor::set_allowed(vector< pair<action,float> >& a) { erase_alloweds(); return add_allowed(a); }


predictor& predictor::add_condition(ptag tag, char name) { condition_on_tags.push_back(tag); condition_on_names.push_back(name); return *this; }
predictor& predictor::set_condition(ptag tag, char name) { condition_on_tags.erase(); condition_on_names.erase(); return add_condition(tag, name); }

predictor& predictor::add_condition_range(ptag hi, ptag count, char name0)
{ if (count == 0) return *this;
  for (ptag i=0; i<count; i++)
  { if (i > hi) break;
    char name = name0 + i;
    condition_on_tags.push_back(hi-i);
    condition_on_names.push_back(name);
  }
  return *this;
}
predictor& predictor::set_condition_range(ptag hi, ptag count, char name0) { condition_on_tags.erase(); condition_on_names.erase(); return add_condition_range(hi, count, name0); }

predictor& predictor::set_learner_id(size_t id) { learner_id = id; return *this; }

predictor& predictor::set_tag(ptag tag) { my_tag = tag; return *this; }

action predictor::predict()
{ const action* orA = oracle_actions.size() == 0 ? nullptr : oracle_actions.begin();
  const ptag*   cOn = condition_on_names.size() == 0 ? nullptr : condition_on_tags.begin();
  const char*   cNa = nullptr;
  if (condition_on_names.size() > 0)
  { condition_on_names.push_back((char)0);  // null terminate
    cNa = condition_on_names.begin();
  }
  const action* alA      = (allowed_actions.size() == 0) ? nullptr : allowed_actions.begin();
  const float*  alAcosts = (allowed_actions_cost.size() == 0) ? nullptr : allowed_actions_cost.begin();
  size_t numAlA = max(allowed_actions.size(), allowed_actions_cost.size());
  action p = is_ldf
             ? sch.predictLDF(ec, ec_cnt, my_tag, orA, oracle_actions.size(), cOn, cNa, learner_id, weight)
             : sch.predict(*ec, my_tag, orA, oracle_actions.size(), cOn, cNa, alA, numAlA, alAcosts, learner_id, weight);

  if (condition_on_names.size() > 0)
    condition_on_names.pop();  // un-null-terminate
  return p;
}
}

// TODO: valgrind --leak-check=full ./vw --search 2 -k -c --passes 1 --search_task sequence -d test_beam --holdout_off --search_rollin policy --search_metatask selective_branching 2>&1 | less
