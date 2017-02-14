require 'socket'
require 'URI'
class Server
  attr_accessor :counter, :requests, :tcp_server, :request_lines, :client

  def initialize
    @counter = 0
    @requests = 0
    @tcp_server = TCPServer.new(9292)
  end

  def run_server
    loop do
      accept_connection
      read_request
      make_diagnositcs
      diagnostics_html
      path_finder
      output_to_client
      close_client
      break if @path == '/shutdown'
    end
  end

  def accept_connection
    @client = tcp_server.accept
  end

  def read_request
    @request_lines = []
    while line = client.gets and !line.chomp.empty?
      request_lines << line.chomp
    end
    puts request_lines.inspect
  end

  def make_diagnositcs
    @verb = request_lines[0].split(" ")[0]
    @path = requested_file(request_lines)
    @protocol = request_lines[0].split(" ")[2]
    @host_port = request_lines[1].split(" ")[1]
    @host = @host_port.split(":")[0]
    @port = @host_port.split(":")[1]
    @origin = @client.peeraddr[-2]
    @accept = request_lines[-3]
  end

  def diagnostics_html
    "<pre>
    Verb: #{@verb}
    Path: #{@path}
    Protocol: #{@protocol}
    Host: #{@host}
    Port: #{@port}
    Origin: #{@origin}
    #{@accept}
    </pre>"
  end

  def path_finder
    if @path == "/"
      response = ""
    elsif @path == "/hello"
      response = "<pre>" + "Hello World(#{counter})" + "</pre>"
      @counter += 1
    elsif @path == "/datetime"
      response = "<pre>#{Time.now.strftime("%I:%M%p on %A, %B %d, %Y")}</pre>"
    elsif @path == "/shutdown"
      response = "<pre>Total Requests: #{requests}</pre>"
    elsif @path == "/word_search"
      response == param_test(param_word)
    end
  end

  def output_to_client
    output = "<html><head><link rel='shortcut icon' href='about:blank'></head><body>#{response}#{diagnostics_html}</body></html>"
    client.puts output
  end

  def close_client
    @requests += 1
    client.close
  end

  def requested_file(request_lines)
    request_uri  = request_lines[0].split(" ")[1]
    path         = URI.unescape(URI(request_uri).path)
  end

  def requested_param(request_lines)
    request_uri  = request_lines[0].split(" ")[1]
    query        = URI.unescape(URI(request_uri).query)
    query        = query.split("=")[1]
  end

  def dict_list
    File.read("/usr/share/dict/words").split("\n")
  end
end

ser = Server.new
ser.run_server
# param_word = requested_param(request_lines)
