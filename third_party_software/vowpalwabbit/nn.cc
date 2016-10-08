/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD (revised)
license as described in the file LICENSE.
 */
#include <float.h>
#include <math.h>
#include <stdio.h>
#include <sstream>

#include "reductions.h"
#include "rand48.h"
#include "gd.h"
#include "vw.h"

using namespace std;
using namespace LEARNER;

const float hidden_min_activation = -3;
const float hidden_max_activation = 3;
const uint64_t nn_constant = 533357803;

struct nn
{ uint32_t k;
  loss_function* squared_loss;
  example output_layer;
  example hiddenbias;
  example outputweight;
  float prediction;
  size_t increment;
  bool dropout;
  uint64_t xsubi;
  uint64_t save_xsubi;
  bool inpass;
  bool finished_setup;
  bool multitask;

  float* hidden_units;
  bool* dropped_out;

  polyprediction* hidden_units_pred;
  polyprediction* hiddenbias_pred;

  vw* all;//many things
};

#define cast_uint32_t static_cast<uint32_t>

static inline float
fastpow2 (float p)
{ float offset = (p < 0) ? 1.0f : 0.0f;
  float clipp = (p < -126) ? -126.0f : p;
  int w = (int)clipp;
  float z = clipp - w + offset;
  union { uint32_t i; float f; } v = { cast_uint32_t ( (1 << 23) * (clipp + 121.2740575f + 27.7280233f / (4.84252568f - z) - 1.49012907f * z) ) };

  return v.f;
}

static inline float
fastexp (float p)
{ return fastpow2 (1.442695040f * p);
}

static inline float
fasttanh (float p)
{ return -1.0f + 2.0f / (1.0f + fastexp (-2.0f * p));
}

void finish_setup (nn& n, vw& all)
{ // TODO: output_layer audit

  memset (&n.output_layer, 0, sizeof (n.output_layer));
  n.output_layer.indices.push_back(nn_output_namespace);
  uint64_t nn_index = nn_constant << all.reg.stride_shift;

  features& fs = n.output_layer.feature_space[nn_output_namespace];
  for (unsigned int i = 0; i < n.k; ++i)
    { fs.push_back(1., nn_index);
      nn_index += (uint64_t)n.increment;
    }
  n.output_layer.num_features += n.k;

  if (! n.inpass)
    { fs.push_back(1.,nn_index);
      ++n.output_layer.num_features;
    }

  n.output_layer.in_use = true;

  // TODO: not correct if --noconstant
  memset (&n.hiddenbias, 0, sizeof (n.hiddenbias));
  n.hiddenbias.indices.push_back(constant_namespace);
  n.hiddenbias.feature_space[constant_namespace].push_back(1,(uint64_t)constant);
  n.hiddenbias.total_sum_feat_sq++;
  n.hiddenbias.l.simple.label = FLT_MAX;
  n.hiddenbias.weight = 1;
  n.hiddenbias.in_use = true;

  memset (&n.outputweight, 0, sizeof (n.outputweight));
  n.outputweight.indices.push_back(nn_output_namespace);
  features& outfs = n.output_layer.feature_space[nn_output_namespace];
  n.outputweight.feature_space[nn_output_namespace].push_back(outfs.values[0],outfs.indicies[0]);
  n.outputweight.feature_space[nn_output_namespace].values[0] = 1;
  n.outputweight.total_sum_feat_sq++;
  n.outputweight.l.simple.label = FLT_MAX;
  n.outputweight.weight = 1;
  n.outputweight.in_use = true;

  n.finished_setup = true;
}

void end_pass(nn& n)
{ if (n.all->bfgs)
    n.xsubi = n.save_xsubi;
}

