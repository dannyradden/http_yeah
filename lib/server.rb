require 'socket'
require 'uri'
require './lib/game'
require './lib/word_search'

class Server
  attr_accessor :close_for_test,
                :game_response

  attr_reader :port,
              :tcp_server,
              :hello_counter,
              :requests,
              :request_lines,
              :verb,
              :user_path,
              :client,
              :response,
              :paths,
              :protocol,
              :host,
              :accept,
              :content_type,
              :content_length,
              :header,
              :output,
              :new_game

  def initialize(port)
    @port = port
    @tcp_server = TCPServer.new(port)
    @hello_counter = 0
    @requests = 0
    @close_for_test = false
    @game_response = ''
  end

  def run_server
    loop do
      accept_connection
      read_request
      sort_request
      diagnostics_html
      counters_increaser
      make_header
      parse_path
      define_response
      make_output
      output_to_client
      close_client
      break if user_path == '/shutdown' || close_for_test == true

    end
  end

  def accept_connection(server = tcp_server)
    @client = server.accept
    puts 'client connected'
  end

  def read_request(server = client)
    @request_lines = []
    while (line = server.gets) && !line.chomp.empty?
      request_lines << line.chomp
    end
    puts request_lines.inspect
  end

  def sort_request(request = request_lines)
    @verb = request[0].split(' ')[0]
    @user_path = requested_file(request)
    @protocol = request[0].split(' ')[2]
    @host = request[1].split(' ')[1].split(':')[0]
    @accept = request_lines[-3]
    if verb == 'POST'
      @content_type = request.find {|string| string.include? "Content-Type"}.split(':')[1]
      @content_length = request.find {|string| string.include? "Content-Length"}.split(':')[1]
    end
  end

  def requested_file(lines = request_lines)
    request_uri = lines[0].split(' ')[1]
    URI.unescape(URI(request_uri).path)
  end

  def diagnostics_html
    "<pre>
    Verb: #{verb}
    Path: #{user_path}
    Protocol: #{protocol}
    Host: #{host}
    Port: #{port}
    Origin: #{host}
    #{accept}
    #{content_type}
    #{content_length}
    </pre>"
  end

  def counters_increaser(path = user_path)
    @requests += 1
    @hello_counter += 1 if path == '/hello'
  end

  def make_header
    @header = ["server: ruby",
               "content-type: text/html; charset=iso-8859-1"]
    parse_header_beginning
    header.join("\r\n")
  end

  def parse_header_beginning
    if verb == 'POST' && user_path == "/game"
      header.unshift("Location: http://127.0.0.1:#{port}/game")
      header.unshift("http/1.1 302 redirecting")
    elsif user_path == "/start_game" && new_game.nil?
      header.unshift("Location: http://127.0.0.1:#{port}/game")
      header.unshift("http/1.1 301 redirecting")
    elsif user_path == "/start_game" && !new_game.nil?
      header.unshift("http/1.1 403 forbidden")
    elsif user_path == "/force_error"
      header.unshift("http/1.1 500 Internal Server Error")
    else
      header.unshift("http/1.1 200 ok")
    end
  end

  def parse_path
    if user_path == "/start_game" && verb == 'POST'
      @new_game = Game.new if new_game == nil
    elsif user_path == "/game"
      parse_game_path
    elsif user_path == '/word_search'
      request_uri = request_lines[0].split(' ')[1]
      new_word = WordSearch.new(request_uri)
      @word_response = new_word.dict_search_result
    end
  end

  def parse_game_path
    if new_game != nil
      if verb == 'POST'
        grab_guess
        new_game.guess_checker(@guess) if !new_game.game_number.nil?
      elsif verb == 'GET'
        @game_response = new_game.game_info(@guess)
        new_game = nil if game_response == "CORRECT!!!"
      end
    else
      @game_response = "Please start a new game."
    end
  end

  def grab_guess
    if content_type.include? 'form-data'
      @guess = client.read(content_length.to_i).split("\r\n")[-2].to_i
    else
      @guess = client.read(content_length.to_i).split('=')[1].to_i
    end
  end

  def define_response(path = user_path, word_response = @word_response)
    @paths   =  {'/' => '',
                 '/hello' => "Hello World(#{hello_counter})",
                 '/datetime' => "#{Time.now.strftime('%I:%M%p on %A, %B %d, %Y')}",
                 '/shutdown' => "Total Requests: #{requests}",
                 '/word_search' => "#{word_response}",
                 '/start_game' => "Good luck!",
                 '/game' => "#{game_response}",
                 '/force_error' => 'SystemError'
                 }
    @response = paths[path]
  end

  def make_output(main = response, diag = diagnostics_html)
    @output = "<html><head></head><body><pre>#{main}#{diag if host != 'Faraday'}</pre></body></html>"
  end

  def output_to_client
    if paths.key?(user_path) == false
      header.shift
      header.unshift "http/1.1 404 Not Found"
    end
    header << "content-length: #{output.length}\r\n\r\n"
    client.puts header
    client.puts output
  end

  def close_client
    client.close
  end
end

# ser = Server.new(9292)
# ser.run_server
# conn = Faraday.new(:url => 'http://127.0.0.1:9292')
