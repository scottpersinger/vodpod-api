module Rack::API; end
class Rack::API::Errors
  # Intercepts errors thrown by the application and converts them to XML or
  # JSON, depending on the URI.
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      # Call the next app
      @app.call(env)
    rescue Exception => e
      # In the event of emergency, inspect the request path and get the extension.
      env['PATH_INFO'] =~ /\.(\w+)$/

      # Determine HTTP status code
      code = case e
      when API::NotFoundError
        404
      when API::ForbiddenError
        403
      when API::RateLimitError
        403
      when API::StatusError
        550
      else
        500
      end

      # Log error
      case e
      when API::Error
        Ramaze::Log.info "API Error: #{e.message}"
      else
        req = Rack::Request.new(env)
        text = "Error processing #{env['PATH_INFO']}\nParams: #{req.params.inspect}\n\n#{e.class} #{e.message}\n#{e.backtrace.join("\n")}"
        Thread.new do
          Vodpod.alert :service => 'api', 
            :state => :error,
            :once => true,
            :description => text
        end
        Ramaze::Log.error text
      end

      if $1 and ($1 == 'js' or $1 == 'json')
        # Return JSON
        content_type = 'application/json'
        message = [false, e].to_json.to_s
      elsif $1 and $1 == 'xml'
        # Return XML
        content_type = 'text/xml'
        doc = LibXML::XML::Document.new
        doc.root = e.to_xml
        message = doc.to_s
      elsif $1 and $1 == 'txt'
        content_type = 'text/plain'
        str = case e
               when API::Error
                 e.message
               else
                 'Server error'
               end
        s = str.size
        message = '' + 
          '  _' + '_'*s +   "_\n" +
          ' / ' + ' '*s + " \\\n" +
          ' | ' + str +   " |\n" +
          ' \_' + '_'*s + "_/\n" +
          "        /\n" +
          "   0__0\n" +
          " (/^  ^\\)             the vodfrog"
      else
        # Return human-readable text.
        content_type = 'text/plain'
        message = JSON.pretty_generate([false, e])
      end

      [
        code, 
        {
          "Content-Type" => content_type,
          'Content-Length' => message.size.to_s
        },
        [message]
      ]
    end
  end
end
