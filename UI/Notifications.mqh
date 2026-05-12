//+------------------------------------------------------------------+
//| Notifications.mqh                                                 |
//+------------------------------------------------------------------+
#property strict
#ifndef __AQ_NOTIFY_MQH__
#define __AQ_NOTIFY_MQH__

class CNotify
  {
public:
   static void Push(const string title, const string body)
     {
      SendNotification(title + ": " + body);
     }
  };

#endif // __AQ_NOTIFY_MQH__
