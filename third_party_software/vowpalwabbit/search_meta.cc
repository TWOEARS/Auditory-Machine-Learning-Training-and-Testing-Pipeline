/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD (revised)
license as described in the file LICENSE.
 */
#include <float.h>
#include <errno.h>

#include "reductions.h"
#include "vw.h"
#include "search.h"

using namespace std;
namespace DebugMT
{
void run(Search::search& sch, vector<example*>& ec);
Search::search_metatask metatask = { "debug", run, nullptr, nullptr, nullptr, nullptr };

void run(Search::search& sch, vector<example*>& ec)
{ sch.base_task(ec)
  .foreach_action(
    [](Search::search& /*sch*/, size_t t, float min_cost, action a, bool taken, float a_cost) -> void
  { cerr << "==DebugMT== foreach_action(t=" << t << ", min_cost=" << min_cost << ", a=" << a << ", taken=" << taken << ", a_cost=" << a_cost << ")" << endl;
  })

  .post_prediction(
    [](Search::search& /*sch*/, size_t t, action a, float a_cost) -> void
  { cerr << "==DebugMT== post_prediction(t=" << t << ", a=" << a << ", a_cost=" << a_cost << ")" << endl;
  })

  .maybe_override_prediction(
    [](Search::search& /*sch*/, size_t t, action& a, float& a_cost) -> bool
  { cerr << "==DebugMT== maybe_override_prediction(t=" << t << ", a=" << a << ", a_cost=" << a_cost << ")" << endl;
    return false;
  })

  .final_run()

  .Run();
}
}

