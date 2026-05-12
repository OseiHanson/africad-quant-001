//+------------------------------------------------------------------+
//| FVGEngine.mqh — 3-candle imbalance (FVG)                         |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_FVG_MQH__
#define __AQ_FVG_MQH__

#include "../Config/Settings.mqh"
#include "../Utils/Helpers.mqh"

struct SFvgZone
  {
   bool              valid;
   bool              bullish;
   double            low;
   double            high;
   datetime          time_end;   // time of third candle (newest of pattern)
   int               shift_end;  // series index of candle3
  };

class CFVGEngine
  {
private:
   string            m_symbol;
   SQuantConfig      m_cfg;
   ENUM_TIMEFRAMES   m_tf;
   SFvgZone          m_last;

public:
                     CFVGEngine(void): m_tf(PERIOD_M15) { ZeroMemory(m_last); }

   void Init(const string sym, const SQuantConfig &cfg, const ENUM_TIMEFRAMES tf)
     {
      m_symbol = sym;
      m_cfg = cfg;
      m_tf = tf;
     }

   // Pattern on bars: 3,2,1 (all closed) — candle3 oldest of trio
   bool DetectLastClosed(void)
     {
      ZeroMemory(m_last);
      double o[], h[], l[], c[];
      long v[];
      datetime t[];
      if(!CBarHelpers::CopyRatesSeries(m_symbol, m_tf, 120, o, h, l, c, v, t))
         return false;

      int c3 = 3, c1 = 1;

      double atr = 0;
      int hATR = iATR(m_symbol, m_tf, m_cfg.atr_period);
      if(hATR != INVALID_HANDLE)
        {
         double ab[];
         ArraySetAsSeries(ab, true);
         if(CopyBuffer(hATR, 0, 1, 1, ab) > 0)
            atr = ab[0];
         IndicatorRelease(hATR);
        }
      if(atr <= 0)
         return false;

      // Bullish FVG: low of candle 1 (oldest in trio) > high of candle 3? 
      // Spec: Candle1 High < Candle3 Low (candles numbered in formation order)
      // Map: formation c1 (oldest) = index 3, c2 = 2, c3 (newest) = 1
      double min_gap = atr * m_cfg.fvg_min_gap_atr_mult;

      bool bull = (h[c3] < l[c1]);
      bool bear = (l[c3] > h[c1]);

      if(bull)
        {
         double gap = l[c1] - h[c3];
         if(gap >= min_gap)
           {
            m_last.valid = true;
            m_last.bullish = true;
            m_last.low = h[c3];
            m_last.high = l[c1];
            m_last.time_end = t[1];
            m_last.shift_end = 1;
           }
        }
      else if(bear)
        {
         double gap = l[c3] - h[c1];
         if(gap >= min_gap)
           {
            m_last.valid = true;
            m_last.bullish = false;
            m_last.low = h[c1];
            m_last.high = l[c3];
            m_last.time_end = t[1];
            m_last.shift_end = 1;
           }
        }

      return m_last.valid;
     }

   SFvgZone Last(void) const { return m_last; }

   bool AlignsWithBiasAndBos(const int bias_h4, const bool bos_bull, const bool bos_bear) const
     {
      if(!m_last.valid)
         return false;
      if(m_last.bullish)
         return (bias_h4 >= 0 && bos_bull);
      return (bias_h4 <= 0 && bos_bear);
     }
  };

#endif // __AQ_FVG_MQH__
