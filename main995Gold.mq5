//+------------------------------------------------------------------+
//| main995Gold.mq5 — same as MainEA; keep inside AFRICAD_QUANT_001\  |
//+------------------------------------------------------------------+
//| FOLDER RULE (fixes "file ...\Experts\Config\Settings.mqh not   |
//| found"): keep this .mq5 INSIDE the project folder, and copy the  |
//| WHOLE folder to:                                                  |
//|   <Terminal>\MQL5\Experts\AFRICAD_QUANT_001\                      |
//| so you have Experts\AFRICAD_QUANT_001\Config\Settings.mqh etc.   |
//| Do NOT place only the .mq5 file in MQL5\Experts\ root.           |
//| See INSTALL_MT5.txt in this folder.                              |
//+------------------------------------------------------------------+
#property copyright "AFRICAD QUANT"
#property version   "1.001"
#property strict

#include <Trade\Trade.mqh>
#include "Config/Settings.mqh"
#include "Utils/Logger.mqh"
#include "Utils/Helpers.mqh"
#include "Utils/SymbolUtils.mqh"
#include "Core/MarketStructure.mqh"
#include "Core/LiquidityEngine.mqh"
#include "Core/FVGEngine.mqh"
#include "Core/OrderBlockEngine.mqh"
#include "Core/SessionEngine.mqh"
#include "Core/NewsFilter.mqh"
#include "Core/VolumeEngine.mqh"
#include "Core/SMTDivergence.mqh"
#include "Core/AIConfidence.mqh"
#include "Core/RiskEngine.mqh"
#include "Core/TradeExecution.mqh"
#include "Core/TradeManagement.mqh"
#include "UI/Dashboard.mqh"
#include "UI/Drawings.mqh"
#include "UI/Notifications.mqh"

//--- inputs (defaults tuned for XAUUSD / XAUUSDm — calibrate per broker)
input group "Symbol — Gold (XAUUSD)"
input bool              InpTradeGoldOnly       = true;       // Require XAU*USD symbol on chart
input bool              InpApplyGoldPresets    = true;       // Floor spread/slippage/liquidity for gold

input group "Risk & execution"
input double            InpRiskPercent          = 0.75;      // Risk per trade (% balance)
input ENUM_AQ_LOT_MODE  InpLotMode              = AQ_LOT_RISK_PERCENT;
input double            InpFixedLot            = 0.01;      // Fixed lot (if mode = fixed)
input double            InpMaxDailyDdPercent   = 5.0;      // Max daily drawdown (%)
input double            InpMaxEquityDdPercent  = 10.0;     // Max DD from high-water (%)
input int               InpMaxConsecLosses     = 4;        // Max consecutive losses (0=off)
input double            InpMinConfidence       = 80.0;     // Minimum AI score (%)
input int               InpMaxSpreadPoints     = 220;      // Max spread (points) — raise if broker wider
input int               InpMaxSlippagePoints   = 70;       // Max slippage deviation (points)
input ulong             InpMagic               = 20260512;  // Magic number
input string            InpComment             = "AQ001";

input group "Structure & SMC"
input int               InpSwingLeft           = 2;
input int               InpSwingRight          = 2;
input double            InpDisplacementAtrMult = 0.40;     // Min displacement vs ATR
input int               InpAtrPeriod           = 14;
input double            InpFvgMinGapAtrMult    = 0.12;      // Min FVG gap vs ATR
input double            InpLiqEqTolPoints      = 55.0;      // Equal high/low tolerance (pts)

input group "Sessions (UTC on chart server — prefer GMT-based broker or adjust)"
input ENUM_AQ_SESSION_FILTER InpSessionMode    = AQ_SESSION_LONDON_NY;
input int               InpLondonStart         = 7;
input int               InpLondonEnd           = 10;
input int               InpNyStart             = 13;
input int               InpNyEnd               = 16;
input bool              InpAvoidFridayLate    = true;
input int               InpFridayCutoffUtc     = 18;

