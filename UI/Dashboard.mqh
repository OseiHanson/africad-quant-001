//+------------------------------------------------------------------+
//| Dashboard.mqh — on-chart status panel                            |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_DASH_MQH__
#define __AQ_DASH_MQH__

#include "../Config/Settings.mqh"

class CDashboard
  {
private:
   string m_prefix;
   int    m_x, m_y;

   void SetLbl(const int idx, const string text, const color clr)
     {
      string name = m_prefix + IntegerToString(idx);
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_y + idx * 16);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
      ObjectSetString(0, name, OBJPROP_TEXT, text);
     }

public:
   CDashboard(void): m_prefix("AQ_DASH_"), m_x(8), m_y(20) {}

   void Clear(void)
     {
      for(int i = 0; i < 20; i++)
        {
         string name = m_prefix + IntegerToString(i);
         ObjectDelete(0, name);
        }
     }

   void Update(const bool enabled,
               const string session,
               const int bias_h4,
               const double conf,
               const double spread_pts,
               const double risk_pct,
               const string setup)
     {
      if(!enabled)
        {
         Clear();
         return;
        }
      string b = (bias_h4 > 0 ? "BULL" : (bias_h4 < 0 ? "BEAR" : "NEU"));
      SetLbl(0, "AFRICAD QUANT 001", clrWhite);
      SetLbl(1, "Session: " + session, clrSilver);
      SetLbl(2, "H4 Bias: " + b, clrAqua);
      SetLbl(3, "Confidence: " + DoubleToString(conf, 1) + "%", clrYellow);
      SetLbl(4, "Spread: " + DoubleToString(spread_pts, 1) + " pts", clrSilver);
      SetLbl(5, "Risk/trade: " + DoubleToString(risk_pct, 2) + "%", clrSilver);
      SetLbl(6, "Setup: " + setup, clrWhite);
     }
  };

#endif // __AQ_DASH_MQH__
