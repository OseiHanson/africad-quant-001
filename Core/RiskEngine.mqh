//+------------------------------------------------------------------+
//| RiskEngine.mqh — capital protection & prop-style limits          |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_RISK_MQH__
#define __AQ_RISK_MQH__

#include "../Config/Settings.mqh"

class CRiskEngine
  {
private:
   SQuantConfig m_cfg;
   int          m_day_id;
   double       m_day_start_equity;
   double       m_high_water_equity;
   int          m_consecutive_losses;
   bool         m_halted;

public:
   CRiskEngine(void):
      m_day_id(-1), m_day_start_equity(0), m_high_water_equity(0),
      m_consecutive_losses(0), m_halted(false)
     {
     }

   void Init(const SQuantConfig &cfg) { m_cfg = cfg; }

   void ResetHalt(void) { m_halted = false; }

   int ConsecutiveLosses(void) const { return m_consecutive_losses; }

   void RegisterWin(void) { m_consecutive_losses = 0; }

   void RegisterLoss(void)
     {
      m_consecutive_losses++;
     }

   void UpdateDayAnchor(void)
     {
      MqlDateTime g;
      TimeToStruct(TimeGMT(), g);
      int id = g.year * 10000 + g.mon * 100 + g.day;
      if(id != m_day_id)
        {
         m_day_id = id;
         m_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
         m_high_water_equity = m_day_start_equity;
         // optional: reset consecutive at new day — conservative: keep
        }
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      if(eq > m_high_water_equity)
         m_high_water_equity = eq;
     }

   bool DailyProfitTargetHit(void) const
     {
      if(!m_cfg.use_daily_profit_target || m_cfg.daily_profit_target_percent <= 0)
         return false;
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      double gain = (eq - m_day_start_equity) / m_day_start_equity * 100.0;
      return (gain >= m_cfg.daily_profit_target_percent);
     }

   bool BreachedDailyDd(void) const
     {
      if(m_cfg.max_daily_dd_percent <= 0 || m_day_start_equity <= 0)
         return false;
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      double dd = (m_day_start_equity - eq) / m_day_start_equity * 100.0;
      return (dd >= m_cfg.max_daily_dd_percent);
     }

   bool BreachedEquityDd(void) const
     {
      if(m_cfg.max_equity_dd_percent <= 0 || m_high_water_equity <= 0)
         return false;
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      double dd = (m_high_water_equity - eq) / m_high_water_equity * 100.0;
      return (dd >= m_cfg.max_equity_dd_percent);
     }

   bool TooManyConsecutiveLosses(void) const
     {
      if(m_cfg.max_consecutive_losses <= 0)
         return false;
      return (m_consecutive_losses >= m_cfg.max_consecutive_losses);
     }

   void Halt(const string reason)
     {
      m_halted = true;
      Print("[AQ001][RISK] TRADING HALTED: ", reason);
     }

   bool IsHalted(void) const { return m_halted; }

   bool CanOpenNewTrade(void)
     {
      UpdateDayAnchor();
      if(m_halted)
         return false;
      if(DailyProfitTargetHit())
         return false;
      if(BreachedDailyDd())
        {
         Halt("Daily drawdown limit");
         return false;
        }
      if(BreachedEquityDd())
        {
         Halt("Equity drawdown from high-water mark");
         return false;
        }
      if(TooManyConsecutiveLosses())
        {
         Halt("Max consecutive losses");
         return false;
        }
      return true;
     }

   double DayStartEquity(void) const { return m_day_start_equity; }
   double HighWaterEquity(void) const { return m_high_water_equity; }
  };

#endif // __AQ_RISK_MQH__
