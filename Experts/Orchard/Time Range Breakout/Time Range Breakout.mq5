/*

   Time Range Breakout.mq5
   Copyright 2022, Orchard Forex
   https://www.orchardforex.com

*/

#property copyright "Copyright 2022, Orchard Forex"
#property link "https://www.orchardforex.com"
#property version "1.00"
#property strict

#include "Time Range Breakout.mqh"

// Bring in the trade class to make trading easier
#include <Trade/Trade.mqh>
CTrade        Trade;
CPositionInfo Position;
COrderInfo    Order;

;
//
//	Initialisation
//
int OnInit() {

   if ( !CheckInput() ) return ( INIT_PARAMETERS_INCORRECT );

   Trade.SetExpertMagicNumber( InpMagic );

   InsideRange = IsInsideTime( TimeCurrent(), RangeStartMinutes, RangeEndMinutes );
   InsideClose = IsInsideTime( TimeCurrent(), RangeEndMinutes, CloseMinutes );

   return ( INIT_SUCCEEDED );
}

void OnDeinit( const int reason ) {}

void OpenTrade( ENUM_ORDER_TYPE type, double price, double sl ) {

   double tp = price + ( price - sl );

   price     = NormalizeDouble( price, Digits() );
   sl        = NormalizeDouble( sl, Digits() );
   tp        = NormalizeDouble( tp, Digits() );

   if ( !Trade.OrderOpen( Symbol(), type, InpOrderSize, 0, price, sl, tp, ORDER_TIME_GTC, 0, InpTradeComment ) ) {
      Print( "Open failed for %s, %s, price=%f, sl=%f, tp=%f", Symbol(), EnumToString( type ), price, sl, tp );
   }
}

//
//	CloseAll
// Currently ignoring failed close
//
void CloseAll() {

   for ( int i = PositionsTotal() - 1; i >= 0; i-- ) {
      ulong ticket = PositionGetTicket( i );
      if ( !PositionSelectByTicket( ticket ) ) continue;
      if ( Position.Symbol() != Symbol() || Position.Magic() != InpMagic ) continue;
      if ( !Trade.PositionClose( ticket ) ) {
         PrintFormat( "Failed to close position %i", ticket );
      }
   }

   for ( int i = OrdersTotal() - 1; i >= 0; i-- ) {
      ulong ticket = OrderGetTicket( i );
      if ( !OrderSelect( ticket ) ) continue;
      if ( Order.Symbol() != Symbol() || Order.Magic() != InpMagic ) continue;
      if ( !Trade.OrderDelete( ticket ) ) {
         PrintFormat( "Failed to delete order %i", ticket );
      }
   }
}

bool IsTradeAllowed() {

   return ( ( bool )MQLInfoInteger( MQL_TRADE_ALLOWED )              // Trading allowed in input dialog
            && ( bool )TerminalInfoInteger( TERMINAL_TRADE_ALLOWED ) // Trading allowed in terminal
            && ( bool )AccountInfoInteger( ACCOUNT_TRADE_ALLOWED )   // Is account able to trade, not locked out
            && ( bool )AccountInfoInteger( ACCOUNT_TRADE_EXPERT )    // Is account able to auto trade
   );
}

bool IsTradeAllowed( string symbol, datetime time ) {

   static string   lastSymbol   = "";
   static bool     isOpen       = false;
   static datetime sessionStart = 0;
   static datetime sessionEnd   = 0;

   if ( lastSymbol == symbol && sessionEnd > sessionStart ) {
      if ( ( isOpen && time >= sessionStart && time <= sessionEnd ) || ( !isOpen && time > sessionStart && time < sessionEnd ) ) return isOpen;
   }

   lastSymbol = symbol;

   MqlDateTime mtime;
   TimeToStruct( time, mtime );
   datetime seconds  = mtime.hour * 3600 + mtime.min * 60 + mtime.sec;

   mtime.hour        = 0;
   mtime.min         = 0;
   mtime.sec         = 0;
   datetime dayStart = StructToTime( mtime );
   datetime dayEnd   = dayStart + 86400;

   datetime fromTime;
   datetime toTime;

   sessionStart = dayStart;
   sessionEnd   = dayEnd;

   for ( int session = 0;; session++ ) {

      if ( !SymbolInfoSessionTrade( symbol, ( ENUM_DAY_OF_WEEK )mtime.day_of_week, session, fromTime, toTime ) ) {
         sessionEnd = dayEnd;
         isOpen     = false;
         return isOpen;
      }

      if ( seconds < fromTime ) { // not inside a session
         sessionEnd = dayStart + fromTime;
         isOpen     = false;
         return isOpen;
      }

      if ( seconds > toTime ) { // maybe a later session
         sessionStart = dayStart + toTime;
         continue;
      }

      // at this point must be inside a session
      sessionStart = dayStart + fromTime;
      sessionEnd   = dayStart + toTime;
      isOpen       = true;
      return isOpen;
   }

   return false;
}
