
# -----------------------------------


require 'rubygems'
require 'socket'
require "base64"
require 'digest/sha1'

$MAXSIZE = 65536

$config = {
	"-port" 	=> 10000,
	"-debug"	=> 0
}



#--------
def accept_new_connection( sock )
	
	newsock = sock.accept
	@descriptors << newsock
	@clients << newsock;
	
	puts "#{newsock.to_s} connected."
	
end

#-----------
def settle_incoming_msg( sock )

	puts "<settle_incoming_msg>" if $config["-debug"].to_i > 3
	
	begin
		if sock.eof? 
			puts "#{sock.to_s} closed."
			sock.close
			@descriptors.delete(sock)
			@clients.delete( sock )
			@wsclients.delete( sock )

		else

			raw_msg = sock.read_nonblock($MAXSIZE)
			process_msg( raw_msg  , sock)

		end
	
	rescue Exception => e  
		puts "ERROR: #{ e.to_s }\n#{e.backtrace() }"
	end

	puts "<settle_incoming_msg> Done." if $config["-debug"].to_i > 3
	
end







#----------------
def process_msg( raw_msg , sock ) 
	
	puts "<process_msg>: " if $config["-debug"].to_i > 2
	puts "raw_msg: #{raw_msg} " if $config["-debug"].to_i > 4
	
	
	if raw_msg.length > 0

		# Websocket handshake
		if raw_msg[0...10][/^GET/]

			msg_arr = raw_msg.gsub("\r\n","\n").split("\n")
			
			ws_key = nil
			msg_arr.each { |line|

				k = line.split(" ")
				if ( k[0][/Sec-WebSocket-Key:/] ) 
					ws_key = k[1]
				end
			}
			if ws_key

				puts "WS open request, responding back."
				
				# Websocket open handshake
				guid 	= "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
				websocket_accept_key = Base64.encode64( Digest::SHA1.digest( "#{ws_key}#{guid}" ) )
				sock.write "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: #{websocket_accept_key}\r\n"
			
				@wsclients << sock
			end

		else
			
			# Websocket
			if @wsclients.index( sock ) != nil

				msg = ''
				extract_msg( raw_msg , msg )
				ws_onmessage( sock , msg )


			# ordinary TCPIP socket
			else
				raw_onmessage( sock , raw_msg )
			end		
						
		end

		
	end
	
	puts "<process_msg>: Done\n" if $config["-debug"].to_i > 2
end



#--------------------------
def ws_onmessage( ws , msg )

	puts "<ws_onmessage>: #{ws}" if $config["-debug"].to_i > 2
	puts "Data :#{msg}" if $config["-debug"].to_i > 3

	if msg[/topic_sample/] 
		

	end

	puts "<ws_onmessage>: Done.\n" if $config["-debug"].to_i > 2
	
	
end


#-------------------
def raw_onmessage( sock , data ) 

	puts "<raw_onmessage>: #{sock}" if $config["-debug"].to_i > 2
	puts "Data :#{data}" if $config["-debug"].to_i > 3

	# Don't dispatch immediately
	@buffer = '' if @buffer == nil
	@buffer.concat(data.to_s)

	if data && data.index("\n")
		
		@buffer.gsub("\r","").gsub("\n","")
		raw_dispatch_msg( sock, @buffer )
		@buffer = ""

		
	end



	puts "<raw_onmessage> Done.\n" if $config["-debug"].to_i > 2
	
end

#-------------
$symbol_queue = {}


def raw_dispatch_msg( sock , msg ) 

	msgarr = msg.split(" ")

	p msgarr

	if msgarr[0][/^QUOTES/]

		symbol = msgarr[1]
		quotes = msgarr[2...msgarr.length]
		
		$symbol_queue[symbol] = [] if $symbol_queue[symbol] == nil
		$symbol_queue[symbol] << quotes
		$symbol_queue[symbol].shift() if $symbol_queue[symbol].length > 10
	

	elsif  msgarr[0][/^QUERYQUOTES/]

		symbol = msgarr[1]
		
		sock.puts( $symbol_queue[ symbol ].inspect() )



	end

end



#-------------
def extract_msg( raw_msg , msg ) 

		fin    		=   ( raw_msg[0] >> 7 ) & 0x01
		rsv1   		=   ( raw_msg[0] >> 6 ) & 0x01
		rsv2   		=   ( raw_msg[0] >> 5 ) & 0x01
		rsv3   		=   ( raw_msg[0] >> 4 ) & 0x01			 
		opcode 		=     raw_msg[0]  & 0x0f
		maskflag   	=   ( raw_msg[1] >> 7 ) & 0x01
		len    		=     raw_msg[1] & 0x7f
		offset 		=   2
		
		if len == 127 
		
			offset += 8
			len =  (raw_msg[2].to_i << 56) + ( raw_msg[3].to_i << 48) \
				 + (raw_msg[4].to_i << 40) + ( raw_msg[5].to_i << 32) \
				 + (raw_msg[6].to_i << 24) + ( raw_msg[7].to_i << 16) \
				 + (raw_msg[8].to_i << 8)  + ( raw_msg[9].to_i )	

		elsif len >= 126
			
			offset += 2
			len = ( raw_msg[2].to_i << 8 ) + raw_msg[3].to_i
			
		end

		mask = []
		(0...4).each { |i|
			mask[i] = raw_msg[offset + i] 
		}
		offset += 4

		if opcode == 0x01 

			(0...len).each { |i|

				msg << ( raw_msg[offset + i] ^ mask[i % 4] ).chr

			}
		end
end



#----------------------------------------
def send_ws_frame( ws , application_data)

	frame = ''

	frame << 0x81

	length = application_data.size
	
	if length <= 125
	  byte2 = length
	  frame << byte2
	
	elsif length < 65536 # write 2 byte length
	  frame << 126
	  frame << [length].pack('n')
	
	else # write 8 byte length
	  frame << 127
	  frame << [length >> 32, length & 0xFFFFFFFF].pack("NN")
	end

	frame << application_data

	ws.write(frame)

end


#------------
def main( argv )

	$config = $config.merge( Hash[*argv] )
	
	port =  $config["-port"] 
	

	@descriptors = Array::new
	@wsclients = Array::new

	
	@serverSocket = TCPServer.new("", port)
	@serverSocket.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )
	@descriptors << @serverSocket
	@clients = []
	printf "Server started on port %d\n", port
	
	while (1)
		
		res = select( @descriptors, nil ,nil ,nil )
		if res != nil
			res[0].each do
				|sock|
				if sock == @serverSocket 
					accept_new_connection( sock )
				else
					settle_incoming_msg( sock )
				end
			end
		end
	end
end

main ARGV



