/*
  Copyright (c) by respective owners including Yahoo!, Microsoft, and
  individual contributors. All rights reserved.  Released under a BSD (revised)
  license as described in the file LICENSE.
*/
#include "search_dep_parser.h"
#include "gd.h"
#include "cost_sensitive.h"
#include "label_dictionary.h"   // for add_example_namespaces_from_example
#include "vw.h"
#include "vw_exception.h"
using namespace std;

#define val_namespace 100 // valency and distance feature space
#define offset_const 344429
#define arc_hybrid 1
#define arc_eager 2


namespace DepParserTask         {  Search::search_task task = { "dep_parser", run, initialize, finish, setup, nullptr};  }

struct task_data
{ example *ex;
  size_t root_label;
  uint32_t num_label;
  v_array<uint32_t> valid_actions, action_loss, gold_heads, gold_tags, stack, heads, tags, temp, valid_action_temp;
  v_array<action> gold_actions, gold_action_temp;
  v_array<pair<action, float>> gold_action_losses;
  v_array<uint32_t> children[6]; // [0]:num_left_arcs, [1]:num_right_arcs; [2]: leftmost_arc, [3]: second_leftmost_arc, [4]:rightmost_arc, [5]: second_rightmost_arc
  example * ec_buf[13];
  bool old_style_labels;
  bool cost_to_go, one_learner;
  uint32_t transition_system;
};

