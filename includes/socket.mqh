#include <winsock.mqh>

string socket_protocol = "TCP";
 
#define BUFFER 1024
 
 
int err = 0;
int err(int code) {
  err = code;
  return(code);
}

//----------------------
int errno() {
  int ret = err;
  err = 0;
  return(ret);
}
 


//---------------------- 
int sock_close(int sock) {
  int ret = closesocket(sock);
  err(ret);
  return(ret);
}
 


//---------------------- 
string sock_receive(int msgsock) {

   int Buffer[BUFFER];
   int retval = recv(msgsock, Buffer, ArraySize(Buffer)<<2, 0);
   if (retval == SOCKET_ERROR) {
       Print("Server: recv() failed: error "+ WSAGetLastError());
       closesocket(msgsock);
       err(-1);
       return("");
   } else
       Print("Server: recv() is OK.");
   if (retval == 0) {
      Print("Server: Client closed connection.\n");
      closesocket(msgsock);
      err(-1);
      return("");
   }
   string item = struct2str(Buffer,ArraySize(Buffer)<<18); 
   item = StringSubstr(item,0,retval);
   return(item);
}




//----------------------          
int sock_send(int msgsock, string response) {
   
   int SendBuffer[];
   ArrayResize(SendBuffer,StringLen(response)); 
   str2struct(SendBuffer,ArraySize(SendBuffer)<<18,response); 
   int ret = send(msgsock,SendBuffer,ArraySize(SendBuffer),0);
   
   
   if (ret == SOCKET_ERROR) {
      Print("Server: send() failed: error "+WSAGetLastError());
      err(ret);
   } else {
      Print("Server: send() is OK."); 
      err(0); 
      
   }
   
   return(ret);
}




//----------------------
int socket_server( int port ) {

  int conn_socket = open_socket( port , "");
  return (conn_socket);
}



//----------------------
int socket_client( int port , string ip_address ){
   
   int wsaData[WSADATA];
   int retval = WSAStartup(0x202, wsaData);
   
   if (retval != 0) {
      Print("Server: WSAStartup() failed with error "+ retval);
      err(-1);
      return(-1);
   } else {
      Print("Server: WSAStartup() is OK.");
   }
   
   int addr[1];
   addr[0] = inet_addr(ip_address); 
   
   int server[sockaddr_in];
   
   int2struct(server,sin_addr,addr[0]);
   int2struct(server,sin_family,AF_INET);
   int2struct(server,sin_port,htons(port));
   
   int conn_socket = socket(AF_INET, SOCK_STREAM , 0); 
   if (conn_socket <0 ) {
      Print("Client: Error Opening socket: Error "+ WSAGetLastError());
      return(-1);
   } else {
      Print("Client: socket() is OK.");
   }
   
   retval = connect(conn_socket, server, ArraySize(server)<<2);
   if (retval == SOCKET_ERROR) {
      Print("Client: connect() failed: ", WSAGetLastError());
      return(-1);
   } else {
      Print("Client: connect() is OK.");
   }
   
   return (conn_socket);
}
 


//----------------------
int open_socket(int port, string ip_address) {

    int listen_socket; 
    int Buffer[BUFFER];
    int retval;
    int fromlen[1];
    int i, loopcount=0;
    int socket_type = SOCK_STREAM;
    int local[sockaddr_in], from[sockaddr_in];
    int wsaData[WSADATA];
   
    retval = WSAStartup(0x202, wsaData);
    if (retval != 0) {
        Print("Server: WSAStartup() failed with error "+ retval);
        err(-1);
        return(-1);
    } else {

      Print("Server: WSAStartup() is OK.");
    }


    int2struct(local, sin_family, AF_INET);

    Print( "local: ", local[0] , " ", local[1], " ", local[2], " ", local[3] );
    
    if ( ip_address == "" ) {
      int2struct(local,sin_addr,INADDR_ANY); 
    
    } else {  
      int2struct(local,sin_addr,inet_addr(ip_address));

    }

    Print( "Port: " , port );

    int2struct(local,sin_port,htons(port));
    Print( "local: ", local[0] , " ", local[1], " ", local[2], " ", local[3] );
    

    listen_socket = socket(AF_INET, socket_type,0);
 
    if (listen_socket == INVALID_SOCKET){
        
        Print("Server: socket() failed with error "+WSAGetLastError());
        err(-1);
        WSACleanup();
        return(-1);
    
    } else {

       Print("Server: socket() is OK.");
    }

    Print("sin_family: ", struct2int(local,sin_family) , " sin_port: " , struct2int(local,sin_port) , " sin_addr: " , struct2int(local,sin_addr)  );   
    
    Print( local[0]," ", local[1]," ", local[2], " ",local[3], " ",local[4] );

    if ( bind(listen_socket, local, ArraySize(local) << 2 ) == SOCKET_ERROR ) {
        
        Print("Server: bind() failed with error " + WSAGetLastError());
        WSACleanup();
        
        err(-1);
        return(-1);
    

    } else {
        Print("Server: bind() is OK");
    }


    if (socket_type != SOCK_DGRAM) {
        if (listen(listen_socket,5) == SOCKET_ERROR) {
            Print("Server: listen() failed with error "+ WSAGetLastError());
            WSACleanup();
           
            err(-1);
            return(-1);
        } else
            Print("Server: listen() is OK.");
    }
    Print("Server: listening and waiting connection port:"+port+", protocol:"+socket_protocol);
    return(listen_socket);
 }
 



//----------------------
int sock_accept(int listen_socket) {

    int msgsock;
    int fromlen[1];
    int  local[sockaddr_in], from[sockaddr_in];
    //after setup code   
    int closed = True;
    fromlen[0] =ArraySize(from)<<2;
    msgsock = accept(listen_socket, from, fromlen);
    if (msgsock == INVALID_SOCKET) {
        Print("Server: accept() error "+ WSAGetLastError());
        WSACleanup();
        err(-1);
        return(-1);
     } else {
        Print("Server: accept() is OK.\n");
     }
     Print("Server: accepted connection from "+inet_ntoa(struct2int(from,sin_addr))+", port "+ htons(struct2int(from,sin_port))) ;
   return(msgsock);
}
 


//----------------------
void sock_cleanup() {
  WSACleanup();
}