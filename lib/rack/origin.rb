module Rack::API; end
class Rack::API::Origin
  ALLOWED = /^http:\/\/((localhost)(:\d+)?)|(vodpod\.com)$/

  # Sets the cross-site origin header.
  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)
    if origin = env['HTTP_ORIGIN'] and ALLOWED =~ origin
      response[1]["Access-Control-Allow-Origin"] = origin
      response[1]["Access-Control-Allow-Credentials"] = "true"
    end
    response
  end
end