template<bool is_learn, bool recompute_hidden>
void predict_or_learn_multi(nn& n, base_learner& base, example& ec)
{ bool shouldOutput = n.all->raw_prediction > 0;
  if (! n.finished_setup)
    finish_setup (n, *(n.all));
  shared_data sd;
  memcpy (&sd, n.all->sd, sizeof(shared_data));
  shared_data* save_sd = n.all->sd;
  n.all->sd = &sd;

  label_data ld = ec.l.simple;
  void (*save_set_minmax) (shared_data*, float) = n.all->set_minmax;
  float save_min_label;
  float save_max_label;
  float dropscale = n.dropout ? 2.0f : 1.0f;
  loss_function* save_loss = n.all->loss;

  polyprediction* hidden_units = n.hidden_units_pred;
  polyprediction* hiddenbias_pred = n.hiddenbias_pred;
  bool* dropped_out = n.dropped_out;

  ostringstream outputStringStream;

  n.all->set_minmax = noop_mm;
  n.all->loss = n.squared_loss;
  save_min_label = n.all->sd->min_label;
  n.all->sd->min_label = hidden_min_activation;
  save_max_label = n.all->sd->max_label;
  n.all->sd->max_label = hidden_max_activation;

  uint64_t save_ft_offset = ec.ft_offset;

  if (n.multitask)
    ec.ft_offset = 0;

  n.hiddenbias.ft_offset = ec.ft_offset;

  if (recompute_hidden)
  { base.multipredict(n.hiddenbias, 0, n.k, hiddenbias_pred, true);

    for (unsigned int i = 0; i < n.k; ++i)
      // avoid saddle point at 0
      if (hiddenbias_pred[i].scalar == 0)
      { n.hiddenbias.l.simple.label = (float) (frand48 () - 0.5);
        base.learn(n.hiddenbias, i);
        n.hiddenbias.l.simple.label = FLT_MAX;
      }

    base.multipredict(ec, 0, n.k, hidden_units, true);

    for (unsigned int i = 0; i < n.k; ++i )
      dropped_out[i] = (n.dropout && merand48 (n.xsubi) < 0.5);

    if (ec.passthrough)
      for (unsigned int i = 0; i < n.k; ++i)
      { add_passthrough_feature(ec, i*2,   hiddenbias_pred[i].scalar);
        add_passthrough_feature(ec, i*2+1, hidden_units[i].scalar);
      }
  }

  if (shouldOutput)
    for (unsigned int i = 0; i < n.k; ++i )
    { if (i > 0) outputStringStream << ' ';
      outputStringStream << i << ':' << hidden_units[i].scalar << ',' << fasttanh (hidden_units[i].scalar); // TODO: huh, what was going on here?
    }

  n.all->loss = save_loss;
  n.all->set_minmax = save_set_minmax;
  n.all->sd->min_label = save_min_label;
  n.all->sd->max_label = save_max_label;
  ec.ft_offset = save_ft_offset;

  bool converse = false;
  float save_partial_prediction = 0;
  float save_final_prediction = 0;
  float save_ec_loss = 0;

CONVERSE: // That's right, I'm using goto.  So sue me.

  n.output_layer.total_sum_feat_sq = 1;
  n.output_layer.feature_space[nn_output_namespace].sum_feat_sq = 1;

  n.outputweight.ft_offset = ec.ft_offset;

  n.all->set_minmax = noop_mm;
  n.all->loss = n.squared_loss;
  save_min_label = n.all->sd->min_label;
  n.all->sd->min_label = -1;
  save_max_label = n.all->sd->max_label;
  n.all->sd->max_label = 1;

  for (unsigned int i = 0; i < n.k; ++i)
  { float sigmah =
      (dropped_out[i]) ? 0.0f : dropscale * fasttanh (hidden_units[i].scalar);
    features& out_fs = n.output_layer.feature_space[nn_output_namespace];
    out_fs.values[i] = sigmah;

    n.output_layer.total_sum_feat_sq += sigmah * sigmah;
    out_fs.sum_feat_sq += sigmah * sigmah;

    n.outputweight.feature_space[nn_output_namespace].indicies[0] = out_fs.indicies[i];
    base.predict(n.outputweight, n.k);
    float wf = n.outputweight.pred.scalar;

    // avoid saddle point at 0
    if (wf == 0)
    { float sqrtk = sqrt ((float)n.k);
      n.outputweight.l.simple.label = (float) (frand48 () - 0.5) / sqrtk;
      base.update(n.outputweight, n.k);
      n.outputweight.l.simple.label = FLT_MAX;
    }
  }

  n.all->loss = save_loss;
  n.all->set_minmax = save_set_minmax;
  n.all->sd->min_label = save_min_label;
  n.all->sd->max_label = save_max_label;

  if (n.inpass)
  { // TODO: this is not correct if there is something in the
    // nn_output_namespace but at least it will not leak memory
    // in that case
    ec.indices.push_back (nn_output_namespace);
    features save_nn_output_namespace = ec.feature_space[nn_output_namespace];
    ec.feature_space[nn_output_namespace] = n.output_layer.feature_space[nn_output_namespace];
    ec.total_sum_feat_sq += n.output_layer.feature_space[nn_output_namespace].sum_feat_sq;
    if (is_learn)
      base.learn(ec, n.k);
    else
      base.predict(ec, n.k);
    n.output_layer.partial_prediction = ec.partial_prediction;
    n.output_layer.loss = ec.loss;
    ec.total_sum_feat_sq -= n.output_layer.feature_space[nn_output_namespace].sum_feat_sq;
    ec.feature_space[nn_output_namespace].sum_feat_sq = 0;
    ec.feature_space[nn_output_namespace] = save_nn_output_namespace;
    ec.indices.pop ();
  }
  else
  { n.output_layer.ft_offset = ec.ft_offset;
    n.output_layer.l = ec.l;
    n.output_layer.weight = ec.weight;
    n.output_layer.partial_prediction = 0;
    if (is_learn)
      base.learn(n.output_layer, n.k);
    else
      base.predict(n.output_layer, n.k);
    ec.l = n.output_layer.l;
  }

  n.prediction = GD::finalize_prediction (n.all->sd, n.output_layer.partial_prediction);

  if (shouldOutput)
  { outputStringStream << ' ' << n.output_layer.partial_prediction;
    n.all->print_text(n.all->raw_prediction, outputStringStream.str(), ec.tag);
  }

  if (is_learn && n.all->training && ld.label != FLT_MAX)
  { float gradient = n.all->loss->first_derivative(n.all->sd,
                     n.prediction,
                     ld.label);

    if (fabs (gradient) > 0)
    { n.all->loss = n.squared_loss;
      n.all->set_minmax = noop_mm;
      save_min_label = n.all->sd->min_label;
      n.all->sd->min_label = hidden_min_activation;
      save_max_label = n.all->sd->max_label;
      n.all->sd->max_label = hidden_max_activation;
      save_ft_offset = ec.ft_offset;

      if (n.multitask)
        ec.ft_offset = 0;

      for (unsigned int i = 0; i < n.k; ++i)
      { if (! dropped_out[i])
        { float sigmah =
            n.output_layer.feature_space[nn_output_namespace].values[i] / dropscale;
          float sigmahprime = dropscale * (1.0f - sigmah * sigmah);
          n.outputweight.feature_space[nn_output_namespace].indicies[0] =
            n.output_layer.feature_space[nn_output_namespace].indicies[i];
          base.predict(n.outputweight, n.k);
          float nu = n.outputweight.pred.scalar;
          float gradhw = 0.5f * nu * gradient * sigmahprime;

          ec.l.simple.label = GD::finalize_prediction (n.all->sd, hidden_units[i].scalar - gradhw);
          ec.pred.scalar = hidden_units[i].scalar;
          if (ec.l.simple.label != hidden_units[i].scalar)
            base.update(ec, i);
        }
      }

      n.all->loss = save_loss;
      n.all->set_minmax = save_set_minmax;
      n.all->sd->min_label = save_min_label;
      n.all->sd->max_label = save_max_label;
      ec.ft_offset = save_ft_offset;
    }
  }

  ec.l.simple.label = ld.label;

  if (! converse)
  { save_partial_prediction = n.output_layer.partial_prediction;
    save_final_prediction = n.prediction;
    save_ec_loss = n.output_layer.loss;
  }

  if (n.dropout && ! converse)
  { for (unsigned int i = 0; i < n.k; ++i)
    { dropped_out[i] = ! dropped_out[i];
    }

    converse = true;
    goto CONVERSE;
  }

  ec.partial_prediction = save_partial_prediction;
  ec.pred.scalar = save_final_prediction;
  ec.loss = save_ec_loss;

  n.all->sd = save_sd;
  n.all->set_minmax (n.all->sd, sd.min_label);
  n.all->set_minmax (n.all->sd, sd.max_label);
}

