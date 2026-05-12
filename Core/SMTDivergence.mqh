//+------------------------------------------------------------------+
//| SMTDivergence.mqh — correlated symbol structure check              |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_SMT_MQH__
#define __AQ_SMT_MQH__

#include "../Config/Settings.mqh"
#include "../Utils/Helpers.mqh"

class CSMTDivergenceEngine
  {
private:
   SQuantConfig      m_cfg;
   string            m_primary;

public:
   void Init(const string primary_sym, const SQuantConfig &cfg)
     {
      m_primary = primary_sym;
      m_cfg = cfg;
     }

   // Returns true if SMT filter passes (no bearish divergence against long bias)
   bool ConfirmLongBias(void)
     {
      if(!m_cfg.use_smt || m_cfg.smt_symbol == "" || m_cfg.smt_symbol == m_primary)
         return true;
      ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)m_cfg.smt_tf_minutes;
      double o[], h[], l[], c[];
      long v[];
      datetime t[];
      if(!CBarHelpers::CopyRatesSeries(m_cfg.smt_symbol, tf, 80, o, h, l, c, v, t))
         return true; // fail open if data missing

      // Simple: correlated FX should not make fresh LL while primary makes HL proxy
      double p_low_recent = l[1];
      double p_low_prior = l[10];
      bool corr_selling = (c[1] < c[5] && p_low_recent < p_low_prior);
      return !corr_selling;
     }

   bool ConfirmShortBias(void)
     {
      if(!m_cfg.use_smt || m_cfg.smt_symbol == "" || m_cfg.smt_symbol == m_primary)
         return true;
      ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)m_cfg.smt_tf_minutes;
      double o[], h[], l[], c[];
      long v[];
      datetime t[];
      if(!CBarHelpers::CopyRatesSeries(m_cfg.smt_symbol, tf, 80, o, h, l, c, v, t))
         return true;

      double p_high_recent = h[1];
      double p_high_prior = h[10];
      bool corr_buying = (c[1] > c[5] && p_high_recent > p_high_prior);
      return !corr_buying;
     }
  };

#endif // __AQ_SMT_MQH__
