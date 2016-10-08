#include <memory>

typedef float feature_value;
typedef uint64_t feature_index;
typedef std::pair<std::string, std::string> audit_strings;
typedef std::shared_ptr<audit_strings> audit_strings_ptr;

struct feature {//sparse feature definition for the library interface
  float x;
  uint64_t weight_index;
  feature(float _x, uint64_t _index): x(_x), weight_index(_index) {}
  feature() {feature(0.f,0);}
};

struct feature_slice{ //a helper struct for functions using the set {v,i,space_name}
  feature_value v;
  feature_index i;
  audit_strings space_name;
};

inline int order_features(const void* first, const void* second)
{ if (((feature_slice*)first)->i != ((feature_slice*)second)->i)
    return (int)(((feature_slice*)first)->i - ((feature_slice*)second)->i);
  else if (((feature_slice*)first)->v > ((feature_slice*)second)->v)
    return 1;
  else
    return -1;
}

struct features;

/// iterator over feature values only
class features_value_iterator
{
protected:
  feature_value* _begin;
public:
  features_value_iterator(feature_value* begin)
    : _begin(begin)
  { }

  features_value_iterator(const features_value_iterator& other)
    : _begin(other._begin)
  { }

  features_value_iterator& operator++()
  { _begin++;
    return *this;
  }

  /// \return reference to the current value
  inline feature_value& value()
  { return *_begin;
  }

  /// creates a new iterator advanced by \p index
  /// \remark template<typename T> used to avoid warnings or tons of overloads for int, size_t, ...
  template<typename T>
  features_value_iterator operator+(T index) { return features_value_iterator(_begin + index); }

  template<typename T>
  features_value_iterator& operator+=(T index)
  { _begin += index;
    return *this;
  }

  template<typename T>
  features_value_iterator& operator-=(T index)
  { _begin -= index;
    return *this;
  }

  features_value_iterator& operator=(const features_value_iterator& other)
  { _begin = other._begin;
    return *this;
  }

  features_value_iterator& operator*() { return *this; }

  bool operator==(const features_value_iterator& rhs) { return _begin == rhs._begin; }
  bool operator!=(const features_value_iterator& rhs) { return _begin != rhs._begin; }

  friend void swap(features_value_iterator& lhs, features_value_iterator& rhs) { std::swap(lhs._begin, rhs._begin); }

  friend struct features;
};

/// iterator over values and indicies
class features_value_index_iterator : public features_value_iterator
{
protected:
  feature_index* _begin_index;
public:
  features_value_index_iterator(feature_value* begin, feature_index* begin_index)
    : features_value_iterator(begin), _begin_index(begin_index)
  { }

  features_value_index_iterator(const features_value_index_iterator& other)
    : features_value_iterator(other), _begin_index(other._begin_index)
  { }

  features_value_index_iterator& operator++()
  { features_value_iterator::operator++();
    _begin_index++;
    return *this;
  }

  inline feature_index& index()
  { return *_begin_index;
  }

  template<typename T>
  features_value_index_iterator& operator+=(T index)
  { features_value_iterator::operator+=(index);
    _begin_index += index;
    return *this;
  }

  template<typename T>
  features_value_index_iterator operator+(T index)
  { return features_value_index_iterator(_begin + index, _begin_index + index);
  }

  template<typename T>
  features_value_index_iterator& operator-=(T index)
  { features_value_iterator::operator-=(index);
    _begin_index -= index;
    return *this;
  }

  features_value_index_iterator& operator=(const features_value_index_iterator& other)
  {  features_value_iterator::operator=(other);
    _begin_index = other._begin_index;
    return *this;
  }

  features_value_index_iterator& operator*()
  { return *this;
  }

  friend void swap(features_value_index_iterator& lhs, features_value_index_iterator& rhs)
  { swap(static_cast<features_value_iterator&>(lhs), static_cast<features_value_iterator&>(rhs));
    std::swap(lhs._begin_index, rhs._begin_index);
  }
};

/// iterator over values, indicies and audit space names
class features_value_index_audit_iterator : public features_value_index_iterator
{
protected:
  audit_strings_ptr* _begin_audit;
public:
  features_value_index_audit_iterator(feature_value* begin, feature_index* begin_index, audit_strings_ptr* begin_audit)
    : features_value_index_iterator(begin, begin_index), _begin_audit(begin_audit)
  { }

  features_value_index_audit_iterator(const features_value_index_audit_iterator& other)
    : features_value_index_iterator(other), _begin_audit(other._begin_audit)
  { }

  // prefix increment
  features_value_index_audit_iterator& operator++()
  { features_value_index_iterator::operator++();
    _begin_audit++;
    return *this;
  }

  inline audit_strings_ptr& audit()
  { return *_begin_audit;
  }

