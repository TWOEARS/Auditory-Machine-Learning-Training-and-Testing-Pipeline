/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD
license as described in the file LICENSE.
 */
#pragma once
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <string.h>
#include "v_array.h"

template<class K, class V> class v_hashmap
{
public:

  struct hash_elem
  { bool   occupied;
    K      key;
    V      val;
    uint64_t hash;
  };

  bool (*equivalent)(void*,K&,K&);
  bool (*equivalent_no_data)(K&,K&);
  //  size_t (*hash)(K);
  V default_value;
  v_array<hash_elem> dat;
  size_t last_position;
  size_t num_occupants;
  void*eq_data;
  //size_t num_linear_steps, num_clear, total_size_at_clears;

  size_t base_size()
  { return dat.end_array-dat.begin();
  }

  void set_default_value(V def) { default_value = def; }

  void init_dat(size_t min_size, V def, bool (*eq)(void*,K&,K&), void *eq_dat = nullptr)
  { dat = v_init<hash_elem>();
    if (min_size < 1023) min_size = 1023;
    dat.resize(min_size, true); // resize sets to 0 ==> occupied=false

    default_value = def;
    equivalent = eq;
    equivalent_no_data = nullptr;
    eq_data = eq_dat;

    last_position = 0;
    num_occupants = 0;
  }

  void init(size_t min_size, V def, bool (*eq)(K&,K&))
  { dat = v_array<hash_elem>();
    if (min_size < 1023) min_size = 1023;
    dat.resize(min_size); // resize sets to 0 ==> occupied=false

    default_value = def;
    equivalent = nullptr;
    equivalent_no_data = eq;
    eq_data = nullptr;

    last_position = 0;
    num_occupants = 0;
  }

  void init(size_t min_size, bool (*eq)(K&,K&))
  { dat = v_array<hash_elem>();
    if (min_size < 1023) min_size = 1023;
    dat.resize(min_size); // resize sets to 0 ==> occupied=false

    equivalent = nullptr;
    equivalent_no_data = eq;
    eq_data = nullptr;

    last_position = 0;
    num_occupants = 0;
  }

  v_hashmap(size_t min_size, V def, bool (*eq)(void*,K&,K&), void*eq_dat=nullptr) { init_dat(min_size, def, eq, eq_dat); }
  v_hashmap(size_t min_size, V def, bool (*eq)(K&,K&))                         { init(min_size, def, eq); }
  v_hashmap() { init(1023, nullptr); }

  void set_equivalent(bool (*eq)(void*,K&,K&), void*eq_dat=nullptr) { equivalent = eq; eq_data = eq_dat; equivalent_no_data = nullptr; }
  void set_equivalent(bool (*eq)(K&,K&)) { equivalent_no_data = eq; eq_data = nullptr; equivalent = nullptr; }

  void delete_v() { dat.delete_v(); }

  ~v_hashmap() { delete_v(); }

  void clear()
  { if (num_occupants == 0) return;
    memset(dat.begin(), 0, base_size()*sizeof(hash_elem));
    last_position = 0;
    num_occupants = 0;
  }

  void* iterator_next(void* prev)
  { hash_elem* e = (hash_elem*)prev;
    if (e == nullptr) return nullptr;
    e++;
    while (e != dat.end_array)
    { if (e->occupied)
        return e;
      e++;
    }
    return nullptr;
  }

  void* iterator()
  { hash_elem* e = dat.begin();
    while (e != dat.end_array)
    { if (e->occupied)
        return e;
      e++;
    }
    return nullptr;
  }

  V* iterator_get_value(void* el)
  { hash_elem* e = (hash_elem*)el;
    return &e->val;
  }

  void iter(void (*func)(K,V))
  { //for (size_t lp=0; lp<base_size(); lp++) {
    for (hash_elem* e=dat.begin(); e!=dat.end_array; e++)
    { //hash_elem* e = dat.begin()+lp;
      if (e->occupied)
      { //printf("  [lp=%d\tocc=%d\thash=%llu]\n", lp, e->occupied, e->hash);
        func(e->key, e->val);
      }
    }
  }

  void put_after_get_nogrow(K& key, uint64_t hash, V val)
  { //printf("++[lp=%d\tocc=%d\thash=%llu]\n", last_position, dat[last_position].occupied, hash);
    dat[last_position].occupied = true;
    dat[last_position].key = key;
    dat[last_position].val = val;
    dat[last_position].hash = hash;
  }

  void double_size()
  { //    printf("doubling size!\n");
    // remember the old occupants
    v_array<hash_elem>tmp = v_array<hash_elem>();
    tmp.resize(num_occupants+10);
    for (hash_elem* e=dat.begin(); e!=dat.end_array; e++)
      if (e->occupied)
        tmp.push_back(*e);

    // double the size and clear
    //std::cerr<<"doubling to "<<(base_size()*2) << " units == " << (base_size()*2*sizeof(hash_elem)) << " bytes / " << ((size_t)-1)<<std::endl;
    dat.resize(base_size()*2);
    memset(dat.begin(), 0, base_size()*sizeof(hash_elem));

    // re-insert occupants
    for (auto& e : tmp)
    { get(e.key, e.hash);
      //      std::cerr << "reinserting " << e->key << " at " << last_position << std::endl;
      put_after_get_nogrow(e.key, e.hash, e.val);
    }
    tmp.delete_v();
  }

  bool is_equivalent(K& key, K& key2)
  { if ((equivalent == nullptr) && (equivalent_no_data == nullptr))
      return true;
    else if (equivalent != nullptr)
      return equivalent(eq_data, key, key2);
    else
      return equivalent_no_data(key, key2);
  }

  V& get(K key, uint64_t hash)
  { size_t sz  = base_size();
    size_t first_position = hash % sz;
    last_position = first_position;
    while (true)
    { // if there's nothing there, obviously we don't contain it
      if (!dat[last_position].occupied)
        return default_value;

      // there's something there: maybe it's us
      if ((dat[last_position].hash == hash) && is_equivalent(key, dat[last_position].key))
        return dat[last_position].val;

      // there's something there that's NOT us -- advance pointer
      //cerr << "+";
      //num_linear_steps++;
      last_position++;
      if (last_position >= sz)
        last_position = 0;

      // check to make sure we haven't cycled around -- this is a bug!
      if (last_position == first_position)
        THROW("error: v_hashmap did not grow enough!");
    }
  }

  bool contains(K& key, size_t hash)
  { size_t sz  = base_size();
    size_t first_position = hash % sz;
    last_position = first_position;
    while (true)
    { // if there's nothing there, obviously we don't contain it
      if (!dat[last_position].occupied)
        return false;

      // there's something there: maybe it's us
      if ((dat[last_position].hash == hash) && is_equivalent(key, dat[last_position].key))
        return true;

      // there's something there that's NOT us -- advance pointer
      last_position++;
      if (last_position >= sz)
        last_position = 0;

      // check to make sure we haven't cycled around -- this is a bug!
      if (last_position == first_position)
        THROW("error: v_hashmap did not grow enough!");
    }
  }


  // only call put_after_get(key, hash, val) if you've already
  // run get(key, hash).  if you haven't already run get, then
  // you should use put() rather than put_after_get().  these
  // both will overwrite previous values, if they exist.
  void put_after_get(K& key, uint64_t hash, V val)
  { if (!dat[last_position].occupied)
    { num_occupants++;
      if (num_occupants*4 >= base_size())          // grow when we're a quarter full
      { double_size();
        get(key, hash);  // probably should change last_position-- this is the lazy man's way to do it
      }
    }

    // now actually insert it
    put_after_get_nogrow(key, hash, val);
  }

  void put(K& key, uint64_t hash, V val)
  { get(key, hash);
    put_after_get(key, hash, val);
  }

  size_t size() { return num_occupants; }
};

void test_v_hashmap();
