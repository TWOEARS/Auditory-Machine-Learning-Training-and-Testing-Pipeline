#include "vw_exception.h"

#ifdef _WIN32
#include <Windows.h>
#endif

namespace VW
{

vw_exception::vw_exception(const char* pfile, int plineNumber, std::string pmessage)
  : file(pfile), message(pmessage), lineNumber(plineNumber)
{
}

vw_exception::vw_exception(const vw_exception& ex)
  : file(ex.file), message(ex.message), lineNumber(ex.lineNumber)
{
}

vw_exception::~vw_exception() _NOEXCEPT
{
}

const char* vw_exception::what() const _NOEXCEPT
{ return message.c_str();
}

const char* vw_exception::Filename() const
{ return file;
}

int vw_exception::LineNumber() const
{ return lineNumber;
}

#ifdef _WIN32

void vw_trace(const char* filename, int linenumber, const char* fmt, ...)
{ char buffer[4 * 1024];
  int offset = sprintf_s(buffer, sizeof(buffer), "%s:%d (%d): ", filename, linenumber, GetCurrentThreadId());

  va_list argptr;
  va_start(argptr, fmt);
  offset += vsprintf_s(buffer + offset, sizeof(buffer) - offset, fmt, argptr);
  va_end(argptr);

  sprintf_s(buffer + offset, sizeof(buffer) - offset, "\n");

  OutputDebugStringA(buffer);
}

bool launchDebugger()
{ // Get System directory, typically c:\windows\system32
  std::wstring systemDir(MAX_PATH + 1, '\0');
  UINT nChars = GetSystemDirectoryW(&systemDir[0], (UINT)systemDir.length());
  if (nChars == 0) return false; // failed to get system directory
  systemDir.resize(nChars);

  // Get process ID and create the command line
  DWORD pid = GetCurrentProcessId();
  std::wostringstream s;
  s << systemDir << L"\\vsjitdebugger.exe -p " << pid;
  std::wstring cmdLine = s.str();

  // Start debugger process
  STARTUPINFOW si;
  ZeroMemory(&si, sizeof(si));
  si.cb = sizeof(si);

  PROCESS_INFORMATION pi;
  ZeroMemory(&pi, sizeof(pi));

  if (!CreateProcessW(NULL, &cmdLine[0], NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) return false;

  // Close debugger process handles to eliminate resource leak
  CloseHandle(pi.hThread);
  CloseHandle(pi.hProcess);

  // Wait for the debugger to attach
  while (!IsDebuggerPresent()) Sleep(100);

  // Stop execution so the debugger can take over
  DebugBreak();
  return true;
}
#endif
}
