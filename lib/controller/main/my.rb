class API::MainController
  timeout false
  h 'my', :** do |*args|
    index 'users', @client.key, *args
  end
end
