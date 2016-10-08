#include "reductions.h"
#include "cost_sensitive.h"
#include "label_dictionary.h"

namespace LabelDict
{
size_t hash_lab(size_t lab) { return 328051 + 94389193 * lab; }

  void del_example_namespace(example& ec, char ns, features& fs)
  {
    // print_update is called after this del_example_namespace,
    // so we need to keep the ec.num_features correct,
    // so shared features are included in the reported number of "current features"
    //ec.num_features -= numf;
    features& del_target = ec.feature_space[(size_t)ns];
    assert(del_target.size() >= fs.size());
    assert(ec.indices.size() > 0);
    if (ec.indices.last() == ns && ec.feature_space[(size_t)ns].size() == fs.size())
      ec.indices.pop();
    ec.total_sum_feat_sq -= fs.sum_feat_sq;
    //ec.num_features -= fs.size();
    del_target.truncate_to(del_target.size() - fs.size());
    del_target.sum_feat_sq -= fs.sum_feat_sq;
  }

void add_example_namespace(example& ec, char ns, features& fs)
{ bool has_ns = false;
  for (size_t i=0; i<ec.indices.size(); i++)
    if (ec.indices[i] == (size_t)ns)
      { has_ns = true;
        break;
      }

  if (!has_ns)
    ec.indices.push_back((size_t)ns);

  bool audit = fs.space_names.size() > 0;
  features& add_fs = ec.feature_space[(size_t)ns];
 for (size_t i = 0; i < fs.size(); ++i)
    {
      add_fs.push_back(fs.values[i], fs.indicies[i]);
      if (audit)
        add_fs.space_names.push_back(fs.space_names[i]);
    }
  ec.total_sum_feat_sq += fs.sum_feat_sq;

  ec.num_features += fs.size();
}

void add_example_namespaces_from_example(example& target, example& source)
{ for (namespace_index idx : source.indices)
  { if (idx == constant_namespace) continue;
    add_example_namespace(target, (char)idx, source.feature_space[idx]);
  }
}

void del_example_namespaces_from_example(example& target, example& source)
{ namespace_index* idx = source.indices.end();
  idx--;
  for (; idx>=source.indices.begin(); idx--)
    { if (*idx == constant_namespace) continue;
      del_example_namespace(target, (char)*idx, source.feature_space[*idx]);
    }
}

void add_example_namespace_from_memory(label_feature_map& lfm, example& ec, size_t lab)
{ size_t lab_hash = hash_lab(lab);
  features& res = lfm.get(lab, lab_hash);
  if (res.size() == 0) return;
  add_example_namespace(ec, 'l', res);
}

void del_example_namespace_from_memory(label_feature_map& lfm, example& ec, size_t lab)
{ size_t lab_hash = hash_lab(lab);
  features& res = lfm.get(lab, lab_hash);
  if (res.size() == 0) return;
  del_example_namespace(ec, 'l', res);
}

void set_label_features(label_feature_map& lfm, size_t lab, features& fs)
{ size_t lab_hash = hash_lab(lab);
  if (lfm.contains(lab, lab_hash)) return;
  lfm.put_after_get(lab, lab_hash, fs);
}

void free_label_features(label_feature_map& lfm)
{ void* label_iter = lfm.iterator();
  while (label_iter != nullptr)
  { features *res = lfm.iterator_get_value(label_iter);
    res->values.delete_v();
    res->indicies.delete_v();
    res->space_names.delete_v();

    label_iter = lfm.iterator_next(label_iter);
  }
  lfm.clear();
  lfm.delete_v();
}
}
