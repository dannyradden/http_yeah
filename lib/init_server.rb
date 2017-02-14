require './lib/server'

class InitServer
  def initialize(port)
    ser = Server.new(port)
    ser.run_server
  end
end

init = InitServer.new(9293)
