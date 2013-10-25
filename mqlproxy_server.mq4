//+------------------------------------------------------------------+
//|                                           tensaix2j_mtdaemon.mq4 |
//|                                        Copyright 2013, tensaix2j |
//|                                                                  |
//+------------------------------------------------------------------+


#property copyright "Copyright 2013, tensaix2j"
#property link      ""


#include <select.mqh>
#include <utils.mqh>

int sock_server;
int ctrl_flags[10];

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {

      sock_server = socket_server( 10000 );
      ctrl_flags[0] = 1;
	   run_select_loop( sock_server, ctrl_flags );	
      
      return(0);
}


//-------
void select_ondata_callback( int sock, string msg ) {

	Print("Sock : ", sock , " Msg : " , msg );
   
   string buffer[];
   SplitString(msg, " ", buffer);	
	
	if ( buffer[0] == "quit" ) {
	
		Print("Quitting! Bye");
		ctrl_flags[0] = 0;
		closesocket(sock_server);
		WSACleanup();
	
	}else if ( buffer[0] == "quote" ) {
	  
	  Print("Quote request");
	  
	  string symbol = buffer[1];
	  
	  int period = StrToInteger( buffer[2] );
	  int shift  = StrToInteger( buffer[3] );
     int length = StrToInteger( buffer[4] );
     
     Print( symbol, " " , period, " ", shift, " " , length );
     
     int i;
     
     string resp = "[";
     for ( i = 0 ; i < length ; i++ ) {
     
         int    timev  = iTime( symbol, period, shift + i );    
         double openv  = iOpen( symbol, period, shift + i );
         double highv  = iHigh( symbol, period, shift + i );
         double lowv   = iLow(  symbol, period, shift + i );
         double closev = iClose(symbol, period, shift + i );
         
         string arrstr = "[" + timev + "," + openv + "," + highv + "," + lowv + "," + closev + "]";
         resp = StringConcatenate(resp,arrstr);
         if ( i + 1 < length ) {
            resp = StringConcatenate(resp,",");         
         }
     }
     resp = StringConcatenate(resp, "]\r\n");
	  
	  
	  Print("Sending back response...");
	  int send_status = sock_send( sock, resp );
	  Print("Send Status ", send_status );
	
	}
	
   
}


//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
   Print("Deinit");
   closesocket(sock_server);
              
//----
   return(0);
  }




//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+


