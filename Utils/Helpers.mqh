//+------------------------------------------------------------------+
//| Helpers.mqh — bars, copying, pivots                              |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_HELPERS_MQH__
#define __AQ_HELPERS_MQH__

class CBarHelpers
  {
public:
   // rates as series: 0 = current forming, 1 = last closed
   static bool CopyRatesSeries(const string sym, const ENUM_TIMEFRAMES tf, const int count,
                               double &open[], double &high[], double &low[], double &close[],
                               long &tick_vol[], datetime &time[])
     {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      int n = CopyRates(sym, tf, 0, count, rates);
      if(n <= 0)
         return false;
      ArrayResize(open, n);
      ArrayResize(high, n);
      ArrayResize(low, n);
      ArrayResize(close, n);
      ArrayResize(tick_vol, n);
      ArrayResize(time, n);
      ArraySetAsSeries(open, true);
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(close, true);
      ArraySetAsSeries(tick_vol, true);
      ArraySetAsSeries(time, true);
      for(int i = 0; i < n; i++)
        {
         open[i] = rates[i].open;
         high[i] = rates[i].high;
         low[i] = rates[i].low;
         close[i] = rates[i].close;
         tick_vol[i] = rates[i].tick_volume;
         time[i] = rates[i].time;
        }
      return true;
     }

   // Swing high at bar index 'sh' (series): older bars = higher index
   static bool IsSwingHighSeries(const double &high[], const int sh, const int left, const int right)
     {
      int total = ArraySize(high);
      if(sh < right || sh + left >= total)
         return false;
      double piv = high[sh];
      for(int i = 1; i <= left; i++)
        {
         if(high[sh + i] > piv)
            return false;
        }
      for(int i = 1; i <= right; i++)
        {
         if(high[sh - i] > piv)
            return false;
        }
      return true;
     }

   static bool IsSwingLowSeries(const double &low[], const int sh, const int left, const int right)
     {
      int total = ArraySize(low);
      if(sh < right || sh + left >= total)
         return false;
      double piv = low[sh];
      for(int i = 1; i <= left; i++)
        {
         if(low[sh + i] < piv)
            return false;
        }
      for(int i = 1; i <= right; i++)
        {
         if(low[sh - i] < piv)
            return false;
        }
      return true;
     }
  };

#endif // __AQ_HELPERS_MQH__
