module Rack::API; end
class Rack::API::YoutubeHack
  # I think a Youtube ID is a URL-safe base64 encoding.
  PATTERN = %r!(<iframe src=\\\"http://www.youtube.com/embed/)([a-zA-Z0-9\-\_]*)(\\\" width=\\\"\d+\\\" height=\\\"\d+\\\"></iframe>)!
  
  def initialize(app)
    @app = app       
  end                

  def call(env)
    status, headers, response = @app.call(env)
    response = rewrite response
        
    # Change the content length.
    headers['Content-Length'] = response.first.bytesize.to_s
        
    [status, headers, response]
  end

  # Search for any Youtube embed, in our _exact_ format, and add a question
  # mark.
  def rewrite(response)
    body = ''
    response.each{ |s| body << s.to_s }
    [body.gsub(PATTERN, '\\1\\2?\\3')]
  end
end
