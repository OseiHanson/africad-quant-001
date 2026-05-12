//+------------------------------------------------------------------+
//| MarketStructure.mqh — swings, BOS, CHOCH, HTF bias               |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_MARKETSTRUCTURE_MQH__
#define __AQ_MARKETSTRUCTURE_MQH__

#include "../Config/Settings.mqh"
#include "../Utils/Helpers.mqh"
#include "../Utils/MathUtils.mqh"

struct SSwingPoint
  {
   datetime          time;
   double            price;
   int               bar_index; // series index at detection
  };

class CMarketStructureEngine
  {
private:
   string            m_symbol;
   SQuantConfig      m_cfg;

   int               m_bias_h4;   // 1 bull, -1 bear, 0 neutral
   int               m_bias_h1;

   bool              m_bos_bull_setup_tf;
   bool              m_bos_bear_setup_tf;
   bool              m_choch_bull;
   bool              m_choch_bear;

   ENUM_TIMEFRAMES   m_tf_macro;
   ENUM_TIMEFRAMES   m_tf_trend;
   ENUM_TIMEFRAMES   m_tf_setup;
   ENUM_TIMEFRAMES   m_tf_entry;

   SSwingPoint       m_last_sh_h4;
   SSwingPoint       m_last_sl_h4;
   SSwingPoint       m_prev_sh_h4;
   SSwingPoint       m_prev_sl_h4;

   double            m_atr_setup;

   bool FindLastSwingsSeries(const double &high[], const double &low[], const datetime &time[],
                             const int left, const int right, const int search_start, const int search_end,
                             SSwingPoint &out_sh, SSwingPoint &out_sl)
     {
      out_sh.time = 0;
      out_sl.time = 0;
      out_sh.price = 0;
      out_sl.price = 0;
      bool fh = false, fl = false;
      int n = ArraySize(high);
      for(int sh = search_start; sh <= search_end; sh++)
        {
         if(!fh && CBarHelpers::IsSwingHighSeries(high, sh, left, right))
           {
            out_sh.time = time[sh];
            out_sh.price = high[sh];
            out_sh.bar_index = sh;
            fh = true;
           }
         if(!fl && CBarHelpers::IsSwingLowSeries(low, sh, left, right))
           {
            out_sl.time = time[sh];
            out_sl.price = low[sh];
            out_sl.bar_index = sh;
            fl = true;
           }
         if(fh && fl)
            break;
        }
      return fh || fl;
     }

   bool UpdateSwingsForTf(const ENUM_TIMEFRAMES tf, SSwingPoint &sh, SSwingPoint &sl,
                          SSwingPoint &prev_sh, SSwingPoint &prev_sl)
     {
      double o[], h[], l[], c[];
      long v[];
      datetime t[];
      if(!CBarHelpers::CopyRatesSeries(m_symbol, tf, 400, o, h, l, c, v, t))
         return false;
      int L = m_cfg.swing_left;
      int R = m_cfg.swing_right;
      int start = R + L + 5;
      int end = MathMin(ArraySize(h) - L - 2, 120);
      SSwingPoint tsh, tsl, tsh2, tsl2;
      tsh.time = tsl.time = 0;
      // First most recent swing pair
      FindLastSwingsSeries(h, l, t, L, R, start, end, tsh, tsl);
      // Scan for second occurrence (older region)
      int sub_end = (tsh.bar_index > 0 ? tsh.bar_index : end) + L + R + 3;
      tsh2.time = tsl2.time = 0;
      if(tsh.bar_index > 0)
         FindLastSwingsSeries(h, l, t, L, R, tsh.bar_index + L + R + 1, MathMin(sub_end, ArraySize(h) - L - 2), tsh2, tsl2);
      sh = tsh;
      sl = tsl;
      prev_sh = tsh2;
      prev_sl = tsl2;
      return true;
     }

   int ComputeBiasFromSwings(const SSwingPoint &sh, const SSwingPoint &sl,
                             const SSwingPoint &prev_sh, const SSwingPoint &prev_sl)
     {
      if(sh.time == 0 || sl.time == 0 || prev_sh.time == 0 || prev_sl.time == 0)
         return 0;
      bool hh = sh.price > prev_sh.price;
      bool hl = sl.price > prev_sl.price;
      bool lh = sh.price < prev_sh.price;
      bool ll = sl.price < prev_sl.price;
      if(hh && hl)
         return 1;
      if(lh && ll)
         return -1;
      return 0;
     }

   double AtrTf(const ENUM_TIMEFRAMES tf, const int period)
     {
      int h = iATR(m_symbol, tf, period);
      if(h == INVALID_HANDLE)
         return 0;
      double buf[];
      ArraySetAsSeries(buf, true);
      if(CopyBuffer(h, 0, 1, 2, buf) < 1)
        {
         IndicatorRelease(h);
         return 0;
        }
      double v = buf[0];
      IndicatorRelease(h);
      return v;
     }

public:
                     CMarketStructureEngine(void):
                        m_bias_h4(0), m_bias_h1(0),
                        m_bos_bull_setup_tf(false), m_bos_bear_setup_tf(false),
                        m_choch_bull(false), m_choch_bear(false),
                        m_tf_macro(PERIOD_H4), m_tf_trend(PERIOD_H1),
                        m_tf_setup(PERIOD_M15), m_tf_entry(PERIOD_M5),
                        m_atr_setup(0)
     {
      ZeroMemory(m_last_sh_h4);
      ZeroMemory(m_last_sl_h4);
      ZeroMemory(m_prev_sh_h4);
      ZeroMemory(m_prev_sl_h4);
     }

   void Init(const string sym, const SQuantConfig &cfg)
     {
      m_symbol = sym;
      m_cfg = cfg;
     }

   void SetTimeframes(const ENUM_TIMEFRAMES macro_tf, const ENUM_TIMEFRAMES trend_tf,
                      const ENUM_TIMEFRAMES setup_tf, const ENUM_TIMEFRAMES entry_tf)
     {
      m_tf_macro = macro_tf;
      m_tf_trend = trend_tf;
      m_tf_setup = setup_tf;
      m_tf_entry = entry_tf;
     }

   bool Update(void)
     {
      SSwingPoint sh4, sl4, psh4, psl4;
      if(!UpdateSwingsForTf(m_tf_macro, sh4, sl4, psh4, psl4))
         return false;
      m_last_sh_h4 = sh4;
      m_last_sl_h4 = sl4;
      m_prev_sh_h4 = psh4;
      m_prev_sl_h4 = psl4;
      m_bias_h4 = ComputeBiasFromSwings(sh4, sl4, psh4, psl4);

      SSwingPoint sh1, sl1, psh1, psl1;
      if(UpdateSwingsForTf(m_tf_trend, sh1, sl1, psh1, psl1))
         m_bias_h1 = ComputeBiasFromSwings(sh1, sl1, psh1, psl1);
      else
         m_bias_h1 = 0;

      m_atr_setup = AtrTf(m_tf_setup, m_cfg.atr_period);
      if(m_atr_setup <= 0)
         return false;

      // BOS on setup TF: break of last swing with displacement on bar 1 (closed)
      double o[], h[], l[], c[];
      long v[];
      datetime t[];
      if(!CBarHelpers::CopyRatesSeries(m_symbol, m_tf_setup, 300, o, h, l, c, v, t))
         return false;
      int L = m_cfg.swing_left;
      int R = m_cfg.swing_right;
      int start = R + L + 5;
      int end = MathMin(ArraySize(h) - 2, 80);
      SSwingPoint swing_high, swing_low;
      FindLastSwingsSeries(h, l, t, L, R, start, end, swing_high, swing_low);

      m_bos_bull_setup_tf = false;
      m_bos_bear_setup_tf = false;
      m_choch_bull = false;
      m_choch_bear = false;

      if(swing_high.time == 0 || swing_low.time == 0)
         return true;

      double body1 = CMathUtils::BodySize(o[1], c[1]);
      double min_disp = m_atr_setup * m_cfg.displacement_atr_mult;

      // Bullish BOS: close[1] > swing_high and strong bull body
      if(c[1] > swing_high.price && CMathUtils::IsBullishBar(o[1], c[1]) && body1 >= min_disp)
         m_bos_bull_setup_tf = true;

      // Bearish BOS: close[1] < swing_low and strong bear body
      if(c[1] < swing_low.price && CMathUtils::IsBearishBar(o[1], c[1]) && body1 >= min_disp)
         m_bos_bear_setup_tf = true;

      // CHOCH proxy: structure flip vs H1 bias
      if(m_bias_h1 == 1 && m_bos_bear_setup_tf)
         m_choch_bear = true;
      if(m_bias_h1 == -1 && m_bos_bull_setup_tf)
         m_choch_bull = true;

      return true;
     }

   int BiasH4(void) const { return m_bias_h4; }
   int BiasH1(void) const { return m_bias_h1; }
   bool BosBullSetup(void) const { return m_bos_bull_setup_tf; }
   bool BosBearSetup(void) const { return m_bos_bear_setup_tf; }
   bool ChochBull(void) const { return m_choch_bull; }
   bool ChochBear(void) const { return m_choch_bear; }
   double AtrSetup(void) const { return m_atr_setup; }
   ENUM_TIMEFRAMES TfSetup(void) const { return m_tf_setup; }
   ENUM_TIMEFRAMES TfEntry(void) const { return m_tf_entry; }
   string Symbol(void) const { return m_symbol; }
  };

#endif // __AQ_MARKETSTRUCTURE_MQH__
