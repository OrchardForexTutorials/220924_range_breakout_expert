/*

   Expert.mq4
   Copyright 2022, Orchard Forex
   https://orchardforex.com

*/

#property copyright "Copyright 2021, Orchard Forex"
#property link "https://orchardforex.com"
#property version "1.00"
#property strict

input double InpOrderSize    = 0.00;      //	Order size
input int    InpMagic        = 222222;    // Magic
input string InpTradeComment = "Comment"; // Comment

int          OnInit() {

   if ( !ValidateInput() ) {
      return ( INIT_FAILED );
   }

   return ( INIT_SUCCEEDED );
}

void OnDeinit( const int reason ) {}

void OnTick() {

   if ( !NewBar() ) return;
}

bool ValidateInput() { return ( true ); }

bool NewBar() {
   static datetime previousTime = 0;
   datetime        currentTime  = iTime( Symbol(), Period(), 0 );
   if ( previousTime == currentTime ) return ( false );
   previousTime = currentTime;
   return ( true );
}
