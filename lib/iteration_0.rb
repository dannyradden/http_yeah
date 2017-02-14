require 'socket'

tcp_server = TCPServer.new(9292)

counter = 0
loop do
  client = tcp_server.accept

  request_lines = []
  while line = client.gets and !line.chomp.empty?
    request_lines << line.chomp
  end

puts request_lines.inspect

  response = "<pre>" + "Hello World(#{counter})" + "</pre>"
  counter += 1
  output = "<html><head><link rel='shortcut icon' href='about:blank'></head><body>#{response}</body></html>"

  client.puts output


  client.gets
  client.close

end