void multipredict(nn& n, base_learner& base, example& ec, size_t count, size_t step, polyprediction*pred, bool finalize_predictions)
{ for (size_t c=0; c<count; c++)
  { if (c == 0)
      predict_or_learn_multi<false,true>(n, base, ec);
    else
      predict_or_learn_multi<false,false>(n, base, ec);
    if (finalize_predictions) pred[c] = ec.pred;
    else pred[c].scalar = ec.partial_prediction;
    ec.ft_offset += (uint64_t)step;
  }
  ec.ft_offset -= (uint64_t)(step*count);
}

void finish_example(vw& all, nn&, example& ec)
{ int save_raw_prediction = all.raw_prediction;
  all.raw_prediction = -1;
  return_simple_example(all, nullptr, ec);
  all.raw_prediction = save_raw_prediction;
}

void finish(nn& n)
{ delete n.squared_loss;
  free(n.hidden_units);
  free(n.dropped_out);
  free(n.hidden_units_pred);
  free(n.hiddenbias_pred);
  VW::dealloc_example(nullptr, n.output_layer);
  VW::dealloc_example(nullptr, n.hiddenbias);
  VW::dealloc_example(nullptr, n.outputweight);
}

base_learner* nn_setup(vw& all)
{ if (missing_option<size_t, true>(all, "nn", "Sigmoidal feedforward network with <k> hidden units"))
    return nullptr;
  new_options(all, "Neural Network options")
  ("inpass", "Train or test sigmoidal feedforward network with input passthrough.")
  ("multitask", "Share hidden layer across all reduced tasks.")
  ("dropout", "Train or test sigmoidal feedforward network using dropout.")
  ("meanfield", "Train or test sigmoidal feedforward network using mean field.");
  add_options(all);

  po::variables_map& vm = all.vm;
  nn& n = calloc_or_throw<nn>();
  n.all = &all;
  //first parse for number of hidden units
  n.k = (uint64_t)vm["nn"].as<size_t>();

  if ( vm.count("dropout") )
  { n.dropout = true;
    *all.file_options << " --dropout ";
  }

  if ( vm.count("multitask") )
  { n.multitask = true;
    *all.file_options << " --multitask ";
  }

  if (n.multitask && ! all.quiet)
    std::cerr << "using multitask sharing for neural network "
              << (all.training ? "training" : "testing")
              << std::endl;

  if ( vm.count("meanfield") )
  { n.dropout = false;
    if (! all.quiet)
      std::cerr << "using mean field for neural network "
                << (all.training ? "training" : "testing")
                << std::endl;
  }

  if (n.dropout)
    if (! all.quiet)
      std::cerr << "using dropout for neural network "
                << (all.training ? "training" : "testing")
                << std::endl;

  if (vm.count ("inpass"))
  { n.inpass = true;
    *all.file_options << " --inpass";

  }

  if (n.inpass && ! all.quiet)
    std::cerr << "using input passthrough for neural network "
              << (all.training ? "training" : "testing")
              << std::endl;

  n.finished_setup = false;
  n.squared_loss = getLossFunction (all, "squared", 0);

  n.xsubi = all.random_seed;

  n.save_xsubi = n.xsubi;

  n.hidden_units = calloc_or_throw<float>(n.k);
  n.dropped_out = calloc_or_throw<bool>(n.k);
  n.hidden_units_pred = calloc_or_throw<polyprediction>(n.k);
  n.hiddenbias_pred = calloc_or_throw<polyprediction>(n.k);

  base_learner* base = setup_base(all);
  n.increment = base->increment;//Indexing of output layer is odd.
  learner<nn>&l = init_learner(&n, base,
                               predict_or_learn_multi<true,true>,
                               predict_or_learn_multi<false,true>,
                               n.k+1);
  if (n.multitask)
    l.set_multipredict(multipredict);
  l.set_finish(finish);
  l.set_finish_example(finish_example);
  l.set_end_pass(end_pass);

  return make_base(l);
}

/*

  train: ./vw -k -c -d mnist8v9.gz --passes 24 -b 25 --nn 64 -l 0.1 --invariant --adaptive --holdout_off --random_seed 19 --nnmultipredict -f mnist64
predict: ./vw -t -d mnist8v9.gz -i mnist64 --nnmultipredict

                     default   multipredict
  nn  64 train         9.1s         8.1s
         predict       0.57s        0.52s
  nn 128 train        16.5s        13.8s
         predict       0.76s        0.69s

with oaa:

  train: ./vw --oaa 10 -b 25 --adaptive --invariant --holdout_off -l 0.1 --nn 64 --passes 24 -k -c -d mnist-all.gz --random_seed 19 --nnmultipredict -f mnist-all64
predict: ./vw -t -d mnist-all.gz -i mnist-all64 --nnmultipredict

*/
