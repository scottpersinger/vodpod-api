class API::MainController
  # News feed
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS, :ttl => 60
  h 'users', :*, 'feed' do |user_key|
    unless user = Vodpod::User.api_get(user_key).first and user === @client
      raise API::Error, "can't retrieve another user's feed"
    end
   
    feed = user.feed_dataset.api_filter(request.params)
    a = NamedArray.new('feed', feed.all)
    ds = feed.unlimited.select(:news_feed_items__id)
    a.total = ds.count
    a.unread = ds.filter("created_at >= ?", user.feed_checked_at).count
    a
  end
end
