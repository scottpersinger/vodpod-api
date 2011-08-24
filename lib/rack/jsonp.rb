module Rack::API; end
class Rack::API::JSONP
  INVALID_MSG = 'Error: invalid or missing JSONP callback name. Callback must consist only of letters, numbers, and underscores.'
  INVALID_RESPONSE = [
    200, {
      'Content-Type' => 'text/plain',
      'Content-Length' => INVALID_MSG.size.to_s
    },
    [INVALID_MSG]
  ]

  # Intercepts requests for .jsonp and wraps them in JSONP callbacks.
  def initialize(app, options = {})
    @app = app
    @callback_param = options[:callback_param] || 'callback'
  end

  def call(env)
    request = Rack::Request.new(env)

    if env['PATH_INFO'] =~ /\.jsonp$/
      # JSONP request

      callback = request.params.delete(@callback_param)
      unless callback and callback =~ /^[a-z0-9_]+$/i
        # Invalid callback!
        return INVALID_RESPONSE
      end
    
      # Rewrite .jsonp to .json 
      env['PATH_INFO'].sub!(/\.jsonp$/, '.json')

      # Rewrite the query string and delete the callback parameter from the
      # request.
      env['QUERY_STRING'] = env['QUERY_STRING'].split("&").delete_if{|param| param =~ /^(_|#{@callback_param})/}.join("&")

      # Strip cookies to prevent XSS issues
      req = Rack::Request.new(env)
      req.cookies.clear

      # Call app
      status, headers, response = @app.call(env)
      
      # Pad response
      response = pad(callback, response)
      
      # Reset content-type (we're a script now, not JSON)
      headers['Content-Type'] = 'application/javascript'
      # Length has changed too
      headers['Content-Length'] = response.first.bytesize.to_s

      # Respond...
      [200, headers, response]
    else
      # Fall straight through
      @app.call env 
    end
  end

  # Pads the response with the appropriate callback format according to the
  # JSON-P spec/requirements.
  #
  # The Rack response spec indicates that it should be enumerable. The method
  # of combining all of the data into a single string makes sense since JSON
  # is returned as a full string.
  #
  def pad(callback, response, body = "")
    response.each{ |s| body << s.to_s }
    ["#{callback}(#{body})"]
  end
end
