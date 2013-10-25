

/* 
	Created by tensaix2j
*/


/*
 No struct here in mql, use array of int instead!

typedef struct fd_set {
  u_int  fd_count;
  SOCKET fd_array[FD_SETSIZE];
} fd_set;
*/

#include <socket.mqh>

#define FD_SETSIZE 260

//-------
void FD_ZERO( int& fd_set[] ) {

  for ( int i = 0 ; i < fd_set[0]+1 ; i++ ) {
    fd_set[i] = 0;
  }
}

//-------
void FD_SET( int s, int& fd_set[] ) {

  fd_set[ fd_set[0]+1 ] = s;
  fd_set[0] += 1;
   
}

//-------
int FD_ISSET( int s, int& fd_set[] ) {

  for ( int i = 0 ; i < fd_set[0] ; i++ ) {

    if ( fd_set[i+1] == s ) {
      return (1); 
    }
  }
  return (0);
}

//----------
void array_pushback( int &arr[], int val ) {

  arr[ arr[0]+1 ] = val;
  arr[0] += 1;
}


//-------------
void run_select_loop( int sock_server , int& ctrl_flags[] ) {

	int ReadSet[FD_SETSIZE];
	int WriteSet[FD_SETSIZE];
	int client_list[64];
	int i;
   
   if ( sock_server != SOCKET_ERROR ) {
   
	  while ( ctrl_flags[0] == 1 ) {

		  FD_ZERO( ReadSet );
		  FD_ZERO( WriteSet );

		  FD_SET( sock_server, ReadSet);
		  for ( i = 0 ; i < client_list[0] ; i++ ) {
			  FD_SET( client_list[i+1] , ReadSet);
		  }

		  
		  int readsocks = select( 0, ReadSet, WriteSet, 0 , 0);
		  if (readsocks == SOCKET_ERROR ) {

			  Print("select() error: ", WSAGetLastError());
              closesocket(sock_server);
              WSACleanup();
              break;
		  }

		  if ( readsocks == 0) {
			  /* Nothing ready to read, just show that
			     we're alive */
		  } else {

			  // The sock server is in one of the ISSET in ReadSet
			  // This means it receives some connection request.

			  if ( FD_ISSET( sock_server , ReadSet )) {
				
				  // Accept the client's connection request 
				  int connection = sock_accept( sock_server );
	
				  if (connection == INVALID_SOCKET) {
					
					  Print("accept() error: ", WSAGetLastError());
					  closesocket(sock_server);
              		  WSACleanup();
            		  break;
				  }

				  // Add the socket client into the array of client list
				  Print("Client added", connection);
				  array_pushback( client_list, connection );
					
			  }	
			
			

			  // For each of the client, need to see if these sockets are in the ISSET of ReadSet on the last Select()
			  for ( i = 0 ; i < client_list[0] ; i++ ) {
				
				  if ( FD_ISSET( client_list[i+1] , ReadSet ) ) {
					
					  // If it is , read and print
					  string s = sock_receive( client_list[i+1] ) ;	
					  select_ondata_callback( client_list[i+1] , StringSubstr(s, 0,  StringLen(s) - 2 ) );

				  } 
			  }

		  }

	  }
	}
}




