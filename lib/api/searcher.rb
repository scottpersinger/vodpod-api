# Provides centralized, thread-safe search lookups, including connection and
# tunnel handling, plus filter support.
class API::Searcher
  attr_reader :ready

  def initialize
    @config = API.config.solr
    @client = Vodpod::SolrClient.new(
      @config.host,
      :port => @config.port,
      :timeout => @config.timeout,
      :raise_errors => true
    )
  end

  # Performs a search
  def search(query, params = {})
    # Options passed to SolrClient
    opts = {:boost => true}

    # Limit results
    if num = params['limit'] || params['per_page']
      i = num.to_i
      if num =~ /[^\d]/
        raise API::Error.new("invalid limit (#{num}) is not an integer")
      elsif i > @config.maximum_limit
        raise API::Error.new("limit (#{i}) is higher than the maximum #{@config.maximum_limit}")
      else
        opts[:limit] = i
      end
    else
      # Apply the default for limits if none is set.
      opts[:limit] = @config.default_limit
    end

    # Offset results
    if num = params['offset']
      i = num.to_i
      if num =~ /[^\d]/
        raise API::Error.new("invalid offset (#{num}) is not an integer")
      else
        opts[:offset] = i
      end
    elsif num = params['page']
      i = num.to_i
      if num =~ /[^\d]/
        raise API::Error.new("invalid page (#{num}) is not an integer")
      elsif i <= 0
        raise API::Error.new("invalid page (#{num}) is less than 1")
      else
        opts[:offset] = (i - 1) * opts[:limit]
      end
    end

    # Do search
    case params['type']
    when 'collection_video'
      klass = Vodpod::CollectionVideo
      results = @client.search_collection_videos(query, params['collection_ids'], opts) 
    when 'video'
      klass = Vodpod::Video
      results = @client.search_videos(query, opts)
    when 'user'
      klass = Vodpod::User
      results = @client.search_users(query, opts)
    else
      raise API::Error, "no search type given"
    end

    ids = results[:ids]
    total = results[:total]

    # Fetch from DB
    # We construct a limited subset (just enough for include/serialize) of the
    # parameter hash, preprocess it using api_validate (which splits lists, etc)
    # and apply the include/serialize methods to the dataset.
    models = {}
    ds = klass.filter(:id => ids)
    filter_params = {'include' => params['include']}
    ds.api_validate filter_params
    ds = ds.api_include(filter_params)
    ds = ds.api_serialize(filter_params)
    ds.all.each do |model|
      models[model.id] = model
    end

    # Construct result set
    a = NamedArray.new('videos', ids.map { |id| models[id] }.compact)
    a.total = total
    a
  end
end
