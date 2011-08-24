class API::MainController < API::Controller
  # Keys which are always valid.
  KEYS = [
    'api_key', 'auth_key'
  ]
  PAGE_CACHE_KEYS = [
    'sort',
    'order', 
    'limit',
    'offset',
    'page',
    'per_page'
  ]
  RECORD_CACHE_KEYS = [
    'include'
  ]
  TAG_CACHE_KEYS = [
    'tag',
    'tags',
    'tag_mode'
  ]
  SEARCH_CACHE_KEYS = [
    'query'
  ]

  helper :auth, :rate_limit
  before_all do
    identify_client
    rate_limit
  end

  h do
    true
  end

  Find.find("#{File.dirname(__FILE__)}/main/") do |path|
    require path if path =~ /\.rb$/
  end
end
