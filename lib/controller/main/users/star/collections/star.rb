class API::MainController
  # Show a specific collection
  cache_with RECORD_CACHE_KEYS
  h 'users', :*, 'collections', :* do |user, collection|
    API.collection(user, collection, request.params)
  end
end
