#include "interactions.h"
#include "vw_exception.h"
using namespace std;
namespace INTERACTIONS
{

/*
 *  Interactions preprocessing
 */

// expand namespace interactions if contain wildcards
// recursive function used internally in this module
void expand_namespacse_with_recursion(v_string& ns, v_array<v_string>& res, v_string& val,  size_t pos)
{ assert (pos <= ns.size());

  if (pos == ns.size())
  { // we're at the end of interaction

    // make copy of val
    v_string temp = v_init<unsigned char>();
    push_many(temp, val.begin(), val.size());
    // and store it in res
    res.push_back(temp);
    // don't free s memory as it's data will be used later
  }
  else
  {

    // we're at the middle of interaction
    if (ns[pos] != ':')
    { // not a wildcard
      val.push_back(ns[pos]);
      expand_namespacse_with_recursion(ns, res, val, pos + 1);
      --val.end(); // simplified val.pop() - i don't need value itself
    }
    else
    { for (unsigned char j = printable_start; j <= printable_end; ++j)
      { if (valid_ns(j))
        { val.push_back(j);
          expand_namespacse_with_recursion(ns, res, val, pos + 1);
          --val.end(); // simplified val.pop() - i don't need value itself
        }
      }
    }

  }
}

// expand namespace interactions if contain wildcards
// called from parse_args.cc
// process all interactions in a vector

v_array<v_string> expand_interactions(const vector<string>& vec, const size_t required_length, const string& err_msg)
{ v_array<v_string> res = v_init<v_string>();

  for (string const& i : vec)
  { const size_t len = i.length();
    if (required_length > 0 && len != required_length)
      // got strict requirement of interaction length and it was failed.
      { THROW(err_msg); }
    else if (len < 2)
      // regardles of required_length value this check is always performed
      THROW("error, feature interactions must involve at least two namespaces" << err_msg);

    v_string ns = string2v_string(i);
    v_string temp = v_init<unsigned char>();
    expand_namespacse_with_recursion(ns, res, temp, 0);
    temp.delete_v();
    ns.delete_v();
  }
  return res;
}


/*
 *   Sorting and filtering duplicate interactions
 */

// helper functions
// compares v_string
bool is_equal_v_string(v_string& a, v_string& b)
{ const size_t size = a.size();
  if (size != b.size()) {return false;}
  else if (size == 0) return true;

  unsigned char* ai = a.begin();
  unsigned char* bi = b.begin();
  while (ai != a.end())
    if (*ai != *bi) return false;
    else
    { ++ai; ++ bi;
    }
  return true;
}


// helper structure to restore original order of sorted data

struct ordered_interaction
{ size_t pos;
  unsigned char* data;
  size_t size;
};

// returns true if iteraction contains one or more duplicated namespaces
// with one exeption - returns false if interaction made of one namespace
// like 'aaa' as it has no sense to sort such things.

inline bool must_be_left_sorted(const ordered_interaction& oi)
{ if (oi.size <= 1) return true; // one letter in string - no need to sort

  bool diff_ns_found = false;
  bool pair_found = false;

  for (const unsigned char* i = oi.data; i != oi.data + oi.size - 1; ++i)
    if (*i == *(i+1)) // pair found
    { if (diff_ns_found) return true; // case 'abb'
      pair_found = true;

    }
    else
    { if (pair_found) return true; // case 'aab'
      diff_ns_found = true;
    }

  return false; // 'aaa' or 'abc'
}



// comparision function for qsort to sort namespaces in interaction
int comp_char (const void * a, const void * b)
{ return ( *(const char*)a - *(const char*)b );
}

// comparision function for std::sort to sort interactions by their data
bool comp_interaction (ordered_interaction a, ordered_interaction b)
{ if (a.size != b.size)
    return a.size < b.size;
  else
  { const int order = memcmp(a.data, b.data, a.size);
    // a.pos < b.pos is additional level of ordering (`AB` must always be prefered to `BA` bcs autotests might be inconsistent).
    return (order == 0)? a.pos < b.pos : order < 0;
  }
}

// comparision function for std::sort to sort interactions by their position (to restore original order)
bool comp_interaction_by_pos (ordered_interaction a, ordered_interaction b)
{ return a.pos < b.pos;
}

// helper function for unique() fork. Just compares interactions.
// it behave like operator == while comp_interaction() above behave like operator <
inline bool equal_interaction (const ordered_interaction& a, const ordered_interaction& b)
{ if (a.size != b.size)
    return false;
  else
    return memcmp(a.data, b.data, a.size) == 0;
}

// a fork of std::unique implementation
// made to free memory allocated by objects that overwritter by unique()
ordered_interaction* unique_intearctions(ordered_interaction* first, ordered_interaction* last)
{ if (first == last)
    return last;

  ordered_interaction* result = first;
  while (++first != last)
  { if (!equal_interaction(*result,*first))
    { *(++result) = std::move(*first);
    }
    else
      free(first->data); // for this line I forked std::unique()
  }
  return ++result;
}


// used from parse_args.cc
// filter duplecate namespaces treating them as unordered sets of namespaces.
// also sort namespaces in interactions containing duplicate namespaces to make sure they are grouped together.

void sort_and_filter_duplicate_interactions(v_array<v_string>& vec, bool filter_duplicates, size_t& removed_cnt, size_t& sorted_cnt)
{ const size_t cnt = vec.size();
  // 2 out parameters
  removed_cnt = 0;
  sorted_cnt = 0;

  // make a copy of vec and sort namespaces of every interaction in its copy
  v_array<ordered_interaction> vec_sorted = v_init<ordered_interaction>();

  size_t pos = 0;
  for (v_string& v : vec)
  { ordered_interaction oi;
    size_t size = v.size();
    // copy memory
    oi.data = calloc_or_throw<unsigned char>(size);
    memcpy(oi.data, v.begin(), size);

    // sort charcters in interaction string
    qsort(oi.data, size, sizeof(unsigned char), comp_char);
    oi.size = size;
    oi.pos = pos++; // save original order info
    vec_sorted.push_back(oi);
  }


  if (filter_duplicates) // filter dulicated interactions
  { // sort interactions (each interaction namespaces are sorted already)
    std::sort(vec_sorted.begin(), vec_sorted.end(), comp_interaction);
    // perform unique() for them - that destroys all duplicated data.
    ordered_interaction* new_end = unique_intearctions(vec_sorted.begin(), vec_sorted.end());
    vec_sorted.end() = new_end;              // correct new ending marker
    removed_cnt = cnt - vec_sorted.size(); // report count of removed duplicates
    std::sort(vec_sorted.begin(), vec_sorted.end(), comp_interaction_by_pos); // restore original order
  }


  // we have original vector and vector with duplicates removed + corresponding indexes in original vector
  // plus second vector's data is sorted. We can reuse it if we need interaction to be left sorted.
  // let's make a new vector from these two sources - without dulicates and with sorted data whenever it's needed.
  v_array<v_string> res = v_init<v_string>();
  pos = 0;

  for (INTERACTIONS::ordered_interaction& oi : vec_sorted)
  { size_t copy_pos = oi.pos;
    // if vec data has no corresponding record in vec_sorted then it's a duplicate and shall be destroyed
    while (pos < copy_pos) vec[pos++].delete_v();

    if (must_be_left_sorted(oi)) //check if it should be sorted in result vector
    { // if so - copy sorted data to result
      v_string v = v_init<unsigned char>();
      push_many(v, oi.data, oi.size);
      res.push_back(v);
      vec[pos].delete_v();
      ++sorted_cnt;
    }
    else   // else - move unsorted data to result
      res.push_back(vec[pos]);
    pos++;
    // sorted data is copied, not moved, bcs i'm lazy to write assignment operator between these two types.
    // thus we always must free it
    free(oi.data);
  }

  vec_sorted.delete_v(); // sorted array destroyed. It's data partially copied to the new array, partially destroyed
  vec.delete_v(); // original array destroyed. It's data partially moved to the new array, partially destroyed

  vec = res; // new array replaces original
}



/*
 *  Estimation of generated features properties
 */


// the code under DEBUG_EVAL_COUNT_OF_GEN_FT below is an alternative way of implementation of eval_count_of_generated_ft()
// it just calls generate_interactions() with small function which counts generated features and sums their squared values
// it's replaced with more fast (?) analytic solution but keeps just in case and for doublecheck.

//#define DEBUG_EVAL_COUNT_OF_GEN_FT
#ifdef DEBUG_EVAL_COUNT_OF_GEN_FT
struct eval_gen_data
{ size_t& new_features_cnt;
  float& new_features_value;
  eval_gen_data(size_t& features_cnt, float& features_value): new_features_cnt(features_cnt), new_features_value(features_value) {}
};

void ft_cnt(eval_gen_data& dat, float fx, uint32_t )
{ ++ dat.new_features_cnt;
  dat.new_features_value += fx * fx;
}
#endif

// lookup table of factorials up tu 21!
long long int fast_factorial[] = {1,1,2,6,24,120,720,5040,40320,362880,3628800,39916800,479001600,6227020800,87178291200,1307674368000,
                                  20922789888000,355687428096000,6402373705728000,121645100408832000,2432902008176640000
                                 };
const size_t size_fast_factorial = sizeof(fast_factorial)/sizeof(*fast_factorial);

// helper factorial function that allows to perform:
// n!/(n-k)! = (n-k+1)*(n-k+2)..*(n-1)*n
// by specifying n-k as second argument
// that helps to avoid size_t overflow for big n
// leave second argument = 1 to get regular factorial function

inline size_t factor(const size_t n, const size_t start_from = 1)
{ if (n <= 0) return 1;
  if (start_from == 1 && n < size_fast_factorial) return (size_t)fast_factorial[n];

  size_t res = 1;
  for (size_t i = start_from+1; i <= n; ++i) res *= i;
  return res;
}



// returns number of new features that will be generated for example and sum of their squared values

void eval_count_of_generated_ft(vw& all, example& ec, size_t& new_features_cnt, float& new_features_value)
{ new_features_cnt = 0;
  new_features_value = 0.;

  v_array<float> results = v_init<float>();

  if (all.permutations)
  { // just multiply precomputed values for all namespaces
    for (v_string& inter : all.interactions)
    { size_t num_features_in_inter = 1;
      float sum_feat_sq_in_inter = 1.;

      for (namespace_index ns : inter)
      { num_features_in_inter *= ec.feature_space[ns].size();
        sum_feat_sq_in_inter *= ec.feature_space[ns].sum_feat_sq;
        if (num_features_in_inter == 0) break;
      }

      if (num_features_in_inter == 0) continue;

      new_features_cnt += num_features_in_inter;
      new_features_value += sum_feat_sq_in_inter;
    }


  }
  else     // case of simple combinations
  {

#ifdef DEBUG_EVAL_COUNT_OF_GEN_FT
    size_t correct_features_cnt = 0;
    float correct_features_value = 0.;
    eval_gen_data dat(correct_features_cnt, correct_features_value);
    generate_interactions<eval_gen_data, uint32_t, ft_cnt>(all, ec, dat);
#endif

    for (v_string& inter : all.interactions)
    { size_t num_features_in_inter = 1;
      float sum_feat_sq_in_inter = 1.;

      for (namespace_index* ns = inter.begin(); ns != inter.end(); ++ns)
      { if ((ns == inter.end()-1) || (*ns != *(ns + 1))) // neighbour namespaces are different
        { // just multiply precomputed values
          const int nsc = *ns;
          num_features_in_inter *= ec.feature_space[nsc].size();
          sum_feat_sq_in_inter *= ec.feature_space[nsc].sum_feat_sq;
          if (num_features_in_inter == 0) break; //one of namespaces has no features - go to next interaction
        }
        else     // we are at beginning of a block made of same namespace (interaction is preliminary sorted)
        {

          // let's find out real length of this block
          size_t order_of_inter = 2; // alredy compared ns == ns+1

          for (namespace_index* ns_end = ns + 2; ns_end < inter.end(); ++ns_end)
            if (*ns == *ns_end) ++order_of_inter;

          // namespace is same for whole block
          features& fs = ec.feature_space[(const int)*ns];

          // count number of features with value != 1.;
          size_t cnt_ft_value_non_1 = 0;


          // in this block we shall calculate number of generated features and sum of their values
          // keeping in mind rules applicable for simple combinations instead of permutations



          // let's calculate sum of their squared value for whole block

          // ensure results as big as order_of_inter and empty.
          for (size_t i = 0; i < results.size(); ++i) results[i] = 0.;
          while (results.size() < order_of_inter) results.push_back(0.);

          // recurrent value calculations
          for (size_t i = 0; i < fs.size(); ++i)
          { const float x = fs.values[i]*fs.values[i];

            if ( !PROCESS_SELF_INTERACTIONS(fs.values[i]) )
            { for (size_t i = order_of_inter-1; i > 0; --i)
                results[i] += results[i-1]*x;

              results[0] += x;
            }
            else
            { results[0] += x;

              for (size_t i = 1; i < order_of_inter; ++i)
                results[i] += results[i-1]*x;

              ++cnt_ft_value_non_1;
            }

          }

          sum_feat_sq_in_inter *= results[order_of_inter-1]; // will be explained in http://bit.ly/1Hk9JX1


          // let's calculate  the number of a new features

          // if number of features is less than  order of interaction then go to the next interaction
          // as you can't make simple combination of interaction 'aaa' if a contains < 3 features.
          // unless one of them has value != 1. and we are counting them.
          const size_t ft_size = fs.size();
          if (cnt_ft_value_non_1 == 0 && ft_size < order_of_inter)
          { num_features_in_inter = 0;
            break;
          }


          size_t n;
          if (cnt_ft_value_non_1 == 0) // number of generated simple combinations is C(n,k)
          { n = (size_t)choose((long long)ft_size, (long long)order_of_inter);
          }
          else
          { n = 0;
            for (size_t l = 0; l <= order_of_inter; ++l)
            { //C(l+m-1, l) * C(n-m, k-l)
              size_t num = (l==0)?1:(size_t)choose(l+cnt_ft_value_non_1-1, l);

              if (ft_size - cnt_ft_value_non_1 >= order_of_inter-l)
                num *= (size_t)choose(ft_size - cnt_ft_value_non_1, order_of_inter-l);
              else num = 0;

              n +=  num;
            }

          } // details on http://bit.ly/1Hk9JX1


          num_features_in_inter *= n;

          ns += order_of_inter-1; //jump over whole block
        }
      }


      if (num_features_in_inter == 0) continue; //signal that values should be ignored (as default value is 1)

      new_features_cnt += num_features_in_inter;
      new_features_value += sum_feat_sq_in_inter;
    }

#ifdef DEBUG_EVAL_COUNT_OF_GEN_FT
    if (correct_features_cnt != new_features_cnt)
      cerr << "Incorrect new features count " << new_features_cnt << " must be " << correct_features_cnt << endl;
    if (fabs(correct_features_value - new_features_value) > 1e-5)
      cerr << "Incorrect new features value " << new_features_value << " must be " << correct_features_value << endl;
#endif

  }

  results.delete_v();
}



}
