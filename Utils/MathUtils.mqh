//+------------------------------------------------------------------+
//| MathUtils.mqh                                                    |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_MATHUTILS_MQH__
#define __AQ_MATHUTILS_MQH__

class CMathUtils
  {
public:
   static double Clamp(const double v, const double lo, const double hi)
     {
      if(v < lo)
         return lo;
      if(v > hi)
         return hi;
      return v;
     }

   static double PointsToPrice(const string sym, const double points)
     {
      double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double mult = (SymbolInfoInteger(sym, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(sym, SYMBOL_DIGITS) == 5) ? 10.0 : 1.0;
      return NormalizeDouble(points * pt * mult, digits);
     }

   static double PriceDistancePoints(const string sym, const double a, const double b)
     {
      double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
      double mult = (SymbolInfoInteger(sym, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(sym, SYMBOL_DIGITS) == 5) ? 10.0 : 1.0;
      return MathAbs(a - b) / (pt * mult);
     }

   static double BodySize(const double open, const double close)
     {
      return MathAbs(close - open);
     }

   static bool IsBullishBar(const double o, const double c)
     {
      return c > o;
     }

   static bool IsBearishBar(const double o, const double c)
     {
      return c < o;
     }
  };

#endif // __AQ_MATHUTILS_MQH__