input group "Trade management"
input bool              InpUseBreakEven       = true;
input double            InpBeTriggerRR        = 1.0;
input bool              InpUsePartial         = true;
input double            InpPartialAtRR        = 1.0;
input double            InpPartialPercent     = 40.0;
input bool              InpUseTrail           = true;
input double            InpTrailAtrMult       = 1.2;
input double            InpTp1Rr              = 1.0;        // informational / partial trigger
input double            InpTp2Rr              = 3.0;        // final TP distance (R)

input group "SMT / correlation"
input bool              InpUseSmt             = false;
input string            InpSmtSymbol          = "";       // e.g. DXY proxy / US500 — empty = skip
input int               InpSmtTfMinutes       = 15;        // e.g. 15 = M15

input group "News / volatility"
input bool              InpUseNewsBlackout    = false;
input int               InpNewsMinBefore      = 30;
input int               InpNewsMinAfter       = 30;

input group "Prop options"
input bool              InpUseDailyProfitTarget = false;
input double            InpDailyProfitTargetPct = 3.0;

input group "UI"
input bool              InpShowDashboard      = true;
input bool              InpShowDrawings       = true;

input group "Entry mode"
input ENUM_AQ_ORDER_TYPE_ENTRY InpEntryType   = AQ_ENTRY_MARKET;

//--- globals
CQuantLogger            g_log;
CMarketStructureEngine  g_ms;
CLiquidityEngine        g_liq;
CFVGEngine              g_fvg;
COrderBlockEngine       g_ob;
CSessionEngine          g_sess;
CNewsFilter             g_news;
CVolumeEngine           g_vol;
CSMTDivergenceEngine    g_smt;
CRiskEngine             g_risk;
CTradeExecutionEngine   g_exec;
CTradeManagementEngine  g_mgmt;
CDashboard              g_dash;
CChartDrawings          g_draw;

SQuantConfig            g_cfg;
datetime                g_last_bar_m5 = 0;

//+------------------------------------------------------------------+
bool BuildConfigFromInputs(SQuantConfig &c)
  {
   c.risk_percent = InpRiskPercent;
   c.fixed_lot = InpFixedLot;
   c.lot_mode = InpLotMode;
   c.max_daily_dd_percent = InpMaxDailyDdPercent;
   c.max_equity_dd_percent = InpMaxEquityDdPercent;
   c.max_consecutive_losses = InpMaxConsecLosses;
   c.min_confidence = InpMinConfidence;
   c.max_spread_points = InpMaxSpreadPoints;
   c.max_slippage_points = InpMaxSlippagePoints;

   c.swing_left = InpSwingLeft;
   c.swing_right = InpSwingRight;
   c.displacement_atr_mult = InpDisplacementAtrMult;
   c.atr_period = InpAtrPeriod;
   c.fvg_min_gap_atr_mult = InpFvgMinGapAtrMult;
   c.liquidity_eq_tolerance_points = InpLiqEqTolPoints;

   c.session_mode = InpSessionMode;
   c.london_start_hour = InpLondonStart;
   c.london_end_hour = InpLondonEnd;
   c.ny_start_hour = InpNyStart;
   c.ny_end_hour = InpNyEnd;
   c.avoid_friday_after_utc = InpAvoidFridayLate;
   c.friday_cutoff_hour_utc = InpFridayCutoffUtc;

   c.use_break_even = InpUseBreakEven;
   c.be_trigger_rr = InpBeTriggerRR;
   c.use_partial_close = InpUsePartial;
   c.partial_at_rr = InpPartialAtRR;
   c.partial_percent = InpPartialPercent;
   c.use_trailing = InpUseTrail;
   c.trail_atr_mult = InpTrailAtrMult;
   c.tp1_rr = InpTp1Rr;
   c.tp2_rr = InpTp2Rr;

   c.use_smt = InpUseSmt;
   c.smt_symbol = InpSmtSymbol;
   c.smt_tf_minutes = InpSmtTfMinutes;

   c.use_news_blackout = InpUseNewsBlackout;
   c.news_minutes_before = InpNewsMinBefore;
   c.news_minutes_after = InpNewsMinAfter;

   c.use_daily_profit_target = InpUseDailyProfitTarget;
   c.daily_profit_target_percent = InpDailyProfitTargetPct;

   c.show_dashboard = InpShowDashboard;
   c.show_chart_objects = InpShowDrawings;
   c.magic_number = InpMagic;
   c.trade_comment = InpComment;

   return true;
  }

