/*

   Fractal EMA
   Expert

   Copyright 2022, Orchard Forex
   https://www.orchardforex.com

*/

/**=
 *
 * Disclaimer and Licence
 *
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * All trading involves risk. You should have received the risk warnings
 * and terms of use in the README.MD file distributed with this software.
 * See the README.MD file for more information and before using this software.
 *
 **/

/*
 * Strategy
 *
 * wait for a consolidation of bollinger indicated by
 *    narrowing to inside a specified range
 *    for a minimum specified period
 * Trade on candle close outside the specified range
 *	tp/sl 1:1 from entry at distance of squeeze range
 *
 */

#include "Framework.mqh"

class CExpert : public CExpertBase {

private:
protected:
// Definitions for compatibility
#ifdef __MQL4__
#define UPPER_LINE MODE_UPPER
#define LOWER_LINE MODE_LOWER
#endif

   CIndicatorMA      *mFastMA;
   CIndicatorMA      *mSlowMA;
   CIndicatorFractal *mFractal;
   double             mTPSLRatio;

   void               Loop();
   void               MakeOrder( ENUM_ORDER_TYPE type, double price, double sl );

public:
   CExpert( CIndicatorMA *fastMA, CIndicatorMA *slowMA,
            CIndicatorFractal *fractal,   //
            double             tpslRatio, //
            double volume, string tradeComment, int magic );
   ~CExpert();
};

//
CExpert::CExpert( CIndicatorMA *fastMA, CIndicatorMA *slowMA,
                  CIndicatorFractal *fractal,   //
                  double             tpslRatio, //
                  double volume, string tradeComment, int magic )
   : CExpertBase( volume, tradeComment, magic ) {

   mFastMA     = fastMA;
   mSlowMA     = slowMA;
   mFractal    = fractal;

   mTPSLRatio  = tpslRatio;

   mInitResult = INIT_SUCCEEDED;
}

//
CExpert::~CExpert() {

   delete mFastMA;
   delete mSlowMA;
   delete mFractal;
}

//
void CExpert::Loop() {

   if ( !mNewBar ) return; // Only trades on open of a new bar

   double fast      = mFastMA.GetData( 0, 1 );
   double slow      = mSlowMA.GetData( 0, 1 );
   double fractalHi = mFractal.GetData( UPPER_LINE, 3 ); // fractal will be 3 bars back
   double fractalLo = mFractal.GetData( LOWER_LINE, 3 );

   if ( fast > slow &&           // Up trend
        fractalHi != EMPTY_VALUE // a high fractal
   ) {
      MakeOrder( ORDER_TYPE_BUY_STOP, fractalHi, iLow( mSymbol, mTimeframe, 3 ) );
   }
   else if ( fast < slow &&           // Down trend
             fractalLo != EMPTY_VALUE // a low fractal
   ) {
      MakeOrder( ORDER_TYPE_SELL_STOP, fractalLo, iHigh( mSymbol, mTimeframe, 3 ) );
   }

   return;
}

void CExpert::MakeOrder( ENUM_ORDER_TYPE type, double price, double sl ) {

   Trade.OrderDelete( mSymbol,
                      type );                           //	Cancel any existing orders of the same type
   double tp = price + ( ( price - sl ) * mTPSLRatio ); //	Same for both buy and sell
   Trade.OrderOpen( mSymbol, type, mOrderSize, 0, price, sl, tp, ORDER_TIME_GTC, 0, mTradeComment );
}

//
