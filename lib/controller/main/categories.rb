class API::MainController
  # Top-level categories
  cache_with PAGE_CACHE_KEYS + RECORD_CACHE_KEYS
  h 'categories' do
    ds = API::Category.top.api_filter(request.params).all
    a = NamedArray.new('categories', ds)
    a.total = ds.size
    a
  end
end