//+------------------------------------------------------------------+
void ApplyGoldPresetToConfig(SQuantConfig &c)
  {
   if(!InpApplyGoldPresets || !CSymbolUtils::IsGoldUsd(_Symbol))
      return;
   c.max_spread_points = MathMax(c.max_spread_points, 180);
   c.max_slippage_points = MathMax(c.max_slippage_points, 50);
   c.liquidity_eq_tolerance_points = MathMax(c.liquidity_eq_tolerance_points, 35.0);
  }

//+------------------------------------------------------------------+
double SpreadPoints(void)
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double mult = (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5) ? 10.0 : 1.0;
   return (ask - bid) / (pt * mult);
  }

//+------------------------------------------------------------------+
bool HasOurPosition(void)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)InpMagic)
         continue;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
bool M5ConfirmationBull(void)
  {
   double o[], h[], l[], c[];
   long v[];
   datetime t[];
   if(!CBarHelpers::CopyRatesSeries(_Symbol, PERIOD_M5, 30, o, h, l, c, v, t))
      return false;
   return (c[1] > o[1]);
  }

//+------------------------------------------------------------------+
bool M5ConfirmationBear(void)
  {
   double o[], h[], l[], c[];
   long v[];
   datetime t[];
   if(!CBarHelpers::CopyRatesSeries(_Symbol, PERIOD_M5, 30, o, h, l, c, v, t))
      return false;
   return (c[1] < o[1]);
  }

//+------------------------------------------------------------------+
int OnInit(void)
  {
   if(InpTradeGoldOnly && !CSymbolUtils::IsGoldUsd(_Symbol))
     {
      Alert("AFRICAD QUANT 001: attach this EA to XAUUSD or XAUUSDm (Gold vs USD).");
      return INIT_FAILED;
     }

   CSymbolUtils::EnsureSelected(_Symbol);

   BuildConfigFromInputs(g_cfg);
   ApplyGoldPresetToConfig(g_cfg);

   g_log.Init("AFRICAD_QUANT_001", 2);
   g_log.Info("Init AFRICAD QUANT 001 on " + _Symbol + " | gold=" + (CSymbolUtils::IsGoldUsd(_Symbol) ? "yes" : "no"));

   g_ms.Init(_Symbol, g_cfg);
   g_ms.SetTimeframes(PERIOD_H4, PERIOD_H1, PERIOD_M15, PERIOD_M5);

   g_liq.Init(_Symbol, g_cfg, PERIOD_M15);
   g_fvg.Init(_Symbol, g_cfg, PERIOD_M15);
   g_ob.Init(_Symbol, g_cfg, PERIOD_M15);
   g_sess.Init(g_cfg);
   g_news.Init(_Symbol, g_cfg);
   g_vol.Init(_Symbol, PERIOD_M15);
   g_smt.Init(_Symbol, g_cfg);
   g_risk.Init(g_cfg);
   g_exec.Init(_Symbol, g_cfg);
   g_mgmt.Init(_Symbol, g_cfg, g_exec);

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   g_dash.Clear();
   g_draw.Refresh(false, g_fvg.Last(), g_ob.Current());
   g_log.Info("Deinit reason=" + IntegerToString(reason));
   g_log.Close();
  }

