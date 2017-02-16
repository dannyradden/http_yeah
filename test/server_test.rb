require 'minitest/autorun'
require 'minitest/pride'
require './lib/server'
require 'faraday'

class ServerTest < Minitest::Test
  attr_accessor :ser, :conn
  def setupp(port)
    @ser = Server.new(port)
    @conn = Faraday.new(:url => "http://127.0.0.1:#{port}")
  end

  def del_html(string)
    string.slice!('<html><head></head><body><pre>')
    string.slice!('</pre></body></html>')
    string
  end


  def test_server_exists
    setupp(9290)

    assert_instance_of Server, ser
    assert_equal 0, ser.requests
  end


  def test_hello
    setupp(9291)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do
      hello_once = conn.get('/hello').body
      sleep(0.01)
      ser.close_for_test = true
      hello_twice = conn.get('/hello').body

      assert_equal 'Hello World(1)', del_html(hello_once)
      assert_equal 'Hello World(2)', del_html(hello_twice)
    end
    threads.each {|thread| thread.join}
  end

  def test_date_time
    setupp(9292)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do

      ser.close_for_test = true
      assert_equal "#{Time.now.strftime('%I:%M%p on %A, %B %d, %Y')}", del_html(conn.get('/datetime').body)
    end
    threads.each {|thread| thread.join}
  end

  def test_start_game
    setupp(9293)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do

      ser.close_for_test = true
      assert_equal "Good luck!", del_html(conn.post('/start_game').body)
    end
    threads.each {|thread| thread.join}
  end

  def test_game_guess
    setupp(9294)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do
      conn.post('/start_game')
      conn.post '/game', {:guess => 50}
      sleep(0.01)
      ser.close_for_test = true
      game_status = conn.get('/game').body

      assert  del_html(game_status).include? "You have made 1 guesses.\n\nYour guess of 50 is"
    end
    threads.each {|thread| thread.join}
  end

  def test_game_info_without_game_started
    setupp(9295)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do
      ser.close_for_test = true
      game_status = conn.get('/game').body
      puts game_status
      assert_equal 'Please start a new game.', del_html(game_status)
    end
    threads.each {|thread| thread.join}
  end

  def test_word_search
    setupp(9296)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do
      right_word = conn.get('/word_search?param=banana').body
      sleep(0.01)
      ser.close_for_test = true
      wrong_word = conn.get('/word_search?param=lanana').body

      assert_equal 'banana is a known word', del_html(right_word)
      assert_equal 'lanana is not a known word', del_html(wrong_word)

    end
    threads.each {|thread| thread.join}
  end

  def test_shutdown
    setupp(9297)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do
      conn.get('/hello')
      conn.get('/hello')
      sleep(0.01)

      assert_equal  "Total Requests: 3", del_html(conn.get('/shutdown').body)
      assert_equal  '/shutdown', ser.user_path
    end
    threads.each {|thread| thread.join}
  end

  def test_one_of_everthing
    setupp(9298)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do

      hello        = conn.get('/hello').body
      right_word   = conn.get('/word_search?param=whale').body
      date_time    = conn.get('/datetime').body
      game_started = conn.post('/start_game').body
                     conn.post '/game', {:guess => 40}
      game_status  = conn.get('/game').body
      sleep(0.01)
      the_shutdown = conn.get('/shutdown').body

      assert_equal  'Hello World(1)', del_html(hello)
      assert_equal  'whale is a known word', del_html(right_word)
      assert_equal  "#{Time.now.strftime('%I:%M%p on %A, %B %d, %Y')}", del_html(date_time)
      assert_equal  "Good luck!", del_html(game_started)
      assert        del_html(game_status).include? "You have made 1 guesses.\n\nYour guess of 40 is"
      assert_equal  "Total Requests: 7", del_html(the_shutdown)
    end
    threads.each {|thread| thread.join}
  end

  def test_error_codes
    setupp(9299)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do
      start_game_once = conn.post('/start_game').status
      start_game_twice = conn.post('/start_game').status
      no_address = conn.post('/gwrerg').status
      error_force = conn.post('/force_error').status
      sleep(0.01)
      ser.close_for_test = true
      hello_once = conn.post('/hello').status

      assert_equal 301, start_game_once
      assert_equal 403, start_game_twice
      assert_equal 404, no_address
      assert_equal 200, hello_once
      assert_equal 500, error_force
    end
    threads.each {|thread| thread.join}
  end

  
end
