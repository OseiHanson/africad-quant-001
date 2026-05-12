//+------------------------------------------------------------------+
//| Settings.mqh — AFRICAD QUANT 001 configuration types              |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_SETTINGS_MQH__
#define __AQ_SETTINGS_MQH__

enum ENUM_AQ_SESSION_FILTER
  {
   AQ_SESSION_LONDON_NY = 0,    // London + NY killzones + overlap
   AQ_SESSION_LONDON_ONLY = 1,
   AQ_SESSION_NY_ONLY = 2,
   AQ_SESSION_DISABLED = 3
  };

enum ENUM_AQ_LOT_MODE
  {
   AQ_LOT_RISK_PERCENT = 0,
   AQ_LOT_FIXED = 1
  };

enum ENUM_AQ_ORDER_TYPE_ENTRY
  {
   AQ_ENTRY_MARKET = 0,
   AQ_ENTRY_LIMIT = 1,
   AQ_ENTRY_STOP = 2
  };

// Runtime configuration filled from EA inputs in OnInit()
struct SQuantConfig
  {
   // Risk
   double            risk_percent;
   double            fixed_lot;
   ENUM_AQ_LOT_MODE lot_mode;
   double            max_daily_dd_percent;
   double            max_equity_dd_percent;
   int               max_consecutive_losses;
   double            min_confidence;        // 0–100
   int               max_spread_points;
   int               max_slippage_points;

   // Structure / SMC
   int               swing_left;
   int               swing_right;
   double            displacement_atr_mult;
   int               atr_period;
   double            fvg_min_gap_atr_mult;
   double            liquidity_eq_tolerance_points;

   // Sessions (UTC)
   ENUM_AQ_SESSION_FILTER session_mode;
   int               london_start_hour;
   int               london_end_hour;
   int               ny_start_hour;
   int               ny_end_hour;
   bool              avoid_friday_after_utc;
   int               friday_cutoff_hour_utc;

   // Trade management
   bool              use_break_even;
   double            be_trigger_rr;
   bool              use_partial_close;
   double            partial_at_rr;
   double            partial_percent;
   bool              use_trailing;
   double            trail_atr_mult;
   double            tp1_rr;
   double            tp2_rr;

   // SMT / correlation
   bool              use_smt;
   string            smt_symbol;
   int               smt_tf_minutes;

   // News / spread
   bool              use_news_blackout;
   int               news_minutes_before;
   int               news_minutes_after;

   // Prop-style
   bool              use_daily_profit_target;
   double            daily_profit_target_percent;

   // UI
   bool              show_dashboard;
   bool              show_chart_objects;
   ulong             magic_number;
   string            trade_comment;
  };

#endif // __AQ_SETTINGS_MQH__
