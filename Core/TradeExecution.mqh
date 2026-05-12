//+------------------------------------------------------------------+
//| TradeExecution.mqh — orders, sizing, validation                  |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_TRADEEXEC_MQH__
#define __AQ_TRADEEXEC_MQH__

#include <Trade\Trade.mqh>
#include "../Config/Settings.mqh"
#include "../Utils/MathUtils.mqh"

class CTradeExecutionEngine
  {
private:
   CTrade            m_trade;
   string            m_symbol;
   SQuantConfig      m_cfg;

   bool NormalizeVolume(double &vol) const
     {
      double step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      double minv = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double maxv = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      if(step <= 0)
         step = 0.01;
      vol = MathFloor(vol / step) * step;
      if(vol < minv)
         vol = minv;
      if(vol > maxv)
         vol = maxv;
      return (vol >= minv - 1e-8);
     }

public:
   void Init(const string sym, const SQuantConfig &cfg)
     {
      m_symbol = sym;
      m_cfg = cfg;
      m_trade.SetExpertMagicNumber((long)m_cfg.magic_number);
      m_trade.SetDeviationInPoints(m_cfg.max_slippage_points);
      m_trade.SetTypeFillingBySymbol(m_symbol);
      m_trade.SetAsyncMode(false);
     }

   bool SpreadOk(void) const
     {
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double pt = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double mult = (SymbolInfoInteger(m_symbol, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(m_symbol, SYMBOL_DIGITS) == 5) ? 10.0 : 1.0;
      double sp = (ask - bid) / (pt * mult);
      return sp <= m_cfg.max_spread_points;
     }

   bool CalcVolumeForRisk(const ENUM_ORDER_TYPE type, const double entry_price,
                          const double sl_price, double &lots_out)
     {
      lots_out = m_cfg.fixed_lot;
      if(m_cfg.lot_mode == AQ_LOT_FIXED)
         return NormalizeVolume(lots_out);

      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double risk_money = balance * m_cfg.risk_percent / 100.0;
      if(risk_money <= 0)
         return false;

      double profit_per_lot = 0;
      if(!OrderCalcProfit(type, m_symbol, 1.0, entry_price, sl_price, profit_per_lot))
         return false;
      double loss_per_lot = MathAbs(profit_per_lot);
      if(loss_per_lot < 1e-8)
         return false;

      lots_out = risk_money / loss_per_lot;
      return NormalizeVolume(lots_out);
     }

   bool OpenMarket(const ENUM_ORDER_TYPE type, const double sl, const double tp1, const double tp2,
                   const int max_retries, string &err)
     {
      err = "";
      if(!SpreadOk())
        {
         err = "Spread too wide";
         return false;
        }

      double price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_ASK) : SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double lots = 0;
      if(!CalcVolumeForRisk(type, price, sl, lots))
        {
         err = "Lot calc failed";
         return false;
        }

      for(int k = 0; k < max_retries; k++)
        {
         bool ok = false;
         if(type == ORDER_TYPE_BUY)
            ok = m_trade.Buy(lots, m_symbol, price, sl, tp2, m_cfg.trade_comment);
         else
            ok = m_trade.Sell(lots, m_symbol, price, sl, tp2, m_cfg.trade_comment);

         if(ok)
            return true;
         err = m_trade.ResultRetcodeDescription();
         Sleep(200 + 100 * k);
        }
      return false;
     }

   bool OpenLimit(const ENUM_ORDER_TYPE type, const double entry, const double sl, const double tp2,
                  string &err)
     {
      err = "";
      double lots = 0;
      if(!CalcVolumeForRisk(type, entry, sl, lots))
        {
         err = "Lot calc failed";
         return false;
        }
      bool ok = false;
      datetime exp = 0;
      if(type == ORDER_TYPE_BUY)
         ok = m_trade.BuyLimit(lots, entry, m_symbol, sl, tp2, ORDER_TIME_GTC, exp, m_cfg.trade_comment);
      else
         ok = m_trade.SellLimit(lots, entry, m_symbol, sl, tp2, ORDER_TIME_GTC, exp, m_cfg.trade_comment);
      if(!ok)
         err = m_trade.ResultRetcodeDescription();
      return ok;
     }

   bool PositionModifySLTP(const ulong ticket, const double sl, const double tp, string &err)
     {
      if(!PositionSelectByTicket(ticket))
        {
         err = "Select ticket failed";
         return false;
        }
      bool ok = m_trade.PositionModify(ticket, sl, tp);
      if(!ok)
         err = m_trade.ResultRetcodeDescription();
      return ok;
     }

   bool PositionClosePartial(const ulong ticket, const double volume, string &err)
     {
      bool ok = m_trade.PositionClosePartial(ticket, volume);
      if(!ok)
         err = m_trade.ResultRetcodeDescription();
      return ok;
     }

   bool PositionClose(const ulong ticket, string &err)
     {
      bool ok = m_trade.PositionClose(ticket);
      if(!ok)
         err = m_trade.ResultRetcodeDescription();
      return ok;
     }
  };

#endif // __AQ_TRADEEXEC_MQH__
