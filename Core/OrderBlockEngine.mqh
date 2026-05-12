//+------------------------------------------------------------------+
//| OrderBlockEngine.mqh — last opposing candle before displacement  |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_ORDERBLOCK_MQH__
#define __AQ_ORDERBLOCK_MQH__

#include "../Config/Settings.mqh"
#include "../Utils/Helpers.mqh"
#include "../Utils/MathUtils.mqh"

struct SOrderBlock
  {
   bool              valid;
   bool              bullish_ob;   // demand
   double            ob_high;
   double            ob_low;
   datetime          ob_time;
   bool              mitigated;
  };

class COrderBlockEngine
  {
private:
   string            m_symbol;
   SQuantConfig      m_cfg;
   ENUM_TIMEFRAMES   m_tf;
   SOrderBlock       m_ob;

public:
                     COrderBlockEngine(void): m_tf(PERIOD_M15) { ZeroMemory(m_ob); }

   void Init(const string sym, const SQuantConfig &cfg, const ENUM_TIMEFRAMES tf)
     {
      m_symbol = sym;
      m_cfg = cfg;
      m_tf = tf;
     }

   bool DetectFromDisplacement(const bool bos_bull, const bool bos_bear, const double atr)
     {
      ZeroMemory(m_ob);
      if(atr <= 0)
         return false;

      double o[], h[], l[], c[];
      long v[];
      datetime t[];
      if(!CBarHelpers::CopyRatesSeries(m_symbol, m_tf, 80, o, h, l, c, v, t))
         return false;

      double min_body = atr * m_cfg.displacement_atr_mult;

      // displacement on bar 1
      double b1 = CMathUtils::BodySize(o[1], c[1]);

      if(bos_bull && CMathUtils::IsBullishBar(o[1], c[1]) && b1 >= min_body)
        {
         // last bearish bar before 1 is at index 2 if bearish, else scan
         for(int i = 2; i < 15; i++)
           {
            if(CMathUtils::IsBearishBar(o[i], c[i]))
              {
               m_ob.valid = true;
               m_ob.bullish_ob = true;
               m_ob.ob_high = h[i];
               m_ob.ob_low = l[i];
               m_ob.ob_time = t[i];
               break;
              }
           }
        }
      else if(bos_bear && CMathUtils::IsBearishBar(o[1], c[1]) && b1 >= min_body)
        {
         for(int i = 2; i < 15; i++)
           {
            if(CMathUtils::IsBullishBar(o[i], c[i]))
              {
               m_ob.valid = true;
               m_ob.bullish_ob = false;
               m_ob.ob_high = h[i];
               m_ob.ob_low = l[i];
               m_ob.ob_time = t[i];
               break;
              }
           }
        }

      return m_ob.valid;
     }

   void UpdateMitigation(const double bid, const double ask)
     {
      if(!m_ob.valid)
         return;
      if(m_ob.bullish_ob)
        {
         if(bid < m_ob.ob_low)
            m_ob.mitigated = true;
        }
      else
        {
         if(ask > m_ob.ob_high)
            m_ob.mitigated = true;
        }
     }

   bool PriceInOb(const double price) const
     {
      if(!m_ob.valid || m_ob.mitigated)
         return false;
      return (price >= m_ob.ob_low && price <= m_ob.ob_high);
     }

   SOrderBlock Current(void) const { return m_ob; }
  };

#endif // __AQ_ORDERBLOCK_MQH__
