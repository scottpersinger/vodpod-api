class API::MainController
  h 'logout' do
    session[:user_id] = nil
    true
  end
end
