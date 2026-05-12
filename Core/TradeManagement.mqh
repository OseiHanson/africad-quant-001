//+------------------------------------------------------------------+
//| TradeManagement.mqh — BE, partials, trail, structure exits         |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_TRADEMGMT_MQH__
#define __AQ_TRADEMGMT_MQH__

#include <Trade\PositionInfo.mqh>
#include "../Config/Settings.mqh"
#include "TradeExecution.mqh"
#include "MarketStructure.mqh"

class CTradeManagementEngine
  {
private:
   CPositionInfo     m_pos;
   string            m_symbol;
   SQuantConfig      m_cfg;
   CTradeExecutionEngine *m_exec;

   bool CommentHas(const string comment, const string token) const
     {
      return (StringFind(comment, token) >= 0);
     }

   double RMultiple(const ENUM_POSITION_TYPE type, const double entry, const double sl, const double price) const
     {
      double risk = MathAbs(entry - sl);
      if(risk < 1e-10)
         return 0;
      if(type == POSITION_TYPE_BUY)
         return (price - entry) / risk;
      return (entry - price) / risk;
     }

   double AtrM1(void) const
     {
      int h = iATR(m_symbol, PERIOD_M1, m_cfg.atr_period);
      if(h == INVALID_HANDLE)
         return 0;
      double b[];
      ArraySetAsSeries(b, true);
      if(CopyBuffer(h, 0, 1, 1, b) < 1)
        {
         IndicatorRelease(h);
         return 0;
        }
      double v = b[0];
      IndicatorRelease(h);
      return v;
     }

public:
   CTradeManagementEngine(void): m_exec(NULL) {}

   void Init(const string sym, const SQuantConfig &cfg, CTradeExecutionEngine &exec)
     {
      m_symbol = sym;
      m_cfg = cfg;
      m_exec = &exec;
     }

   void OnTickManage(CMarketStructureEngine &ms)
     {
      if(m_exec == NULL)
         return;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(!m_pos.SelectByIndex(i))
            continue;
         if(m_pos.Symbol() != m_symbol)
            continue;
         if(m_pos.Magic() != (long)m_cfg.magic_number)
            continue;

         ulong ticket = m_pos.Ticket();
         double entry = m_pos.PriceOpen();
         double sl = m_pos.StopLoss();
         double tp = m_pos.TakeProfit();
         double vol = m_pos.Volume();
         ENUM_POSITION_TYPE typ = m_pos.PositionType();
         string cmt = m_pos.Comment();

         bool moved_be = CommentHas(cmt, "|BE");
         bool took_partial = CommentHas(cmt, "|P1");

         double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         double price = (typ == POSITION_TYPE_BUY) ? bid : ask;

         double rr = RMultiple(typ, entry, sl, price);

         if(m_cfg.use_break_even && !moved_be && rr >= m_cfg.be_trigger_rr)
           {
            string e;
            if(m_exec.PositionModifySLTP(ticket, entry, tp, e))
               moved_be = true;
           }

         if(m_cfg.use_partial_close && !took_partial && rr >= m_cfg.partial_at_rr)
           {
            double part = vol * m_cfg.partial_percent / 100.0;
            double step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
            part = MathFloor(part / step) * step;
            double minv = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
            if(part >= minv && vol - part >= minv - 1e-8)
              {
               string e;
               if(m_exec.PositionClosePartial(ticket, part, e))
                  took_partial = true;
              }
           }

         if(m_cfg.use_trailing && rr >= m_cfg.partial_at_rr)
           {
            double atr = AtrM1();
            if(atr > 0)
              {
               double dist = atr * m_cfg.trail_atr_mult;
               double new_sl = sl;
               if(typ == POSITION_TYPE_BUY)
                 {
                  double candidate = bid - dist;
                  if(candidate > sl)
                     new_sl = candidate;
                 }
               else
                 {
                  double candidate = bid + dist;
                  if(sl == 0 || candidate < sl)
                     new_sl = candidate;
                 }
               if(new_sl != sl)
                 {
                  string e;
                  m_exec.PositionModifySLTP(ticket, new_sl, tp, e);
                 }
              }
           }

         string err_exit;
         if(typ == POSITION_TYPE_BUY && ms.BosBearSetup())
            m_exec.PositionClose(ticket, err_exit);
         if(typ == POSITION_TYPE_SELL && ms.BosBullSetup())
            m_exec.PositionClose(ticket, err_exit);
        }
     }
  };

#endif // __AQ_TRADEMGMT_MQH__
