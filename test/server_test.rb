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

  def test_hello_once
    setupp(9291)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do

      ser.close = true
      assert_equal 'Hello World(0)', del_html(conn.get('/hello').body)

    end
    threads.each {|thread| thread.join}
  end

  def test_hello_twice
    setupp(9292)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do

      conn.get('/hello')
      sleep(0.01)
      ser.close = true
      assert_equal 'Hello World(1)', del_html(conn.get('/hello').body)
    end
    threads.each {|thread| thread.join}
  end

  def test_date_time
    setupp(9293)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do

      ser.close = true
      assert_equal "#{Time.now.strftime('%I:%M%p on %A, %B %d, %Y')}", del_html(conn.get('/datetime').body)
    end
    threads.each {|thread| thread.join}
  end

  def test_start_game
    setupp(9294)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do

      ser.close = true
      assert_equal "Good luck!", del_html(conn.post('/start_game').body)
    end
    threads.each {|thread| thread.join}
  end

  def test_game_guess
    setupp(9295)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do

      conn.post('/start_game')
      conn.post '/game', {:guess => 50}
      sleep(0.01)
      ser.close = true
      assert  del_html(conn.get('/game').body).include? "You have made 1 guesses.\n\nYour guess of 50 is"
    end
    threads.each {|thread| thread.join}
  end
end
