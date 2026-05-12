//+------------------------------------------------------------------+
//| NewsFilter.mqh — spread guard + manual blackout windows          |
//| Extend: read CSV/API into Data/NewsCache in future versions      |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_NEWS_MQH__
#define __AQ_NEWS_MQH__

#include "../Config/Settings.mqh"

class CNewsFilter
  {
private:
   SQuantConfig m_cfg;
   string       m_symbol;
   datetime     m_blackout_until;

public:
   CNewsFilter(void): m_blackout_until(0) {}

   void Init(const string sym, const SQuantConfig &cfg)
     {
      m_symbol = sym;
      m_cfg = cfg;
     }

   void SetManualBlackout(const datetime until_utc) { m_blackout_until = until_utc; }

   bool IsSpreadOk(void) const
     {
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      if(ask <= 0 || bid <= 0)
         return false;
      double pt = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double mult = (SymbolInfoInteger(m_symbol, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(m_symbol, SYMBOL_DIGITS) == 5) ? 10.0 : 1.0;
      double spread_pts = (ask - bid) / (pt * mult);
      return (spread_pts <= m_cfg.max_spread_points);
     }

   bool IsNewsBlockedUtc(const datetime gmt_now)
     {
      if(!m_cfg.use_news_blackout)
         return false;
      if(m_blackout_until > 0 && gmt_now < m_blackout_until)
         return true;
      return false;
     }
  };

#endif // __AQ_NEWS_MQH__
