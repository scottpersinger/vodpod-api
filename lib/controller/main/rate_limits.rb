class API::MainController
  h 'rate_limits' do
    limit = API.cache["rate_limits/users/#{@client.key}"]
    NamedHash.new('rate_limits',
      'limit' => Ramaze::Helper::RateLimit::REMAINING,
      'interval' => Ramaze::Helper::RateLimit::INTERVAL,
      'reset' => Time.at(limit[0]),
      'remaining' => limit[1]
    )
  end
end
