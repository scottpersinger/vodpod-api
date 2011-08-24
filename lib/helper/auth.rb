module Ramaze
  module Helper
    module Auth
      DONT_AUTH = [
        /^\/login$/,
        /^\/users\/new$/
      ]

      def identify_client
        short_path = request.path_info[/^(\/.*?)(\.\w+)?$/, 1]

        # Set up client user before each action.
        if !(key = request[:api_key]).blank?
          # Load the client from the given API key
          unless @client = API.cache["users/api_key/#{key}"]
            if u = Vodpod::User[:api_key => key]
              API.cache.store("users/api_key/#{key}", u, :ttl => 600)
              @client = u
            else
              raise API::ForbiddenError.new('invalid API key')
            end
          end
        elsif id = session[:user_id]
          # Try to load the client from the session
          unless @client = API.cache["users/id/#{id}"]
            if u = Vodpod::User[id]
              API.cache.store("users/id/#{id}", u, :ttl => 600)
              @client = u
            else
              raise API::ForbiddenError.new('no API key provided')
            end
          end
        elsif DONT_AUTH.any? { |pattern| pattern === short_path }
          # Login doesn't need an established client.
          @client = nil
        else
          # No login, no API key
          raise API::ForbiddenError.new('no API key provided')
        end

        true
      end

      # Checks to ensure that the client has write authorization.
      # Raises an API error otherwise.
      def require_write_auth
        if session[:user_id]
          true
        elsif @client and @client.auth_key == request[:auth_key]
          true
        elsif request[:auth_key]
          raise API::ForbiddenError, "auth_key incorrect"
        else
          raise API::ForbiddenError, "auth_key or login required"
        end
      end
    end
  end
end
