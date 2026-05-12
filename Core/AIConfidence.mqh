//+------------------------------------------------------------------+
//| AIConfidence.mqh — weighted institutional setup score            |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_AICONF_MQH__
#define __AQ_AICONF_MQH__

#include "../Config/Settings.mqh"

class CAIConfidenceEngine
  {
public:
   static double ScoreSetup(const bool liquidity_sweep_ok,
                            const bool bos_ok,
                            const bool fvg_ok,
                            const bool ob_ok,
                            const bool session_ok,
                            const bool volume_ok)
     {
      double s = 0;
      if(liquidity_sweep_ok)
         s += 25.0;
      if(bos_ok)
         s += 20.0;
      if(fvg_ok)
         s += 20.0;
      if(ob_ok)
         s += 20.0;
      if(session_ok)
         s += 10.0;
      if(volume_ok)
         s += 5.0;
      return s;
     }

   static bool PassesThreshold(const SQuantConfig &cfg, const double score)
     {
      return (score + 1e-8 >= cfg.min_confidence);
     }
  };

#endif // __AQ_AICONF_MQH__
