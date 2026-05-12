//+------------------------------------------------------------------+
//| SessionEngine.mqh — London / NY killzones (UTC)                  |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_SESSION_MQH__
#define __AQ_SESSION_MQH__

#include "../Config/Settings.mqh"
#include "../Utils/TimeUtils.mqh"

class CSessionEngine
  {
private:
   SQuantConfig m_cfg;

public:
   void Init(const SQuantConfig &cfg) { m_cfg = cfg; }

   bool IsTradingSessionUtc(const datetime gmt_time)
     {
      if(m_cfg.session_mode == AQ_SESSION_DISABLED)
         return true;

      int dow = CTimeUtils::UtcDayOfWeek(gmt_time);
      if(dow == 0 || dow == 6) // Sun/Sat — skip
         return false;

      if(m_cfg.avoid_friday_after_utc && dow == 5)
        {
         if(CTimeUtils::UtcHour(gmt_time) >= m_cfg.friday_cutoff_hour_utc)
            return false;
        }

      bool lon = CTimeUtils::InHourRangeUtc(gmt_time, m_cfg.london_start_hour, m_cfg.london_end_hour);
      bool ny = CTimeUtils::InHourRangeUtc(gmt_time, m_cfg.ny_start_hour, m_cfg.ny_end_hour);

      if(m_cfg.session_mode == AQ_SESSION_LONDON_NY)
         return (lon || ny);
      if(m_cfg.session_mode == AQ_SESSION_LONDON_ONLY)
         return lon;
      if(m_cfg.session_mode == AQ_SESSION_NY_ONLY)
         return ny;
      return true;
     }

   string SessionTagUtc(const datetime gmt_time)
     {
      bool lon = CTimeUtils::InHourRangeUtc(gmt_time, m_cfg.london_start_hour, m_cfg.london_end_hour);
      bool ny = CTimeUtils::InHourRangeUtc(gmt_time, m_cfg.ny_start_hour, m_cfg.ny_end_hour);
      if(lon && ny)
         return "OVERLAP";
      if(lon)
         return "LONDON";
      if(ny)
         return "NEW YORK";
      return "OFF";
     }
  };

#endif // __AQ_SESSION_MQH__
