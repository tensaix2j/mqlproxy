


bool SplitString(string stringValue, string separatorSymbol, string& results[], int expectedResultCount = 0)
{
//	 Alert("--SplitString--");
//	 Alert(stringValue);

   if (StringFind(stringValue, separatorSymbol) < 0)
   {// No separators found, the entire string is the result.
      ArrayResize(results, 1);
      results[0] = stringValue;
   }
   else
   {   
      int separatorPos = 0;
      int newSeparatorPos = 0;
      int size = 0;

      while(newSeparatorPos > -1)
      {
         size = size + 1;
         newSeparatorPos = StringFind(stringValue, separatorSymbol, separatorPos);
         
         ArrayResize(results, size);
         if (newSeparatorPos > -1)
         {
            if (newSeparatorPos - separatorPos > 0)
            {  // Evade filling empty positions, since 0 size is considered by the StringSubstr as entire string to the end.
               results[size-1] = StringSubstr(stringValue, separatorPos, newSeparatorPos - separatorPos);
            }
         }
         else
         {  // Reached final element.
            results[size-1] = StringSubstr(stringValue, separatorPos, 0);
         }
         
         
         //Alert(results[size-1]);
         separatorPos = newSeparatorPos + 1;
      }
   }   
   
   if (expectedResultCount == 0 || expectedResultCount == ArraySize(results))
   {  // Results OK.
      return (true);
   }
   else
   {  // Results are WRONG.
      Print("ERROR - size of parsed string not expected.", true);
      return (false);
   }
}




//---------
double lastOrderProfit() {
   
   if ( OrdersHistoryTotal() == 0 ) {
      return (0.0);
   } else {
      
      OrderSelect(OrdersHistoryTotal()-1, SELECT_BY_POS , MODE_HISTORY);
      return (OrderProfit() );
      
   }
}


//--------------------
double lastOrderSize() {
      
   if ( OrdersHistoryTotal() == 0 ) {
      return (0);
   } else {
      
      OrderSelect(OrdersHistoryTotal()-1, SELECT_BY_POS , MODE_HISTORY);
      return ( OrderLots() );
      
   }
}


//------------  
int lastOrderIsXHoursAgo( int x ) {

   // Get the most recent
   if ( OrdersTotal() == 0 ) {
      
      // No order at all, OK to make order
      return (1);
   
   } else { 
   
      // Has orders, check the last one if it is long ago enough
      
      OrderSelect( OrdersTotal() - 1 , SELECT_BY_POS );
      
      
      
      datetime currenttime = TimeCurrent();
      datetime opentime = OrderOpenTime();
      
      //Print( currenttime, " " , opentime, " " , currenttime - opentime );
      
      if ( currenttime - opentime > (3600 * x) ) {
         return (1);
      } else {
         return (0);
      }
     
   }
}  

void simplebuy( int SLPIP , int TPPIP , double _betsize ) {

     double slpoint;
     double tppoint;
     
     //Buy
     slpoint = Ask - Point * SLPIP * 10; 
     tppoint = Ask + Point * TPPIP * 10; 
     OrderSend( Symbol(), OP_BUY, _betsize , Ask,  10, slpoint, tppoint );
           
}

void simplesell( int SLPIP , int TPPIP , double _betsize ) {

   double slpoint;
   double tppoint;
   
   slpoint = Bid + Point * SLPIP * 10;
   tppoint = Bid - Point * TPPIP * 10;      
   OrderSend( Symbol(), OP_SELL, _betsize, Bid, 10 , slpoint , tppoint );              
           
}

void simplebuy_point(  double  slpoint, double tppoint , double _betsize ) {

   OrderSend( Symbol(), OP_BUY, _betsize , Ask,  10, slpoint, tppoint );
           
}

void simplesell_point(  double slpoint ,  double tppoint , double _betsize ) {

   OrderSend( Symbol(), OP_SELL, _betsize, Bid, 10 , slpoint , tppoint );              
           
}