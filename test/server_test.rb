require 'minitest/autorun'
require 'minitest/pride'
require './lib/server'
require 'faraday'

class ServerTest < Minitest::Test
  attr_accessor :ser, :conn
  def setupp(port)
    $close = false
    @ser = Server.new(port)
    @conn = Faraday.new(:url => "http://127.0.0.1:#{port}")
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
            $close = true
      assert_equal '<html><head></head><body><pre>Hello World(0)</pre></body></html>', conn.get('/hello').body

    end
    threads.each {|thread| thread.join}
  end

  def test_hello_twice
    setupp(9292)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do
      conn.get('/hello')
      $close = true
      assert_equal '<html><head></head><body><pre>Hello World(1)</pre></body></html>', conn.get('/hello').body
    end
    threads.each {|thread| thread.join}
  end

  def test_date_time
    setupp(9293)

    threads = []
    threads << Thread.new {ser.run_server}
    threads << Thread.new do
      $close = true
      assert_equal "<html><head></head><body><pre>#{Time.now.strftime('%I:%M%p on %A, %B %d, %Y')}</pre></body></html>", conn.get('/datetime').body
    end
    threads.each {|thread| thread.join}
  end


end