namespace DepParserTask
{
using namespace Search;

const action SHIFT        = 1;
const action REDUCE_RIGHT = 2;
const action REDUCE_LEFT  = 3;
const action REDUCE       = 4;
const uint32_t my_null = 9999999; /*representing_defalut*/

void initialize(Search::search& sch, size_t& /*num_actions*/, po::variables_map& vm)
{ vw& all = sch.get_vw_pointer_unsafe();
  task_data *data = new task_data();
  data->action_loss.resize(5);
  data->ex = NULL;
  sch.set_task_data<task_data>(data);

  new_options(all, "Dependency Parser Options")
  ("root_label", po::value<size_t>(&(data->root_label))->default_value(8), "Ensure that there is only one root in each sentence")
  ("num_label", po::value<uint32_t>(&(data->num_label))->default_value(12), "Number of arc labels")
  ("transition_system", po::value<uint32_t>(&(data->transition_system))->default_value(1), "1: arc-hybrid 2: arc-eager")
  ("one_learner", "Using one learner instead of three learners for labeled parser")
  ("cost_to_go", "Estimating cost-to-go matrix based on dynamic oracle rathan than rolling-out")
  ("old_style_labels", "Use old hack of label information");  
  add_options(all);

  check_option<size_t>(data->root_label, all, vm, "root_label", false, size_equal,
                       "warning: you specified a different value for --root_label than the one loaded from regressor. proceeding with loaded value: ", "");
  check_option<uint32_t>(data->num_label, all, vm, "num_label", false, uint32_equal,
                         "warning: you specified a different value for --num_label than the one loaded from regressor. proceeding with loaded value: ", "");
  check_option(data->old_style_labels, all, vm, "old_style_labels", false,
               "warning: you specified a different value for --old_style_labels than the one loaded from regressor. proceeding with loaded value: ");
  check_option(data->cost_to_go, all, vm, "cost_to_go", false,
               "warning: you specified a different value for --cost_to_go than the one loaded from regressor. proceeding with loaded value: ");
  check_option(data->one_learner, all, vm, "one_learner", false,
               "warning: you specified a different value for --one_learner than the one loaded from regressor. proceeding with loaded value: ");
  check_option<uint32_t>(data->transition_system, all, vm, "transition_system", false, uint32_equal,
                         "warning: you specified a different value for --transition_system than the one loaded from regressor. proceeding with loaded value: ", "");

  data->ex = VW::alloc_examples(sizeof(polylabel), 1);
  data->ex->indices.push_back(val_namespace);
  for(size_t i=1; i<14; i++)
    data->ex->indices.push_back((unsigned char)i+'A');
  data->ex->indices.push_back(constant_namespace);

  data->old_style_labels = vm.count("old_style_labels") > 0;
  if(data->one_learner)
    sch.set_num_learners(1);
  else
    sch.set_num_learners(3);

  const char* pair[] = {"BC", "BE", "BB", "CC", "DD", "EE", "FF", "GG", "EF", "BH", "BJ", "EL", "dB", "dC", "dD", "dE", "dF", "dG", "dd"};
  const char* triple[] = {"EFG", "BEF", "BCE", "BCD", "BEL", "ELM", "BHI", "BCC", "BEJ", "BEH", "BJK", "BEN"};
  vector<string> newpairs(pair, pair+19);
  vector<string> newtriples(triple, triple+12);
  all.pairs.swap(newpairs);
  all.triples.swap(newtriples);

  for (v_string& i : all.interactions)
    i.delete_v();
  all.interactions.erase();
  for (string& i : all.pairs)
    all.interactions.push_back(string2v_string(i));
  for (string& i : all.triples)
    all.interactions.push_back(string2v_string(i));
  if(data->cost_to_go)
    sch.set_options(AUTO_CONDITION_FEATURES | NO_CACHING | ACTION_COSTS);
  else
    sch.set_options(AUTO_CONDITION_FEATURES | NO_CACHING );

  sch.set_label_parser( COST_SENSITIVE::cs_label, [](polylabel&l) -> bool { return l.cs.costs.size() == 0; });
}

void finish(Search::search& sch)
{ task_data *data = sch.get_task_data<task_data>();
  data->valid_actions.delete_v();
  data->valid_action_temp.delete_v();
  data->gold_heads.delete_v();
  data->gold_tags.delete_v();
  data->stack.delete_v();
  data->heads.delete_v();
  data->tags.delete_v();
  data->temp.delete_v();
  data->action_loss.delete_v();
  data->gold_actions.delete_v();
  data->gold_action_losses.delete_v();
  data->gold_action_temp.delete_v();
  VW::dealloc_example(COST_SENSITIVE::cs_label.delete_label, *data->ex);
  free(data->ex);
  for (size_t i=0; i<6; i++) data->children[i].delete_v();
  delete data;
}

void inline add_feature(example& ex, uint64_t idx, unsigned char ns, uint64_t mask, uint64_t multiplier, bool audit=false)
{
  ex.feature_space[(int)ns].push_back(1.0f, (idx * multiplier) & mask);
}

void add_all_features(example& ex, example& src, unsigned char tgt_ns, uint64_t mask, uint64_t multiplier, uint64_t offset, bool audit=false)
{
  features& tgt_fs = ex.feature_space[tgt_ns];
  for (namespace_index ns : src.indices)
    if(ns != constant_namespace) // ignore constant_namespace
        for (feature_index i : src.feature_space[ns].indicies)
            tgt_fs.push_back(1.0f, ((i / multiplier + offset) * multiplier) & mask );
}

void inline reset_ex(example *ex)
{ ex->num_features = 0;
  ex->total_sum_feat_sq = 0;
  for (features& fs : *ex)
    fs.erase();
}

// arc-hybrid System.
size_t transition_hybrid(Search::search& sch, uint64_t a_id, uint32_t idx, uint32_t t_id, uint32_t n)
{ task_data *data = sch.get_task_data<task_data>();
  v_array<uint32_t> &heads=data->heads, &stack=data->stack, &gold_heads=data->gold_heads, &gold_tags=data->gold_tags, &tags = data->tags;
  v_array<uint32_t> *children = data->children;
  if (a_id == SHIFT)
  { stack.push_back(idx);
    return idx+1;
  }
  else if (a_id == REDUCE_RIGHT)
  { uint32_t last   = stack.last();
    uint32_t   hd   = stack[ stack.size() - 2 ];
    heads[last]     = hd;
    children[5][hd] = children[4][hd];
    children[4][hd] = last;
    children[1][hd] ++;
    tags[last]      = t_id;
    sch.loss(gold_heads[last] != heads[last] ? 2 : (gold_tags[last] != t_id) ? 1.f : 0.f);
    assert(! stack.empty());
    stack.pop();
    return idx;
  }
  else if (a_id == REDUCE_LEFT)
  { size_t last     = stack.last();
    uint32_t hd     = idx;
    heads[last]     = hd;
    children[3][hd] = children[2][hd];
    children[2][hd] = last;
    children[0][hd] ++;
    tags[last]      = t_id;
    sch.loss(gold_heads[last] != heads[last] ? 2 : (gold_tags[last] != t_id) ? 1.f : 0.f);
    assert(! stack.empty());
    stack.pop();
    return idx;
  }
  THROW("transition_hybrid failed");
}

// arc-eager system
size_t transition_eager(Search::search& sch, uint64_t a_id, uint32_t idx, uint32_t t_id, uint32_t n)
{ task_data *data = sch.get_task_data<task_data>();
  v_array<uint32_t> &heads=data->heads, &stack=data->stack, &gold_heads=data->gold_heads, &gold_tags=data->gold_tags, &tags = data->tags;
  v_array<uint32_t> *children = data->children;
  if (a_id == SHIFT)
  { stack.push_back(idx);
    return idx+1;
  }
  else if (a_id == REDUCE_RIGHT)
  { uint32_t hd   = stack.last();
    stack.push_back(idx);
    uint32_t last = idx;    
    heads[last]     = hd;
    children[5][hd] = children[4][hd];
    children[4][hd] = last;
    children[1][hd] ++;
    tags[last]      = t_id;
    sch.loss(gold_heads[last] != heads[last] ? 2 : (gold_tags[last] != t_id) ? 1.f : 0.f);
    return idx+1;
  }
  else if (a_id == REDUCE_LEFT)
  { size_t last     = stack.last();
    uint32_t hd     = (idx >n)? 0:idx;
    heads[last]     = hd;
    children[3][hd] = children[2][hd];
    children[2][hd] = last;
    children[0][hd] ++;
    tags[last]      = t_id;
    sch.loss(gold_heads[last] != heads[last] ? 2 : (gold_tags[last] != t_id) ? 1.f : 0.f);
    assert(! stack.empty());
    stack.pop();
    return idx;
  }
  else if (a_id == REDUCE)
  {
    assert(! stack.empty());
    stack.pop();
    return idx;
  }
  THROW("transition_eager failed");
}

void extract_features(Search::search& sch, uint32_t idx,  vector<example*> &ec)
{ vw& all = sch.get_vw_pointer_unsafe();
  task_data *data = sch.get_task_data<task_data>();
  reset_ex(data->ex);
  uint64_t mask = sch.get_mask();
  uint64_t multiplier = all.wpp << all.reg.stride_shift;
  v_array<uint32_t> &stack = data->stack, &tags = data->tags, *children = data->children, &temp=data->temp;
  example **ec_buf = data->ec_buf;
  example &ex = *(data->ex);

  size_t n = ec.size();
  bool empty = stack.empty();
  size_t last = empty ? 0 : stack.last();

  for(size_t i=0; i<13; i++)
    ec_buf[i] = nullptr;

  // feature based on the top three examples in stack ec_buf[0]: s1, ec_buf[1]: s2, ec_buf[2]: s3
  for(size_t i=0; i<3; i++)
    ec_buf[i] = (stack.size()>i && *(stack.end()-(i+1))!=0) ? ec[*(stack.end()-(i+1))-1] : 0;

  // features based on examples in string buffer ec_buf[3]: b1, ec_buf[4]: b2, ec_buf[5]: b3
  for(size_t i=3; i<6; i++)
    ec_buf[i] = (idx+(i-3)-1 < n) ? ec[idx+i-3-1] : 0;

  // features based on the leftmost and the rightmost children of the top element stack ec_buf[6]: sl1, ec_buf[7]: sl2, ec_buf[8]: sr1, ec_buf[9]: sr2;
  for(size_t i=6; i<10; i++)
    if (!empty && last != 0&& children[i-4][last]!=0)
      ec_buf[i] = ec[children[i-4][last]-1];

  // features based on leftmost children of the top element in bufer ec_buf[10]: bl1, ec_buf[11]: bl2
  for(size_t i=10; i<12; i++)
    ec_buf[i] = (idx <=n && children[i-8][idx]!=0) ? ec[children[i-8][idx]-1] : 0;
  ec_buf[12] = (stack.size()>1 && *(stack.end()-2)!=0 && children[2][*(stack.end()-2)]!=0) ? ec[children[2][*(stack.end()-2)]-1] : 0;

  // unigram features
  for(size_t i=0; i<13; i++)
  { uint64_t additional_offset = (uint64_t)(i*offset_const);
    if (!ec_buf[i])
      add_feature(ex, (uint64_t) 438129041 + additional_offset, (unsigned char)((i+1)+'A'), mask, multiplier);
    else
      add_all_features(ex, *ec_buf[i], 'A'+(unsigned char)(i+1), mask, multiplier, additional_offset, false);
  }

  // Other features
  temp.resize(10);
  temp[0] = empty ? 0: (idx >n? 1: 2+min(5, idx - (uint64_t)last));
  temp[1] = empty? 1: 1+min(5, children[0][last]);
  temp[2] = empty? 1: 1+min(5, children[1][last]);
  temp[3] = idx>n? 1: 1+min(5 , children[0][idx]);
  for(size_t i=4; i<8; i++)
    temp[i] = (!empty && children[i-2][last]!=0)?tags[children[i-2][last]]:15;
  for(size_t i=8; i<10; i++)
    temp[i] = (idx <=n && children[i-6][idx]!=0)? tags[children[i-6][idx]] : 15;

  uint64_t additional_offset = val_namespace*offset_const;
  for(size_t j=0; j< 10; j++)
  {
    additional_offset += j* 1023;
    add_feature(ex, temp[j]+ additional_offset , val_namespace, mask, multiplier);
  }
  size_t count=0;
  for (features fs : *data->ex)
    { fs.sum_feat_sq = (float) fs.size();
      count+= fs.size();
    }

  size_t new_count;
  float new_weight;
  INTERACTIONS::eval_count_of_generated_ft(all, *data->ex, new_count, new_weight);

  data->ex->num_features = count + new_count;
  data->ex->total_sum_feat_sq = (float) count + new_weight;
}

void get_valid_actions(Search::search &sch, v_array<uint32_t> & valid_action, uint64_t idx, uint64_t n, uint64_t stack_depth, uint64_t state)
{ task_data *data = sch.get_task_data<task_data>();
  uint32_t &sys = data->transition_system;
  v_array<uint32_t> &stack = data->stack, &heads = data->heads, &temp = data->temp;
  valid_action.erase();
  if(sys == arc_hybrid)
  { if(idx<=n) // SHIFT
      valid_action.push_back( SHIFT );
    if(stack_depth >=2) // RIGHT
      valid_action.push_back( REDUCE_RIGHT );  
    if(stack_depth >=1 && state!=0 && idx<=n) // LEFT
      valid_action.push_back( REDUCE_LEFT );
  } 
  else if(sys == arc_eager) // assume root is in N+1
  { temp.erase();
    for(size_t i=0; i<=4; i++)
      temp.push_back(1);
    if (idx>n) 
    { temp[SHIFT] = 0;
      temp[REDUCE_RIGHT] = 0;
    }

    if (stack_depth==0)
      temp[REDUCE] = 0;
    else if (idx<=n+1 && heads[stack.last()] == my_null)
      temp[REDUCE] = 0;

    if(stack_depth ==0)    
    { temp[REDUCE_LEFT] = 0;
      temp[REDUCE_RIGHT] = 0;
    } else
    { if(heads[stack.last()]!=my_null) temp[REDUCE_LEFT] = 0;
      if(idx <=n && heads[idx] != my_null) temp[REDUCE_RIGHT] = 0;     
    }
    for(size_t i=1; i<=4; i++){
      if(temp[i]) valid_action.push_back(i);
    }
  }
}

bool is_valid(uint64_t action, v_array<uint32_t> valid_actions)
{ for(size_t i=0; i< valid_actions.size(); i++)
    if(valid_actions[i] == action)
      return true;
  return false;
}

void get_eager_action_cost(Search::search &sch, uint32_t idx, uint64_t n)
{ task_data *data = sch.get_task_data<task_data>();
  v_array<uint32_t> &action_loss = data->action_loss, &stack = data->stack, &gold_heads=data->gold_heads, heads=data->heads;
  size_t size = stack.size();
  size_t last = (size==0) ? 0 : stack.last();
  for(size_t i = 1; i<= 4; i++)
    action_loss[i] = 0;
  if(!stack.empty())
    for(size_t i = 0; i<size; i++)
    { if(gold_heads[stack[i]] == idx && heads[stack[i]] == my_null)
      { action_loss[SHIFT] += 1;
        action_loss[REDUCE_RIGHT] +=1;
      }
      if(idx <=n && (gold_heads[idx] == stack[i]))
      { if(stack[i]!=0) action_loss[SHIFT] += 1;
        if(stack[i]!=last) action_loss[REDUCE_RIGHT]+=1;         
      }
    }
  for(size_t i = idx; i<=n+1; i++)
  { if(i<=n && gold_heads[i] == last)
    { action_loss[REDUCE] +=1;
      action_loss[REDUCE_LEFT] +=1;
    }
    if(i!=idx && gold_heads[last] == i)
      action_loss[REDUCE_LEFT] +=1;
  }
  //if(size>0  && idx <=n && gold_heads[last] == 0 && stack[0] ==0) //should not fire
  //  action_loss[REDUCE_LEFT] +=1;

  if(gold_heads[idx] > idx || (gold_heads[idx] == 0 && size > 0 && stack[0]!=0))
    action_loss[REDUCE_RIGHT] +=1;
}

void get_hybrid_action_cost(Search::search &sch, size_t idx, uint64_t n)
{ task_data *data = sch.get_task_data<task_data>();
  v_array<uint32_t> &action_loss = data->action_loss, &stack = data->stack, &gold_heads=data->gold_heads;
  size_t size = stack.size();
  size_t last = (size==0) ? 0 : stack.last();  

  for(size_t i = 1; i<= 3; i++)
    action_loss[i] = 0;
  if(!stack.empty())
    for(size_t i = 0; i<size-1; i++)
      if(idx <=n && (gold_heads[stack[i]] == idx || gold_heads[idx] == stack[i]))
        action_loss[SHIFT] += 1;

  if(size>0 && gold_heads[last] == idx)
    action_loss[SHIFT] += 1;

  for(size_t i = idx+1; i<=n; i++)
    if(gold_heads[i] == last|| gold_heads[last] == i)
      action_loss[REDUCE_LEFT] +=1;
  if(size>0  && idx <=n && gold_heads[idx] == last)
    action_loss[REDUCE_LEFT] +=1;
  if(size>=2 && gold_heads[last] == stack[size-2])
    action_loss[REDUCE_LEFT] += 1;

  if(gold_heads[last] >= idx)
    action_loss[REDUCE_RIGHT] +=1;
 
  for(size_t i = idx; i<=n; i++)
    if(gold_heads[i] == (uint32_t)last)
      action_loss[REDUCE_RIGHT] +=1;
}

void get_cost_to_go_losses(Search::search &sch, v_array<pair<action, float>>& gold_action_losses, uint32_t left_label, uint32_t right_label)
{ task_data *data = sch.get_task_data<task_data>();
  bool &one_learner = data->one_learner;
  uint32_t &sys = data->transition_system;
  v_array<uint32_t> &action_loss = data->action_loss, &valid_actions=data->valid_actions;
  uint32_t &num_label = data->num_label;
  gold_action_losses.erase();

  if(one_learner)
  { if(is_valid(SHIFT, valid_actions))
      gold_action_losses.push_back(make_pair(SHIFT, action_loss[SHIFT]));
    for(size_t i=2; i<=3; i++)
      if(is_valid(i, valid_actions))
      { for(size_t j=1; j<=num_label; j++)
          if(sys==arc_eager || j!=data->root_label)
            gold_action_losses.push_back(make_pair((1+j+(i-2)*num_label), action_loss[i]+(float)(j != (i==REDUCE_LEFT? left_label:right_label))));
      }
    if(sys==arc_eager && is_valid(REDUCE, valid_actions))
      gold_action_losses.push_back(make_pair(2+num_label*2, action_loss[REDUCE]));
  }
  else
  { for(size_t i=1; i<=3; i++)
      if(is_valid(i, valid_actions))
        gold_action_losses.push_back(make_pair(i, (float)action_loss[i]));
    if(sys==arc_eager && is_valid(REDUCE, valid_actions))
        gold_action_losses.push_back(make_pair(REDUCE, (float)action_loss[REDUCE]));
  }
}

void get_gold_actions(Search::search &sch, uint32_t idx, uint64_t n, v_array<action>& gold_actions)
{ task_data *data = sch.get_task_data<task_data>();
  v_array<uint32_t> &action_loss = data->action_loss, &stack = data->stack, &gold_heads=data->gold_heads, &valid_actions=data->valid_actions;
  gold_actions.erase();
  size_t size = stack.size();
  size_t last = (size==0) ? 0 : stack.last();
  uint32_t &sys = data->transition_system;

  if (sys==arc_hybrid && is_valid(SHIFT,valid_actions) &&( stack.empty() || gold_heads[idx] == last) )
  { gold_actions.push_back(SHIFT);
    return;
  }

  if (sys==arc_hybrid && is_valid(REDUCE_LEFT,valid_actions) && gold_heads[last] == idx)
  { gold_actions.push_back(REDUCE_LEFT);
    return;
  }  
  size_t best_action = 1;
  size_t count = 0;
  for(size_t i=1; i<=4; i++)
  { if(i==4 && sys==arc_hybrid)
      continue;
    if(action_loss[i] < action_loss[best_action] && is_valid(i,valid_actions))
    { best_action= i;
      count = 1;
      gold_actions.erase();
      gold_actions.push_back((uint32_t)i);
    }
    else if (action_loss[i] == action_loss[best_action] && is_valid(i,valid_actions))
    { count++;
      gold_actions.push_back(i);
    }
  }
}

void convert_to_onelearner_actions(Search::search &sch, v_array<action> &actions, v_array<action> &actions_onelearner, uint32_t left_label, uint32_t right_label)
{ task_data *data = sch.get_task_data<task_data>();
  uint32_t &sys = data->transition_system;
  uint32_t &num_label = data->num_label;
  actions_onelearner.erase();
  if(is_valid(SHIFT, actions)) actions_onelearner.push_back(SHIFT);
  if(sys==arc_eager && is_valid(REDUCE, actions)) actions_onelearner.push_back(2+2*num_label);
  if(left_label!=my_null && is_valid(REDUCE_RIGHT, actions)) actions_onelearner.push_back(1+right_label);
  if(left_label!=my_null && is_valid(REDUCE_LEFT, actions)) actions_onelearner.push_back(1+left_label+num_label);  
  if(left_label==my_null && is_valid(REDUCE_RIGHT, actions))
     for(size_t i=0; i< num_label; i++)
       if(i!=data->root_label-1)
           actions_onelearner.push_back(i+2);  
  if(left_label==my_null && is_valid(REDUCE_LEFT, actions))
          for(size_t i=0; i<num_label; i++)
            if(sys==arc_eager || i!=data->root_label-1)
              actions_onelearner.push_back(i+2+num_label);
}     

void setup(Search::search& sch, vector<example*>& ec)
{ task_data *data = sch.get_task_data<task_data>();
  v_array<uint32_t> &gold_heads=data->gold_heads, &heads=data->heads, &gold_tags=data->gold_tags, &tags=data->tags;
  size_t n = ec.size();
  heads.resize(n+1);
  tags.resize(n+1);
  gold_heads.erase();
  gold_heads.push_back(0);
  gold_tags.erase();
  gold_tags.push_back(0);
  for (size_t i=0; i<n; i++)
  { v_array<COST_SENSITIVE::wclass>& costs = ec[i]->l.cs.costs;
    size_t head,tag;
    if (data->old_style_labels)
    { uint32_t label = costs[0].class_index;
      head = (label & 255) -1;
      tag  = label >> 8;
    }
    else
    { head = (costs.size() == 0) ? 0 : costs[0].class_index;
      tag  = (costs.size() <= 1) ? (uint64_t)data->root_label : costs[1].class_index;
    }
    if (tag > data->num_label)
      THROW("invalid label " << tag << " which is > num actions=" << data->num_label);

    gold_heads.push_back(head);
    gold_tags.push_back(tag);
    heads[i+1] = my_null;
    tags[i+1] = my_null;
  }
  for(size_t i=0; i<6; i++)
    data->children[i].resize(n+(size_t)1);
}

void run(Search::search& sch, vector<example*>& ec)
{ task_data *data = sch.get_task_data<task_data>();
  v_array<uint32_t> &stack=data->stack, &gold_heads=data->gold_heads, &valid_actions=data->valid_actions, &heads=data->heads, &gold_tags=data->gold_tags, &tags=data->tags, &valid_action_temp = data->valid_action_temp;
  v_array<uint32_t> &gold_action_temp = data->gold_action_temp;
  v_array<pair<action, float>> &gold_action_losses=data->gold_action_losses;
  v_array<action> &gold_actions = data->gold_actions;
  bool &cost_to_go = data->cost_to_go, &one_learner = data->one_learner;
  uint32_t &num_label = data->num_label;
  uint32_t &sys = data->transition_system;
  uint64_t n = (uint64_t) ec.size();
  uint32_t left_label, right_label;
  stack.erase();
  stack.push_back((data->root_label==0&&sys==arc_hybrid)?0:1);
  for(size_t i=0; i<6; i++)
    for(size_t j=0; j<n+1; j++)
      data->children[i][j] = 0;  
  for(size_t i=0; i<n; i++)  
  { heads[i+1] = my_null;
    tags[i+1] = my_null;
  }
  size_t count=1;
  size_t idx = ((data->root_label==0&&sys==arc_hybrid)?1:2);
  Search::predictor P(sch, (ptag) 0);
  while(true)
  { if(sys==arc_hybrid && stack.size()<=1 && idx > n)
      break;
    else if (sys==arc_eager && stack.size()==0 && idx > n)
      break;
    bool computedFeatures = false;
    if(sch.predictNeedsExample())
    { extract_features(sch, idx, ec);
        computedFeatures = true;
    }
    get_valid_actions(sch, valid_actions, idx, n, (uint64_t) stack.size(), stack.empty() ? 0 : stack.last());
    if(sys == arc_hybrid)
      get_hybrid_action_cost(sch, idx, n);
    else if(sys == arc_eager)
      get_eager_action_cost(sch,idx,n);

    // get gold tag labels
    left_label = stack.empty()?my_null:gold_tags[stack.last()];
    if(sys==arc_hybrid) right_label = stack.empty()?my_null:gold_tags[stack.last()];
    else if(sys==arc_eager) right_label = idx<=n? gold_tags[idx] : (uint32_t) data->root_label;	
    else THROW("unknown transition system");

    size_t a_id = 0, t_id = 0;
    if(one_learner)
    { if(cost_to_go)
      { get_cost_to_go_losses(sch, gold_action_losses, left_label, right_label);
        a_id= P.set_tag((ptag) count)
              .set_input(*(data->ex))
              .set_allowed(gold_action_losses)
              .set_condition_range(count-1, sch.get_history_length(), 'p')
              .set_learner_id(0)
              .predict();
      }
      else
      { get_gold_actions(sch, idx, n, gold_actions);        
        convert_to_onelearner_actions(sch, gold_actions, gold_action_temp, left_label, right_label);
        convert_to_onelearner_actions(sch, valid_actions, valid_action_temp, my_null, my_null);
        a_id = P.set_tag((ptag) count)
               .set_input(*(data->ex))
               .set_oracle(gold_action_temp)
               .set_allowed(valid_action_temp)
               .set_condition_range(count-1, sch.get_history_length(), 'p')
               .set_learner_id(0)
               .predict();
      }
      if (a_id == SHIFT) t_id = 0;
      else if(a_id == 2*num_label+2)
      { t_id = 0;
        a_id = REDUCE;
      }
      else if(a_id>1 && a_id-1 <= num_label)
      { t_id = a_id-1;
        a_id = REDUCE_RIGHT;
      }
      else
      { t_id = (uint64_t)a_id-num_label-1;
        a_id = REDUCE_LEFT;
      }
    }
    else
    { if(cost_to_go)
      { get_cost_to_go_losses(sch, gold_action_losses, left_label, right_label);
        a_id= P.set_tag((ptag) count)
              .set_input(*(data->ex))
              .set_allowed(gold_action_losses)
              .set_condition_range(count-1, sch.get_history_length(), 'p')
              .set_learner_id(0)
              .predict();
      }
      else
      { get_gold_actions(sch, idx, n, gold_actions);
        a_id= P.set_tag((ptag) count)
              .set_input(*(data->ex))
              .set_oracle(gold_actions)
              .set_allowed(valid_actions)
              .set_condition_range(count-1, sch.get_history_length(), 'p')
              .set_learner_id(0)
              .predict();
      }

      // Predict the next action {SHIFT, REDUCE_LEFT, REDUCE_RIGHT}
      count++;

      if (a_id != SHIFT && a_id != REDUCE )
      { if ((!computedFeatures) && sch.predictNeedsExample()) 
          extract_features(sch, idx, ec);

        if(cost_to_go)
        { gold_action_losses.erase();
          for(size_t i=1; i<= data->num_label; i++)
            gold_action_losses.push_back(make_pair((action)i, i != (a_id==REDUCE_LEFT?left_label:right_label)));
            t_id = P.set_tag((ptag) count) 
                 .set_input(*(data->ex))
                 .set_allowed(gold_action_losses)
                 .set_condition_range(count-1, sch.get_history_length(), 'p')
                 .set_learner_id(a_id-1)
                 .predict();
        }
        else
        { t_id = P.set_tag((ptag) count)
                 .set_input(*(data->ex))
                 .set_oracle(a_id==REDUCE_LEFT?left_label:right_label)
                 .erase_alloweds()
                 .set_condition_range(count-1, sch.get_history_length(), 'p')
                 .set_learner_id(a_id-1)
                 .predict();                 
        }
      }
    }
    count++;
    if(sys==arc_hybrid)
        idx = transition_hybrid(sch, a_id, idx, t_id, n);
    else if(sys==arc_eager)
        idx = transition_eager(sch, a_id, idx, t_id, n);
  }
  if(sys==arc_hybrid)
  {   heads[stack.last()] = 0;
      tags[stack.last()] = (uint64_t)data->root_label;
      sch.loss((gold_heads[stack.last()] != heads[stack.last()]));
  }
  if (sch.output().good())
    for(size_t i=1; i<=n; i++)
      sch.output() << (heads[i])<<":"<<tags[i] << endl;
}
}
