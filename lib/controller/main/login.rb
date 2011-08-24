class API::MainController
  h 'login' do
    if user = Vodpod::User.authenticate(request[:username], request[:password])
      session[:user_id] = user.id
      if request[:return_user]
        user.serialize_attrs += ['api_key', 'auth_key']
        user
      else
        true
      end
    else
      raise API::Error, 'invalid credentials'
    end
  end
end
