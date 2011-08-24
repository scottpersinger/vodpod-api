class API::MainController
  # Search for a user
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS + SEARCH_CACHE_KEYS
  h 'search', 'users' do
    params = {
      'type' => 'user'
    }.merge(request.params)

    API.search(request[:query], params)
  end
end
