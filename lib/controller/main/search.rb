class API::MainController
  cache_with PAGE_CACHE_KEYS + RECORD_CACHE_KEYS + SEARCH_CACHE_KEYS
  h 'search' do
    API.search request[:query], request.params
  end
end
