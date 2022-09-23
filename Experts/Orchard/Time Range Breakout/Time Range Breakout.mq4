/*

   Time Range Breakout.mq4
   Copyright 2022, Orchard Forex
   https://www.orchardforex.com

*/

#property copyright "Copyright 2022, Orchard Forex"
#property link "https://www.orchardforex.com"
#property version "1.00"
#property strict

#include "Time Range Breakout.mqh"

;
//
//	Initialisation
//
int OnInit() {

   if ( !CheckInput() ) return ( INIT_PARAMETERS_INCORRECT );

   InsideRange = IsInsideTime( TimeCurrent(), RangeStartMinutes, RangeEndMinutes );
   InsideClose = IsInsideTime( TimeCurrent(), RangeEndMinutes, CloseMinutes );

   return ( INIT_SUCCEEDED );
}

void OnDeinit( const int reason ) {}

void OpenTrade( ENUM_ORDER_TYPE type, double price, double sl ) {

   double tp = price + ( price - sl );
   price     = NormalizeDouble( price, Digits );
   sl        = NormalizeDouble( sl, Digits );
   tp        = NormalizeDouble( tp, Digits );

   if ( !OrderSend( Symbol(), type, InpOrderSize, price, 0, sl, tp, InpTradeComment, InpMagic ) ) {
      Print( "Open failed for %s, %s, price=%f, sl=%f, tp=%f", Symbol(), EnumToString( type ), price, sl, tp );
   }
}

//
//	CloseAll
// Currently ignoring failed close
//
void CloseAll() {

   for ( int i = OrdersTotal() - 1; i >= 0; i-- ) {
      if ( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) continue;
      if ( OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagic ) continue;
      if ( OrderType() == ORDER_TYPE_BUY || OrderType() == ORDER_TYPE_SELL ) {
         if ( !OrderClose( OrderTicket(), OrderLots(), OrderClosePrice(), 0 ) ) {
            PrintFormat( "Failed to close order %i at %f", OrderTicket(), OrderClosePrice() );
         }
      }
      else { // still pending
         if ( !OrderDelete( OrderTicket() ) ) {
            PrintFormat( "Failed to delete pending order %i", OrderTicket() );
         }
      }
   }
}
