/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD
license as described in the file LICENSE.
 */

#pragma once
#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>

#ifdef _WIN32
#define __INLINE
#else
#define __INLINE inline
#endif

#include "vw_exception.h"
#include "memory.h"

const size_t erase_point = ~ ((1 << 10) -1);

template<class T> struct v_array
{
// private:
  T* _begin;
  T* _end;
public:
  T* end_array;
  size_t erase_count;

  // enable C++ 11 for loops
  inline T*& begin() { return _begin; }
  inline T*& end() { return _end; }

  inline T* const cbegin() const { return _begin; }
  inline T* const cend() const { return _end; }

  // v_array cannot have a user-defined constructor, because it participates in various unions.
  // union members cannot have user-defined constructors.
  // v_array() : _begin(nullptr), _end(nullptr), end_array(nullptr), erase_count(0) {}
  // ~v_array() {
  //  delete_v();
  // }
  T last() const { return *(_end-1);}
  T pop() { return *(--_end);}
  bool empty() const { return _begin == _end;}
  void decr() { _end--;}
  void incr()
  { if (_end == end_array)
      resize(2 * (end_array - _begin) + 3);
    _end++;
  }
  T& operator[](size_t i) const { return _begin[i]; }
  T& get(size_t i) const { return _begin[i]; }
  inline size_t size() const {return _end-_begin;}
  void resize(size_t length)
  { if ((size_t)(end_array-_begin) != length)
    { size_t old_len = _end-_begin;
      T* temp = (T *)realloc(_begin, sizeof(T) * length);
      if ((temp == nullptr) && ((sizeof(T)*length) > 0))
      { THROW("realloc of " << length << " failed in resize().  out of memory?");
      }
      else
        _begin = temp;
      if (old_len < length)
        memset(_begin+old_len, 0, (length-old_len)*sizeof(T));
      _end = _begin+old_len;
      end_array = _begin + length;
    }
  }

  void erase()
  { if (++erase_count & erase_point)
    { resize(_end-_begin);
      erase_count = 0;
    }
    _end = _begin;
  }
  void delete_v()
  { if (_begin != nullptr)
      free(_begin);
    _begin = _end = end_array = nullptr;
  }
  void push_back(const T& new_ele)
  { if(_end == end_array)
      resize(2 * (end_array-_begin) + 3);
    new (_end++) T(new_ele);
  }
  void push_back_unchecked(const T& new_ele)
  { new (_end++) T(new_ele); }

  size_t find_sorted(const T& ele) const //index of the smallest element >= ele, return true if element is in the array
  { size_t size = _end - _begin;
    size_t a = 0;
    size_t b = size;
    size_t i = (a + b) / 2;

    while(b - a > 1)
    { if(_begin[i] < ele)	//if a = 0, size = 1, if in while we have b - a >= 1 the loop is infinite
        a = i;
      else if(_begin[i] > ele)
        b = i;
      else
        return i;

      i = (a + b) / 2;
    }

    if((size == 0) || (_begin[a] > ele) || (_begin[a] == ele))		//pusta tablica, nie wchodzi w while
      return a;
    else	//size = 1, ele = 1, _begin[0] = 0
      return b;
  }
  size_t unique_add_sorted(const T& new_ele)
  { size_t index = 0;
    size_t size = _end - _begin;
    size_t to_move;

    if(!contain_sorted(new_ele, index))
    { if(_end == end_array)
        resize(2 * (end_array-_begin) + 3);

      to_move = size - index;

      if(to_move > 0)
        memmove(_begin + index + 1, _begin + index, to_move * sizeof(T));   //kopiuje to_move*.. bytow z _begin+index do _begin+index+1

      _begin[index] = new_ele;

      _end++;
    }

    return index;
  }
  bool contain_sorted(const T& ele, size_t& index)
  { index = find_sorted(ele);

    if(index == this->size())
      return false;

    if(_begin[index] == ele)
      return true;

    return false;
  }
};

#ifdef _WIN32
#undef max
#undef min
#endif

inline size_t max(size_t a, size_t b)
{ if ( a < b) return b; else return a;
}
inline size_t min(size_t a, size_t b)
{ if ( a < b) return a; else return b;
}

template<class T>
inline v_array<T> v_init() { return {nullptr, nullptr, nullptr, 0};}

template<class T> void copy_array(v_array<T>& dst, const v_array<T>& src)
{ dst.erase();
  push_many(dst, src._begin, src.size());
}

template<class T> void copy_array(v_array<T>& dst, const v_array<T>& src, T(*copy_item)(T&))
{ dst.erase();
  for (T*item = src._begin; item != src._end; ++item)
    dst.push_back(copy_item(*item));
}

template<class T> void push_many(v_array<T>& v, const T* _begin, size_t num)
{ if(v._end+num >= v.end_array)
    v.resize(max(2 * (size_t)(v.end_array - v._begin) + 3,
                 v._end - v._begin + num));
  memcpy(v._end, _begin, num * sizeof(T));
  v._end += num;
}

template<class T> void calloc_reserve(v_array<T>& v, size_t length)
{ v._begin = calloc_or_throw<T>(length);
  v._end = v._begin;
  v.end_array = v._begin + length;
}

template<class T> v_array<T> pop(v_array<v_array<T> > &stack)
{ if (stack._end != stack._begin)
    return *(--stack._end);
  else
    return v_array<T>();
}

template<class T> bool v_array_contains(v_array<T> &A, T x)
{ for (T* e = A._begin; e != A._end; ++e)
    if (*e == x) return true;
  return false;
}

template<class T>std::ostream& operator<<(std::ostream& os, const v_array<T>& v)
{ os << '[';
  for (T* i=v._begin; i!=v._end; ++i) os << ' ' << *i;
  os << " ]";
  return os;
}

template<class T,class U>std::ostream& operator<<(std::ostream& os, const v_array<std::pair<T,U> >& v)
{ os << '[';
  for (std::pair<T,U>* i=v._begin; i!=v._end; ++i) os << ' ' << i->first << ':' << i->second;
  os << " ]";
  return os;
}

typedef v_array<unsigned char> v_string;

inline v_string string2v_string(const std::string& s)
{ v_string res = v_init<unsigned char>();
  if (!s.empty())
    push_many(res, (unsigned  char*)s.data(), s.size());
  return res;
}

inline std::string v_string2string(const v_string& v_s)
{ std::string res;
  for (unsigned char* i = v_s._begin; i != v_s._end; ++i)
    res.push_back(*i);
  return res;
}
