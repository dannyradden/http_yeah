require 'socket'
require 'URI'

tcp_server = TCPServer.new("127.0.0.1",9292)

counter = 0

loop do
  client = tcp_server.accept

  request_lines = []
  while line = client.gets and !line.chomp.empty?
    request_lines << line.chomp
  end

  puts request_lines.inspect

  def requested_file(request_lines)
    request_uri  = request_lines[0].split(" ")[1]
    path         = URI.unescape(URI(request_uri).path)
  end
#require "pry"; binding.pry
  verb = request_lines[0].split(" ")[0]
  path = requested_file(request_lines)
  protocol = request_lines[0].split(" ")[2]
  host_port = request_lines[1].split(" ")[1]
  host = host_port.split(":")[0]
  port = host_port.split(":")[1]
  origin = client.peeraddr[-2]
  accept = request_lines[-3]

  response = "<pre>" + "Hello World(#{counter})" + "</pre>"
  diagnostics =   "<pre>
      Verb: #{verb}
      Path: #{path}
      Protocol: #{protocol}
      Host: #{host}
      Port: #{port}
      Origin: #{origin}
      #{accept}
      </pre>"
  counter += 1
  output = "<html><head><link rel='shortcut icon' href='about:blank'></head><body>#{response}#{diagnostics}</body></html>"

  client.puts output

  client.close

end
