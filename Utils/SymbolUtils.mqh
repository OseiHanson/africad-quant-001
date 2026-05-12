//+------------------------------------------------------------------+
//| SymbolUtils.mqh — XAU / broker suffix helpers                      |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_SYMBOLUTILS_MQH__
#define __AQ_SYMBOLUTILS_MQH__

class CSymbolUtils
  {
public:
   static string Upper(const string s)
     {
      string u = s;
      StringToUpper(u);
      return u;
     }

   static bool IsGoldUsd(const string sym)
     {
      string u = Upper(sym);
      if(StringFind(u, "XAU") < 0)
         return false;
      if(StringFind(u, "USD") < 0)
         return false;
      return true;
     }

   static bool EnsureSelected(const string sym)
     {
      if(!SymbolInfoInteger(sym, SYMBOL_SELECT))
         return SymbolSelect(sym, true);
      return true;
     }
  };

#endif // __AQ_SYMBOLUTILS_MQH__
