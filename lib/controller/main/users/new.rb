class API::MainController
  h 'users', 'new' do
    # TODO: when the java client can POST sanely, we'll uncomment this.
#      unless request.post?
#        raise API::Error, "HTTP POST required"
#      end

    if request[:email].blank?
      raise API::Error, "missing parameter: email"
    end
    if request[:key].blank?
      raise API::Error, "missing parameter: key"
    end
    if request[:password].blank?
      raise API::Error, "missing parameter: password"
    end

    #DEPRECATED: 'username' parameter.
    user = Vodpod::User.new(
      :name => request[:name] || request[:key] || request[:username],
      :key => request[:key] || request[:username],
      :email => request[:email],
      :password => request[:password]
    )
    
    begin
      user.save or raise
    rescue Sequel::DatabaseDisconnectError => e
      raise e
    rescue => e
      Ramaze::Log.warn e.message
      unless user.errors.empty?
        message = user.errors.map { |attr, errors|
          "#{attr} #{errors.join(' and ')}"
        }.join(', ')
      else
        message = "save error"
      end
      
      raise API::Error, "couldn't create new user: #{message}"
    end
  end
end
