#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <locale>
#include <sstream>
#include <string_view>
#include <unistd.h>
#include <vector>
#include <windows.h>
#include <tchar.h>

std::basic_string<TCHAR> quoteArg(const TCHAR *arg) {
  std::basic_string<TCHAR> result = _T("\"");
  for (const TCHAR *p = arg; *p; ++p) {
    if (*p == _T('\"')) {
      result += _T("\\\"");
    } else {
      result += *p;
    }
  }
  result += _T("\"");
  return result;
}

int main(int argc, TCHAR **argv) {
  std::vector<std::basic_string<TCHAR>> runArgsStr(argc + 1);
  runArgsStr[0] = _T("wsl.exe");
  runArgsStr[1] = _T("@drv@/bin/@exe@");

  for (int i = 2; i < runArgsStr.size(); ++i) {
    runArgsStr[i] = argv[i - 1];
    if (runArgsStr[i].find('/') != std::basic_string_view<TCHAR>::npos ||
        runArgsStr[i].find('*') != std::basic_string_view<TCHAR>::npos ||
        runArgsStr[i].find('?') != std::basic_string_view<TCHAR>::npos ||
        runArgsStr[i].find('|') != std::basic_string_view<TCHAR>::npos ||
        runArgsStr[i].find('<') != std::basic_string_view<TCHAR>::npos ||
        runArgsStr[i].find('>') != std::basic_string_view<TCHAR>::npos ||
        runArgsStr[i].find('\\') == std::basic_string_view<TCHAR>::npos) {
    } else {
      std::replace(runArgsStr[i].begin(), runArgsStr[i].end(), '\\', '/');
    }

    if (runArgsStr[i].length() >= 3 && runArgsStr[i].substr(1, 2) == _T(":/")) {
      std::basic_stringstream<TCHAR> stream;
      stream << _T("@automountRoot@/")
             << std::tolower(runArgsStr[i][0], std::locale()) << _T("/")
             << runArgsStr[i].substr(3);
      runArgsStr[i] = stream.str();
    }
  }

  std::vector<char *> runArgs;
  runArgs.reserve(runArgsStr.size());
  for (const auto &argStr : runArgsStr) {
    runArgs.push_back((char *)memcpy(malloc(argStr.length() + 1),
                                     argStr.c_str(), argStr.length() + 1));
  }

  STARTUPINFO si;
  PROCESS_INFORMATION pi;

  ZeroMemory(&si, sizeof(si));
  si.cb = sizeof(si);
  ZeroMemory(&pi, sizeof(pi));

  std::basic_string<TCHAR> cmd_line;
  for (const auto &arg : runArgs) {
    cmd_line += quoteArg(arg).c_str();
    cmd_line += _T(" ");
  }

  if (!CreateProcess(NULL, &cmd_line[0], NULL, NULL, false, 0, NULL, NULL, &si, &pi)) {
    return 1;
  }

  WaitForSingleObject(pi.hProcess, INFINITE);
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
}
