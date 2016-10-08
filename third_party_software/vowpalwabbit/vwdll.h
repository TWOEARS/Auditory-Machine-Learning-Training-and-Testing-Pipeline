/*
Copyright (c) by respective owners including Yahoo!, Microsoft, and
individual contributors. All rights reserved.  Released under a BSD
license as described in the file LICENSE.
 */
#pragma once


// indirect the Win32 so non win32 Microsoft C programs can work
#ifdef WIN32
#define MS_CONV		// use Microsoft library calling conventions
#endif

// enable wide character (32 bit) versions of functions
// these are optional  since other compilers may not have wide to narrow char libarray facilities built in.
#ifdef WIN32
#define USE_CODECVT
#endif



#ifdef MS_CONV
#define VW_CALLING_CONV __stdcall
#else
#define VW_CALLING_CONV
#endif

#ifdef MS_CONV

#ifdef VWDLL_EXPORTS
#define VW_DLL_MEMBER __declspec(dllexport)
#else
#define VW_DLL_MEMBER __declspec(dllimport)
#endif

#else
#define VW_DLL_MEMBER
#endif





#ifdef __cplusplus
extern "C"
{
#endif

#ifdef __cplusplus
#define VW_TYPE_SAFE_NULL nullptr
#else
#define VW_TYPE_SAFE_NULL NULL
#endif

  typedef void * VW_HANDLE;
  typedef void * VW_EXAMPLE;
  typedef void * VW_LABEL;
  typedef void * VW_FEATURE_SPACE;
  typedef void * VW_FEATURE;

  const VW_HANDLE INVALID_VW_HANDLE = VW_TYPE_SAFE_NULL;
  const VW_HANDLE INVALID_VW_EXAMPLE = VW_TYPE_SAFE_NULL;

#ifdef USE_CODECVT
  VW_DLL_MEMBER VW_HANDLE VW_CALLING_CONV VW_Initialize(const char16_t * pstrArgs);
#endif
  VW_DLL_MEMBER VW_HANDLE VW_CALLING_CONV VW_InitializeA(const char * pstrArgs);

  VW_DLL_MEMBER void VW_CALLING_CONV VW_Finish_Passes(VW_HANDLE handle);
  VW_DLL_MEMBER void VW_CALLING_CONV VW_Finish(VW_HANDLE handle);

  VW_DLL_MEMBER VW_EXAMPLE VW_CALLING_CONV VW_ImportExample(VW_HANDLE handle, const char * label, VW_FEATURE_SPACE * features, size_t len);

  VW_DLL_MEMBER VW_FEATURE_SPACE VW_CALLING_CONV VW_ExportExample(VW_HANDLE handle, VW_EXAMPLE e, size_t* plen);
  VW_DLL_MEMBER void VW_CALLING_CONV VW_ReleaseFeatureSpace(VW_FEATURE_SPACE * features, size_t len);
#ifdef USE_CODECVT
  VW_DLL_MEMBER VW_EXAMPLE VW_CALLING_CONV VW_ReadExample(VW_HANDLE handle, const char16_t * line);
#endif
  VW_DLL_MEMBER VW_EXAMPLE VW_CALLING_CONV VW_ReadExampleA(VW_HANDLE handle, const char * line);

  VW_DLL_MEMBER void VW_CALLING_CONV VW_StartParser(VW_HANDLE handle);
  VW_DLL_MEMBER void VW_CALLING_CONV VW_EndParser(VW_HANDLE handle);

  VW_DLL_MEMBER VW_EXAMPLE VW_CALLING_CONV VW_GetExample(VW_HANDLE handle);
  VW_DLL_MEMBER void VW_CALLING_CONV VW_FinishExample(VW_HANDLE handle, VW_EXAMPLE e);
  VW_DLL_MEMBER float VW_CALLING_CONV VW_GetLabel(VW_EXAMPLE e);
  VW_DLL_MEMBER float VW_CALLING_CONV VW_GetImportance(VW_EXAMPLE e);
  VW_DLL_MEMBER float VW_CALLING_CONV VW_GetInitial(VW_EXAMPLE e);
  VW_DLL_MEMBER float VW_CALLING_CONV VW_GetPrediction(VW_EXAMPLE e);
  VW_DLL_MEMBER float VW_CALLING_CONV VW_GetCostSensitivePrediction(VW_EXAMPLE e);
  VW_DLL_MEMBER void* VW_CALLING_CONV VW_GetMultilabelPredictions(VW_EXAMPLE e, size_t* plen);
  VW_DLL_MEMBER float VW_CALLING_CONV VW_GetTopicPrediction(VW_EXAMPLE e, size_t i);
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_GetTagLength(VW_EXAMPLE e);
  VW_DLL_MEMBER const char* VW_CALLING_CONV VW_GetTag(VW_EXAMPLE e);
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_GetFeatureNumber(VW_EXAMPLE e);
  VW_DLL_MEMBER VW_FEATURE VW_CALLING_CONV VW_GetFeatures(VW_HANDLE handle, VW_EXAMPLE e, size_t* plen);
  VW_DLL_MEMBER void VW_CALLING_CONV VW_ReturnFeatures(VW_FEATURE f);
#ifdef USE_CODECVT
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_HashSpace(VW_HANDLE handle, const char16_t * s);
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_HashSpaceStatic(const char16_t * s, const char16_t * h);
#endif
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_HashSpaceA(VW_HANDLE handle, const char * s);
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_HashSpaceStaticA(const char * s, const char* h);
#ifdef USE_CODECVT
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_HashFeature(VW_HANDLE handle, const char16_t * s, unsigned long u);
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_HashFeatureStatic(const char16_t * s, unsigned long u, const char16_t * h, unsigned int num_bits);
#endif
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_HashFeatureA(VW_HANDLE handle, const char * s, unsigned long u);
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_HashFeatureStaticA(const char * s, unsigned long u, const char * h, unsigned int num_bits);

  VW_DLL_MEMBER float VW_CALLING_CONV VW_Learn(VW_HANDLE handle, VW_EXAMPLE e);
  VW_DLL_MEMBER float VW_CALLING_CONV VW_Predict(VW_HANDLE handle, VW_EXAMPLE e);
  VW_DLL_MEMBER float VW_CALLING_CONV VW_PredictCostSensitive(VW_HANDLE handle, VW_EXAMPLE e);
  VW_DLL_MEMBER void VW_CALLING_CONV VW_AddLabel(VW_EXAMPLE e, float label, float weight, float base);
  VW_DLL_MEMBER void VW_CALLING_CONV VW_AddStringLabel(VW_HANDLE handle, VW_EXAMPLE e, const char* label);

  VW_DLL_MEMBER float VW_CALLING_CONV VW_Get_Weight(VW_HANDLE handle, size_t index, size_t offset);
  VW_DLL_MEMBER void VW_CALLING_CONV VW_Set_Weight(VW_HANDLE handle, size_t index, size_t offset, float value);
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_Num_Weights(VW_HANDLE handle);
  VW_DLL_MEMBER size_t VW_CALLING_CONV VW_Get_Stride(VW_HANDLE handle);

  VW_DLL_MEMBER void VW_CALLING_CONV VW_SaveModel(VW_HANDLE handle);

#ifdef __cplusplus
}
#endif

#undef VW_TYPE_SAFE_NULL