namespace SelectiveBranchingMT
{
void run(Search::search& sch, vector<example*>& ec);
void initialize(Search::search& sch, size_t& num_actions, po::variables_map& vm);
void finish(Search::search& sch);
Search::search_metatask metatask = { "selective_branching", run, initialize, finish, nullptr, nullptr };

typedef pair<action,float>  act_score;
typedef v_array<act_score>  path;
typedef pair< float, path > branch;

std::ostream& operator<<(std::ostream& os, const std::pair<unsigned int,float>& v) { os << v.first << '_' << v.second; return os; }

struct task_data
{ size_t max_branches, kbest;
  v_array< branch > branches;
  v_array< pair<branch,string*> > final;
  path trajectory;
  float total_cost;
  size_t cur_branch;
  string*output_string;
  stringstream*kbest_out;
  task_data(size_t mb, size_t kb) : max_branches(mb), kbest(kb)
  { branches   = v_init<branch>();
    final      = v_init< pair<branch,string*> >();
    trajectory = v_init<act_score>();
    output_string = nullptr;
    kbest_out     = nullptr;
  }
  ~task_data()
  { branches.delete_v();
    final.delete_v();
    trajectory.delete_v();
    if (output_string) delete output_string;
    if (kbest_out) delete kbest_out;
  }
};

void initialize(Search::search& sch, size_t& /*num_actions*/, po::variables_map& vm)
{ size_t max_branches = 2;
  size_t kbest = 0;
  po::options_description opts("selective branching options");
  opts.add_options()
  ("search_max_branch", po::value<size_t>(&max_branches)->default_value(2), "maximum number of branches to consider")
  ("search_kbest",      po::value<size_t>(&kbest)->default_value(0), "number of best items to output (0=just like non-selectional-branching, default)");
  sch.add_program_options(vm, opts);

  task_data* d = new task_data(max_branches, kbest);
  sch.set_metatask_data(d);
}

void finish(Search::search& sch) { delete sch.get_metatask_data<task_data>(); }

void run(Search::search& sch, vector<example*>& ec)
{ task_data& d = *sch.get_metatask_data<task_data>();

  // generate an initial trajectory, but record possible branches
  d.branches.erase();
  d.final.erase();
  d.trajectory.erase();
  d.total_cost = 0.;
  d.output_string = nullptr;

  cdbg << "*** INITIAL PASS ***" << endl;
  sch.base_task(ec)
  .foreach_action(
    [](Search::search& sch, size_t t, float min_cost, action a, bool taken, float a_cost) -> void
  { cdbg << "==DebugMT== foreach_action(t=" << t << ", min_cost=" << min_cost << ", a=" << a << ", taken=" << taken << ", a_cost=" << a_cost << ")" << endl;
    if (taken) return;  // ignore the taken action
    task_data& d = *sch.get_metatask_data<task_data>();
    float delta = a_cost - min_cost;
    path branch = v_init<act_score>();
    push_many<act_score>(branch, d.trajectory.begin(), d.trajectory.size());
    branch.push_back( make_pair(a,a_cost) );
    d.branches.push_back( make_pair(delta, branch) );
    cdbg << "adding branch: " << delta << " -> " << branch << endl;
  })
  .post_prediction(
    [](Search::search& sch, size_t /*t*/, action a, float a_cost) -> void
  { task_data& d = *sch.get_metatask_data<task_data>();
    d.trajectory.push_back( make_pair(a,a_cost) );
    d.total_cost += a_cost;
  })
  .with_output_string(
    [](Search::search& sch, stringstream& output) -> void
  { sch.get_metatask_data<task_data>()->output_string = new string(output.str());
  })
  .Run();

  // the last item the trajectory stack is complete and therefore not a branch
  //if (! d.branches.empty())
  //  d.branches.pop().second.delete_v();

  { // construct the final trajectory
    path original_final = v_init<act_score>();
    copy_array(original_final, d.trajectory);
    d.final.push_back( make_pair(make_pair(d.total_cost, original_final), d.output_string) );
  }

  // sort the branches by cost
  stable_sort(d.branches.begin(), d.branches.end(),
              [](const branch& a, const branch& b) -> bool { return a.first < b.first; });

  // make new predictions
  for (size_t i=0; i<min(d.max_branches, d.branches.size()); i++)
  { d.cur_branch = i;
    d.trajectory.erase();
    d.total_cost = 0.;
    d.output_string = nullptr;

    cdbg << "*** BRANCH " << i << " *** " << d.branches[i].first << " : " << d.branches[i].second << endl;
    sch.base_task(ec)
    .foreach_action([](Search::search& /*sch*/, size_t /*t*/, float /*min_cost*/, action /*a*/, bool /*taken*/, float /*a_cost*/) -> void {})
    .maybe_override_prediction(
      [](Search::search& sch, size_t t, action& a, float& a_cost) -> bool
    { task_data& d = *sch.get_metatask_data<task_data>();
      path& path = d.branches[d.cur_branch].second;
      if (t >= path.size()) return false;
      a = path[t].first;
      a_cost = path[t].second;
      return true;
    })
    .post_prediction(
      [](Search::search& sch, size_t /*t*/, action a, float a_cost) -> void
    { task_data& d = *sch.get_metatask_data<task_data>();
      d.trajectory.push_back( make_pair(a,a_cost) );
      d.total_cost += a_cost;
    })
    .with_output_string(
      [](Search::search& sch, stringstream& output) -> void
    { sch.get_metatask_data<task_data>()->output_string = new string(output.str());
    })
    .Run();

    { // construct the final trajectory
      path this_final = v_init<act_score>();
      copy_array(this_final, d.trajectory);
      d.final.push_back( make_pair(make_pair(d.total_cost, this_final), d.output_string) );
    }
  }

  // sort the finals by cost
  stable_sort(d.final.begin(), d.final.end(),
              [](const pair<branch,string*>& a, const pair<branch,string*>& b) -> bool { return a.first.first < b.first.first; });

  d.kbest_out = nullptr;
  if (d.output_string && (d.kbest > 0))
  { d.kbest_out = new stringstream();
    for (size_t i=0; i<min(d.final.size(), d.kbest); i++)
      (*d.kbest_out) << *d.final[i].second << "\t" << d.final[i].first.first << endl;
  }

  // run the final selected trajectory
  cdbg << "*** FINAL ***" << endl;
  d.cur_branch = 0;
  d.output_string = nullptr;
  sch.base_task(ec)
  .foreach_action([](Search::search& /*sch*/, size_t /*t*/, float /*min_cost*/, action /*a*/, bool /*taken*/, float /*a_cost*/) -> void {})
  .maybe_override_prediction(
    [](Search::search& sch, size_t t, action& a, float& a_cost) -> bool
  { task_data& d = *sch.get_metatask_data<task_data>();
    path& path = d.final[d.cur_branch].first.second;
    if ((t >= path.size()) || (path[t].first == (action)-1)) return false;
    a = path[t].first;
    a_cost = path[t].second;
    return true;
  })
  .with_output_string(
    [](Search::search& sch, stringstream& output) -> void
  { task_data& d = *sch.get_metatask_data<task_data>();
    if (d.kbest_out)
    { output.str("");
      output << d.kbest_out->str();
    }
  })
  .final_run()
  .Run();

  // clean up memory
  for (size_t i=0; i<d.branches.size(); i++) d.branches[i].second.delete_v();
  d.branches.erase();
  for (size_t i=0; i<d.final.size(); i++) { d.final[i].first.second.delete_v(); delete d.final[i].second; }
  d.final.erase();
  if (d.kbest_out) delete d.kbest_out; d.kbest_out = nullptr;
}
}
