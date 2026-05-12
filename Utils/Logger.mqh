//+------------------------------------------------------------------+
//| Logger.mqh — lightweight file + Print logging                    |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_LOGGER_MQH__
#define __AQ_LOGGER_MQH__

class CQuantLogger
  {
private:
   int               m_level;     // 0=off, 1=errors, 2=info, 3=debug
   string            m_prefix;
   int               m_file_handle;

public:
                     CQuantLogger(void): m_level(2), m_prefix("[AQ001] "), m_file_handle(INVALID_HANDLE) {}
                    ~CQuantLogger(void) { Close(); }

   void              Init(const string log_name, const int level)
     {
      m_level = level;
      if(m_level < 1)
         return;
      string fn = log_name + ".log";
      m_file_handle = FileOpen(fn, FILE_WRITE | FILE_TXT | FILE_COMMON | FILE_ANSI);
      if(m_file_handle == INVALID_HANDLE)
         Print(m_prefix, "Log file open failed: ", fn);
     }

   void              Close(void)
     {
      if(m_file_handle != INVALID_HANDLE)
        {
         FileClose(m_file_handle);
         m_file_handle = INVALID_HANDLE;
        }
     }

   void              Error(const string msg)
     {
      if(m_level < 1)
         return;
      string line = TimeToString(TimeGMT(), TIME_DATE | TIME_SECONDS) + " ERROR " + msg;
      Print(m_prefix, line);
      WriteLine(line);
     }

   void              Info(const string msg)
     {
      if(m_level < 2)
         return;
      string line = TimeToString(TimeGMT(), TIME_DATE | TIME_SECONDS) + " INFO " + msg;
      Print(m_prefix, line);
      WriteLine(line);
     }

   void              Debug(const string msg)
     {
      if(m_level < 3)
         return;
      string line = TimeToString(TimeGMT(), TIME_DATE | TIME_SECONDS) + " DBG " + msg;
      Print(m_prefix, line);
      WriteLine(line);
     }

private:
   void              WriteLine(const string line)
     {
      if(m_file_handle == INVALID_HANDLE)
         return;
      FileSeek(m_file_handle, 0, SEEK_END);
      FileWriteString(m_file_handle, line + "\n");
      FileFlush(m_file_handle);
     }
  };

#endif // __AQ_LOGGER_MQH__
