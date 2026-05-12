//+------------------------------------------------------------------+
//| LiquidityEngine.mqh — equal highs/lows, sweep detection            |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_LIQUIDITY_MQH__
#define __AQ_LIQUIDITY_MQH__

#include "../Config/Settings.mqh"
#include "../Utils/Helpers.mqh"
#include "../Utils/MathUtils.mqh"

struct SLiquidityState
  {
   bool              eq_highs;
   bool              eq_lows;
   double            pool_high;
   double            pool_low;
   bool              ssl_swept;     // sell-side / lows raided
   bool              bsl_swept;     // buy-side / highs raided
   bool              ssl_rejection; // sweep + close back above pool
   bool              bsl_rejection;
  };

class CLiquidityEngine
  {
private:
   string            m_symbol;
   SQuantConfig      m_cfg;
   ENUM_TIMEFRAMES   m_tf;
   SLiquidityState   m_state;

   void ResetState(void)
     {
      ZeroMemory(m_state);
     }

public:
                     CLiquidityEngine(void): m_tf(PERIOD_M15) { ResetState(); }

   void Init(const string sym, const SQuantConfig &cfg, const ENUM_TIMEFRAMES tf)
     {
      m_symbol = sym;
      m_cfg = cfg;
      m_tf = tf;
     }

   bool Update(void)
     {
      ResetState();
      double o[], h[], l[], c[];
      long v[];
      datetime t[];
      if(!CBarHelpers::CopyRatesSeries(m_symbol, m_tf, 200, o, h, l, c, v, t))
         return false;

      double tol = CMathUtils::PointsToPrice(m_symbol, m_cfg.liquidity_eq_tolerance_points);

      // Scan last 40 closed bars (indices 2..41) for equal highs / lows clusters vs bar 1
      int look = 40;
      double ref_high = h[1];
      double ref_low = l[1];
      int eqh = 0, eql = 0;
      double sumh = 0, suml = 0;

      for(int i = 2; i <= look; i++)
        {
         if(MathAbs(h[i] - ref_high) <= tol)
           {
            eqh++;
            sumh += h[i];
           }
         if(MathAbs(l[i] - ref_low) <= tol)
           {
            eql++;
            suml += l[i];
           }
        }

      if(eqh >= 1)
        {
         m_state.eq_highs = true;
         m_state.pool_high = (sumh + ref_high) / (eqh + 1);
        }
      if(eql >= 1)
        {
         m_state.eq_lows = true;
         m_state.pool_low = (suml + ref_low) / (eql + 1);
        }

      // Sweep: wick through pool on bar 1, rejection = close back inside range
      if(m_state.eq_lows && m_state.pool_low > 0)
        {
         if(l[1] < m_state.pool_low - tol * 0.25 && c[1] > m_state.pool_low)
           {
            m_state.ssl_swept = true;
            m_state.ssl_rejection = CMathUtils::IsBullishBar(o[1], c[1]);
           }
        }

      if(m_state.eq_highs && m_state.pool_high > 0)
        {
         if(h[1] > m_state.pool_high + tol * 0.25 && c[1] < m_state.pool_high)
           {
            m_state.bsl_swept = true;
            m_state.bsl_rejection = CMathUtils::IsBearishBar(o[1], c[1]);
           }
        }

      return true;
     }

   SLiquidityState State(void) const { return m_state; }
  };

#endif // __AQ_LIQUIDITY_MQH__
