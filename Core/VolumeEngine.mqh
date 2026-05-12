//+------------------------------------------------------------------+
//| VolumeEngine.mqh — tick volume relative participation              |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_VOLUME_MQH__
#define __AQ_VOLUME_MQH__

#include "../Utils/Helpers.mqh"

class CVolumeEngine
  {
private:
   string          m_symbol;
   ENUM_TIMEFRAMES m_tf;

public:
   void Init(const string sym, const ENUM_TIMEFRAMES tf)
     {
      m_symbol = sym;
      m_tf = tf;
     }

   // Returns ratio of last closed bar volume vs SMA of volumes (20)
   double RelativeVolumeRatio(void)
     {
      double o[], h[], l[], c[];
      long v[];
      datetime t[];
      if(!CBarHelpers::CopyRatesSeries(m_symbol, m_tf, 60, o, h, l, c, v, t))
         return 1.0;
      if(ArraySize(v) < 25)
         return 1.0;
      double sum = 0;
      for(int i = 2; i <= 21; i++)
         sum += (double)v[i];
      double avg = sum / 20.0;
      if(avg <= 0)
         return 1.0;
      return (double)v[1] / avg;
     }

   bool StrongParticipation(const double min_ratio)
     {
      return RelativeVolumeRatio() >= min_ratio;
     }
  };

#endif // __AQ_VOLUME_MQH__
