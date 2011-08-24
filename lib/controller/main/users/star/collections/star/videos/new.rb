class API::MainController
  # Upload to a specific collection
  timeout 200
  h 'users', :*, 'collections', :*, 'videos', 'new' do |user, collection|
    # Parameters:
    #   video
    #   title
    #   description
    #   tags
    #
    #   TODO: fold validation into models.
    
    # Validation
    require_write_auth
    
#    unless request.post?
#      raise API::Error, 'HTTP POST required'
#    end

    unless @client.key == user
      raise API::Error "can't add a video to another user's collection"
    end

    # Deal with fucktarded apache httpclient4 attaching content-type whether
    # you like it or not, the fuckers. Rack should be able to work around it
    # soon--1.1 maybe?
    myparams = request.params.dup
    [:title, :description, :tags, :client, :key].each do |field|
      if request[field].kind_of? Hash and file = request[field][:tempfile]
        data = file.read
        myparams[field.to_s] = data
      end
      file = nil
    end
    
    if request[:media] and request[:title].blank?
      raise API::Error, "title must not be blank"
    end

    unless request[:key] or (request[:media] and request[:media][:tempfile].respond_to? :read)
      raise API::Error, "media invalid or missing"
    end

    unless collection = Vodpod::Collection.belonging_to(user).api_get(collection).first
      raise API::Error, "collection (#{collection}) does not exist for user #{user})"
    end

    provenance = case myparams['client']
      when 'android'
        Vodpod::Provenance::FROM_ANDROID
      when 'iphone'
        Vodpod::Provenance::FROM_IPHONE
      else
        Vodpod::Provenance::FROM_API_UPLOAD
      end                

    begin
      collection.collect_new_video(
        :title => myparams['title'],
        :description => myparams['description'],
        :tags => myparams['tags'],
        :media => (request[:media][:tempfile] rescue nil),
        :key => myparams['key'],
        :provenance => provenance,
        :s3_opts => {
          'Cache-Control' => '10'
        }
      )
    rescue Vodpod::InvalidVideoCodec => e
      raise API::Error, e
    rescue Vodpod::UploadError => e
      Ramaze::Log.error e
      raise API::Error, "error uploading video"
    rescue Vodpod::SaveError => e
      Ramaze::Log.error e
      raise API::Error, "error saving video: #{e.message}"
    end
  end

end
