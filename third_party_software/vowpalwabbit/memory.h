#pragma once
#include <stdlib.h>
#include <stdio.h>
#include <iostream>

template<class T>
T* calloc_or_throw(size_t nmemb)
{ if (nmemb == 0)
    return nullptr;

  void* data = calloc(nmemb, sizeof(T));
  if (data == nullptr)
  { const char* msg = "internal error: memory allocation failed!\n";
    // use low-level function since we're already out of memory.
    fputs(msg, stderr);
    THROW(msg);
  }
  return (T*)data;
}

template<class T> T& calloc_or_throw()
{ return *calloc_or_throw<T>(1); }

#ifdef MADV_MERGEABLE
template<class T>
T* calloc_mergable_or_throw(size_t nmemb)
{ if (nmemb == 0)
    return nullptr;
  size_t length = nmemb * sizeof(T);
  void* data;
  if (0 != posix_memalign(&data, sysconf(_SC_PAGE_SIZE), length))
  {
    const char* msg = "internal error: memory allocation failed!\n";
    fputs(msg, stderr);
    THROW(msg);
  }
  if (data == nullptr)
  { const char* msg = "internal error: memory allocation failed!\n";
    fputs(msg, stderr);
    THROW(msg);
  }
  memset(data, 0, length);
// mark weight vector as KSM sharable
// it allows to save memory if you run multiple instances of the same model
// see more https://www.kernel.org/doc/Documentation/vm/ksm.txt
// you need to have Linux kernel >= 2.6.32 and KSM enabled
// to check is KSM enabled run the command
// $ grep KSM /boot/config-`uname -r`
// if KSM is enabled you should see:
// >> CONFIG_KSM=y
// you can enable ksmd with sudo "echo 1 > /sys/kernel/mm/ksm/run"
// mark address space as a candidate for merging

  if (0 != madvise(data, length, MADV_MERGEABLE)) {
    const char* msg = "internal warning: marking memory as ksm mergeable failed!\n";
    fputs(msg, stderr);
  }
  return (T*)data;
}
#else
#define calloc_mergable_or_throw calloc_or_throw
#endif



inline void free_it(void* ptr) { if (ptr != nullptr) free(ptr); ptr = nullptr; }
