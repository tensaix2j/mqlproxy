
#property copyright "tensaix2j"
#property link      ""

#include <socket.mqh>

   extern string mqlproxyserver_host   = "168.198.1.161";
   extern int mqlproxyserver_port      = 20000;
   int sock = -1;
      
   //----------------
   int init() {
   
      sock = socket_client( mqlproxyserver_port , mqlproxyserver_host );
      return(0);
   }
   
   //----------------
   int start() {
      
      if ( sock < 0 ) {
          sock = socket_client( mqlproxyserver_port , mqlproxyserver_host );
      }
      int send_status = sock_send( sock , StringConcatenate( "QUOTES" ," " ,Symbol(), " ", TimeCurrent() ," ", Bid, " ", Ask ,"\n" ) );
      if ( send_status < 0 ) {
         sock = -1;
      }
       
      return(0);
   }





