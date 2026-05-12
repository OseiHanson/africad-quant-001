//+------------------------------------------------------------------+
//| TimeUtils.mqh — UTC session helpers                              |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_TIMEUTILS_MQH__
#define __AQ_TIMEUTILS_MQH__

class CTimeUtils
  {
public:
   static void BrokerToUtcHourMin(const datetime broker_time, int &hour_utc, int &min_utc)
     {
      MqlDateTime dt;
      TimeToStruct(broker_time, dt);
      hour_utc = dt.hour;
      min_utc = dt.min;
      // If user runs non-UTC broker, adjust: assume inputs are UTC wall-clock mapped to broker — document in EA.
      // Standard approach: use TimeGMT() for session logic.
     }

   static int UtcHour(const datetime t)
     {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      return dt.hour;
     }

   static int UtcDayOfWeek(const datetime t)
     {
      MqlDateTime dt;
      TimeToStruct(t, dt);
      return dt.day_of_week;
     }

   static bool InHourRangeUtc(const datetime t, const int h_start, const int h_end)
     {
      int h = UtcHour(t);
      if(h_start <= h_end)
         return (h >= h_start && h < h_end);
      // wrap (e.g. 22–02)
      return (h >= h_start || h < h_end);
     }
  };

#endif // __AQ_TIMEUTILS_MQH__
