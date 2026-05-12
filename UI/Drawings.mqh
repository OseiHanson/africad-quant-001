//+------------------------------------------------------------------+
//| Drawings.mqh — OB / FVG / session visuals                         |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_DRAW_MQH__
#define __AQ_DRAW_MQH__

#include "../Core/FVGEngine.mqh"
#include "../Core/OrderBlockEngine.mqh"

class CChartDrawings
  {
private:
   string m_prefix;

   void DeleteByPrefix(void)
     {
      int total = ObjectsTotal(0);
      for(int i = total - 1; i >= 0; i--)
        {
         string nm = ObjectName(0, i);
         if(StringFind(nm, m_prefix) == 0)
            ObjectDelete(0, nm);
        }
     }

public:
   CChartDrawings(void): m_prefix("AQ001_") {}

   void Refresh(const bool enabled, const SFvgZone &fvg, const SOrderBlock &ob)
     {
      if(!enabled)
        {
         DeleteByPrefix();
         return;
        }
      DeleteByPrefix();

      datetime t0 = iTime(_Symbol, PERIOD_CURRENT, 50);
      datetime t1 = TimeCurrent();

      if(fvg.valid)
        {
         string n = m_prefix + "FVG";
         if(ObjectCreate(0, n, OBJ_RECTANGLE, 0, t0, fvg.low, t1, fvg.high))
           {
            ObjectSetInteger(0, n, OBJPROP_COLOR, fvg.bullish ? clrDodgerBlue : clrCrimson);
            ObjectSetInteger(0, n, OBJPROP_BACK, true);
            ObjectSetInteger(0, n, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, n, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, n, OBJPROP_FILL, true);
           }
        }

      if(ob.valid)
        {
         string n2 = m_prefix + "OB";
         if(ObjectCreate(0, n2, OBJ_RECTANGLE, 0, t0, ob.ob_low, t1, ob.ob_high))
           {
            ObjectSetInteger(0, n2, OBJPROP_COLOR, ob.bullish_ob ? clrDarkGreen : clrMaroon);
            ObjectSetInteger(0, n2, OBJPROP_BACK, true);
            ObjectSetInteger(0, n2, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, n2, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, n2, OBJPROP_FILL, true);
           }
        }
     }
  };

#endif // __AQ_DRAW_MQH__
