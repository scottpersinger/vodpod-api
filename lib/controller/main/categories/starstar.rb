class API::MainController
  # Choose a specific category
  cache_with RECORD_CACHE_KEYS
  h 'categories', :** do |*args|
    API::Category.resolve(*args).api_filter(request.params).first
  end
end
