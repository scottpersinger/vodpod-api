class API::MainController
  # Search in a collection
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS + SEARCH_CACHE_KEYS
  h 'users', :*, 'collections', :*, 'search' do |user, collection|
    params = {
      'user' => user,
      'collection' => collection
    }.merge(request.params)

    API.search(request[:query], params)
  end
end