  template<typename T>
  features_value_index_audit_iterator& operator+=(T index)
  { features_value_index_iterator::operator+=(index);
    _begin_audit += index;
    return *this;
  }

  template<typename T>
  features_value_index_audit_iterator operator+(T index)
  { return features_value_index_audit_iterator(_begin + index, _begin_index + index, _begin_audit + index);
  }

  template<typename T>
  features_value_index_audit_iterator& operator-=(T index)
  { features_value_index_iterator::operator-=(index);
    _begin_audit += index;
    return *this;
  }

  features_value_index_audit_iterator& operator=(const features_value_index_audit_iterator& other)
  { features_value_index_iterator::operator=(other);
    _begin_audit = other._begin_audit;
    return *this;
  }

  features_value_index_audit_iterator& operator*() { return *this; }

  friend void swap(features_value_index_audit_iterator& lhs, features_value_index_audit_iterator& rhs)
  { swap(static_cast<features_value_index_iterator&>(lhs), static_cast<features_value_index_iterator&>(rhs));
    swap(lhs._begin_audit, rhs._begin_audit);
  }
};

/// the core definition of a set of features.
struct features {
  v_array<feature_value> values; // Always needed.
  v_array<feature_index> indicies; //Optional for sparse data.
  v_array<audit_strings_ptr> space_names; //Optional for audit mode.

  float sum_feat_sq;

  typedef features_value_index_iterator iterator;
  typedef features_value_iterator iterator_value;
  typedef features_value_index_audit_iterator iterator_all;

  /// defines a "range" usable by C++ 11 for loops
  class features_value_index_audit_range {
  private:
    features* _outer;
  public:
    features_value_index_audit_range(features* outer) : _outer(outer)
    { }

    iterator_all begin() { return iterator_all(_outer->values.begin(), _outer->indicies.begin(), _outer->space_names.begin()); }
    iterator_all end() { return iterator_all(_outer->values.end(), _outer->indicies.end(), _outer->space_names.end()); }
  };

  features()
  { values = v_init<feature_value>();
    indicies = v_init<feature_index>();
    space_names = v_init<audit_strings_ptr>();
    sum_feat_sq = 0.f;
  }

  inline size_t size() const { return values.size(); }

  inline bool nonempty() const { return !values.empty(); }

  void free_space_names(size_t i)
  { for (; i < space_names.size(); i++)
      space_names[i].~audit_strings_ptr();
  }

  features_value_index_audit_range values_indices_audit()
  { return features_value_index_audit_range(this);
  }

  // default iterator for values & features
  iterator begin() { return iterator(values.begin(), indicies.begin()); }

  iterator end() { return iterator(values.end(), indicies.end()); }

  void erase()
  {
    sum_feat_sq = 0.f;
    values.erase();
    indicies.erase();
    free_space_names(0);
    space_names.erase();
  }

  void truncate_to(const features_value_iterator& pos)
  {
    ssize_t i = pos._begin - values.begin();
    values.end() = pos._begin;
    if (indicies.end() != indicies.begin())
      indicies.end() = indicies.begin() + i;
    if (space_names.begin() != space_names.end())
    {
      free_space_names(i);
      space_names.end() = space_names.begin() + i;
    }
  }

  void truncate_to(size_t i)
  {
    values.end() = values.begin() + i;
    if (indicies.end() != indicies.begin())
      indicies.end() = indicies.begin() + i;
    if (space_names.begin() != space_names.end())
    { free_space_names(i);
	    space_names.end() = space_names.begin() + i;
    }
  }

  void delete_v()
  {
    values.delete_v();
    indicies.delete_v();
    free_space_names(0);
    space_names.delete_v();
  }
  void push_back(feature_value v, feature_index i)
  {
    values.push_back(v);
    indicies.push_back(i);
    sum_feat_sq += v*v;
  }

  bool sort(uint64_t parse_mask)
  {
    if (indicies.size() == 0)
      return false;
    v_array<feature_slice> slice = v_init<feature_slice>();
    for (size_t i = 0; i < indicies.size(); i++)
      {
        feature_slice temp = { values[i], indicies[i] & parse_mask, audit_strings("", "") };
        if (space_names.size() != 0)
          temp.space_name = *space_names[i].get();
        slice.push_back(temp);
      }
    qsort(slice.begin(), slice.size(), sizeof(feature_slice), order_features);
    for (size_t i = 0; i < slice.size(); i++)
      {
        values[i] = slice[i].v;
        indicies[i] = slice[i].i;
        if (space_names.size() > 0)
          *space_names[i].get() = slice[i].space_name;
      }
    slice.delete_v();
    return true;
  }

  void deep_copy_from(const features& src)
  { copy_array(values, src.values);
    copy_array(indicies, src.indicies);
    free_space_names(0);
    copy_array(space_names, src.space_names);
    sum_feat_sq = src.sum_feat_sq;
  }
};

