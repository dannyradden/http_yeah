require 'socket'
require 'uri'


class Server
  attr_accessor :tcp_server,
                :hello_counter,
                :requests,
                :request_lines,
                :user_path,
                :client,
                :response,
                :paths


  def initialize(port)
    @tcp_server = TCPServer.new(port)
    @hello_counter = 0
    @requests = 0
    @guess_count = 0
  end

  def run_server
    loop do
      accept_connection
      read_request
      parse_request
      diagnostics_html
      check_game
      path_to_response
      counters_increaser
      output_to_client
      close_client
      break if @user_path == '/shutdown'|| $close == true
    end
  end

  def accept_connection(server = tcp_server)
    @client = server.accept
    @requests += 1
  end

  def read_request(server = client)
    @request_lines = []
    while (line = server.gets) && !line.chomp.empty?
      request_lines << line.chomp
    end
    puts request_lines.inspect
  end

  def parse_request(request = request_lines)
    @verb = request[0].split(' ')[0]
    @user_path = requested_file(request)
    @protocol = request[0].split(' ')[2]
    @host = request[1].split(' ')[1].split(':')[0]
    @port = request[1].split(' ')[1].split(':')[1]
    @accept = request_lines[-3]
    @content_length = request[3].split(':')[1] if @verb == 'POST'
  end

  def diagnostics_html
    "<pre>
    Verb: #{@verb}
    Path: #{@user_path}
    Protocol: #{@protocol}
    Host: #{@host}
    Port: #{@port}
    Origin: #{@host}
    #{@accept}
    #{@content_length}
    </pre>"
  end

  def check_game
    if @verb == 'POST' && @user_path == "/start_game"
      start_game
    elsif @verb == 'POST' && @user_path == "/game"
      make_guess
    elsif @verb == 'GET' && @user_path == "/game"
      game_info
    end
  end

  def path_to_response(path = user_path)
    @paths = {'/' => '',
                 '/hello' => "Hello World(#{@hello_counter})",
                 '/datetime' => "#{Time.now.strftime('%I:%M%p on %A, %B %d, %Y')}",
                 '/shutdown' => "Total Requests: #{@requests}",
                 '/word_search' => "#{dict_search_result}",
                 '/start_game' => "Good luck!",
                 '/game' => "#{@game_response}"
                 }
    @response = paths[path]
  end

  def counters_increaser(path = user_path)
    @hello_counter += 1 if path == '/hello'
  end


  def output_to_client(main = response, diag = diagnostics_html)
    @output = "<html><head></head><body><pre>#{main}#{diag if @host != 'Faraday'}</pre></body></html>"
    make_header
    client.puts @header
    client.puts @output

  end

  def make_header
    if @verb == 'POST' &&  @user_path == "/game"
      @header = ["http/1.1 302 redirecting",
            "Location: http://127.0.0.1:9292/game",
            "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
            "server: ruby",
            "content-type: text/html; charset=iso-8859-1",
            "content-length: #{@output.length}\r\n\r\n"].join("\r\n")
    else
      @header = ["http/1.1 200 ok",
              "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
              "server: ruby",
              "content-type: text/html; charset=iso-8859-1",
              "content-length: #{@output.length}\r\n\r\n"].join("\r\n")
    end
  end

  def close_client
    client.close
  end

  def requested_file(lines = @request_lines)
    request_uri = lines[0].split(' ')[1]
    URI.unescape(URI(request_uri).path)
  end

  def assign_param(lines = @request_lines)
    request_uri  = lines[0].split(' ')[1]
    query        = URI.unescape(URI(request_uri).query)
    @param = query.split('=')[1]
  end

  def dict_search_result
    assign_param if @user_path == "/word_search"
    if dict_list.include?(@param) == true
      "#{@param} is a known word"
    else
      "#{@param} is not a known word"
    end
  end

  def dict_list
    File.read('/usr/share/dict/words').split("\n")
  end

  def start_game
    @game_number = rand(101)
  end

  def make_guess
      @guess = client.read(@content_length.to_i).split("\r\n")[-2].to_i
      guess_checker if @game_number != nil
  end

  def guess_checker
    if @guess > @game_number
      @high_low = "too high."
    elsif @guess < @game_number
      @high_low = "too low."
    else
      @high_low = "CORRECT!!!"
    end
    @guess_count += 1
  end

  def game_info
    if @game_number != nil
      @game_response = "You have made #{@guess_count} guesses.\n\nYour guess of #{@guess} is #{@high_low}"
      @game_number = nil if @high_low == "CORRECT!!!"
    else
      @game_response = "Please start a new game."
    end
  end
end

# ser = Server.new(9292)
# ser.run_server
# conn = Faraday.new(:url => 'http://127.0.0.1:9292')
