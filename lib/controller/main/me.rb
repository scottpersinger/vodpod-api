class API::MainController
  timeout false
  h 'me', :** do |*args|
    index 'users', @client.key, *args
  end
end