//+------------------------------------------------------------------+
void OnTick(void)
  {
   datetime t_m5 = iTime(_Symbol, PERIOD_M5, 0);
   bool new_m5 = (t_m5 != g_last_bar_m5);
   if(new_m5)
      g_last_bar_m5 = t_m5;

   g_risk.UpdateDayAnchor();
   g_ms.Update();
   g_liq.Update();
   g_fvg.DetectLastClosed();
   g_ob.DetectFromDisplacement(g_ms.BosBullSetup(), g_ms.BosBearSetup(), g_ms.AtrSetup());
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   g_ob.UpdateMitigation(bid, ask);

   datetime gmt = TimeGMT();
   bool sess_ok = g_sess.IsTradingSessionUtc(gmt);
   bool news_block = g_news.IsNewsBlockedUtc(gmt);
   bool spread_ok = g_news.IsSpreadOk();

   SLiquidityState liq = g_liq.State();
   SFvgZone fvg = g_fvg.Last();
   SOrderBlock ob = g_ob.Current();

   bool sweep_bull = (liq.ssl_swept && liq.ssl_rejection);
   bool sweep_bear = (liq.bsl_swept && liq.bsl_rejection);

   bool bos_bull = g_ms.BosBullSetup();
   bool bos_bear = g_ms.BosBearSetup();

   bool fvg_bull_ok = fvg.valid && fvg.bullish && g_fvg.AlignsWithBiasAndBos(g_ms.BiasH4(), bos_bull, bos_bear);
   bool fvg_bear_ok = fvg.valid && !fvg.bullish && g_fvg.AlignsWithBiasAndBos(g_ms.BiasH4(), bos_bull, bos_bear);

   bool ob_bull_ok = ob.valid && ob.bullish_ob && !ob.mitigated;
   bool ob_bear_ok = ob.valid && !ob.bullish_ob && !ob.mitigated;

   double vol_ratio = g_vol.RelativeVolumeRatio();
   bool vol_ok = (vol_ratio >= 1.05);

   bool smt_long_ok = g_smt.ConfirmLongBias();
   bool smt_short_ok = g_smt.ConfirmShortBias();

   double conf_long = CAIConfidenceEngine::ScoreSetup(sweep_bull, bos_bull, fvg_bull_ok, ob_bull_ok, sess_ok, vol_ok);
   double conf_short = CAIConfidenceEngine::ScoreSetup(sweep_bear, bos_bear, fvg_bear_ok, ob_bear_ok, sess_ok, vol_ok);

   // SMT soft gate: if fails, reduce score notionally by treating session as weak — v1 hard block
   if(InpUseSmt)
     {
      if(!smt_long_ok)
         conf_long = MathMin(conf_long, 70.0);
      if(!smt_short_ok)
         conf_short = MathMin(conf_short, 70.0);
     }

   string setup_txt = "SCAN";
   if(conf_long >= InpMinConfidence)
      setup_txt = "LONG CAND";
   if(conf_short >= InpMinConfidence)
      setup_txt = "SHORT CAND";

   g_dash.Update(InpShowDashboard, g_sess.SessionTagUtc(gmt), g_ms.BiasH4(),
                 MathMax(conf_long, conf_short), SpreadPoints(), InpRiskPercent, setup_txt);
   g_draw.Refresh(InpShowDrawings, fvg, ob);

   g_mgmt.OnTickManage(g_ms);

   if(!new_m5)
      return;

   if(!g_risk.CanOpenNewTrade())
      return;
   if(!sess_ok || news_block || !spread_ok)
      return;
   if(HasOurPosition())
      return;

   double atr = g_ms.AtrSetup();
   if(atr <= 0)
      return;

   double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double mult = (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5) ? 10.0 : 1.0;
   double buf = atr * 0.15;

   //--- Long institutional flow
   if(g_ms.BiasH4() > 0 && sweep_bull && bos_bull && fvg_bull_ok && ob_bull_ok && M5ConfirmationBull())
     {
      if(!CAIConfidenceEngine::PassesThreshold(g_cfg, conf_long))
         return;
      if(!smt_long_ok && InpUseSmt)
         return;

      double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(InpEntryType == AQ_ENTRY_LIMIT)
         entry = MathMin(ob.ob_low + pt * mult, fvg.low + pt * mult);
      if(InpEntryType == AQ_ENTRY_LIMIT && entry >= SymbolInfoDouble(_Symbol, SYMBOL_ASK))
         return;

      double sl = MathMin(ob.ob_low, fvg.low) - buf;
      if(sl >= entry)
         sl = entry - atr * 1.2;

      double risk = entry - sl;
      if(risk <= 0)
         return;
      double tp2 = entry + risk * InpTp2Rr;

      string err;
      bool sent = false;
      if(InpEntryType == AQ_ENTRY_MARKET)
         sent = g_exec.OpenMarket(ORDER_TYPE_BUY, sl, entry + risk * InpTp1Rr, tp2, 3, err);
      else if(InpEntryType == AQ_ENTRY_LIMIT)
         sent = g_exec.OpenLimit(ORDER_TYPE_BUY, entry, sl, tp2, err);

      if(sent)
        {
         g_log.Info("BUY sent conf=" + DoubleToString(conf_long, 1));
         CNotify::Push("AQ001", "BUY " + _Symbol);
        }
      else
         g_log.Error("BUY failed: " + err);
     }

   //--- Short institutional flow
   if(g_ms.BiasH4() < 0 && sweep_bear && bos_bear && fvg_bear_ok && ob_bear_ok && M5ConfirmationBear())
     {
      if(!CAIConfidenceEngine::PassesThreshold(g_cfg, conf_short))
         return;
      if(!smt_short_ok && InpUseSmt)
         return;

      double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(InpEntryType == AQ_ENTRY_LIMIT)
         entry = MathMax(ob.ob_high - pt * mult, fvg.high - pt * mult);
      if(InpEntryType == AQ_ENTRY_LIMIT && entry <= SymbolInfoDouble(_Symbol, SYMBOL_BID))
         return;

      double sl = MathMax(ob.ob_high, fvg.high) + buf;
      if(sl <= entry)
         sl = entry + atr * 1.2;

      double risk = sl - entry;
      if(risk <= 0)
         return;
      double tp2 = entry - risk * InpTp2Rr;

      string err;
      bool sent = false;
      if(InpEntryType == AQ_ENTRY_MARKET)
         sent = g_exec.OpenMarket(ORDER_TYPE_SELL, sl, entry - risk * InpTp1Rr, tp2, 3, err);
      else if(InpEntryType == AQ_ENTRY_LIMIT)
         sent = g_exec.OpenLimit(ORDER_TYPE_SELL, entry, sl, tp2, err);

      if(sent)
        {
         g_log.Info("SELL sent conf=" + DoubleToString(conf_short, 1));
         CNotify::Push("AQ001", "SELL " + _Symbol);
        }
      else
         g_log.Error("SELL failed: " + err);
     }
  }

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;
   if(trans.symbol != _Symbol)
      return;

   ulong deal = trans.deal;
   if(deal == 0)
      return;
   if(!HistoryDealSelect(deal))
      return;
   if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT)
      return;
   if(HistoryDealGetInteger(deal, DEAL_MAGIC) != (long)InpMagic)
      return;

   double profit = HistoryDealGetDouble(deal, DEAL_PROFIT)
                   + HistoryDealGetDouble(deal, DEAL_SWAP)
                   + HistoryDealGetDouble(deal, DEAL_COMMISSION);
   if(profit >= 0)
      g_risk.RegisterWin();
   else
      g_risk.RegisterLoss();
  }

//+------------------------------------------------------------------+
