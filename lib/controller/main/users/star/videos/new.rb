class API::MainController
  # User video upload
  timeout 200
  h 'users', :*, 'videos', 'new' do |user|
    # Accept an mp4 video.
    # Parameters:
    #   video
    #   title
    #   description
    #   tags
    #   client
    
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

    if request[:media] and myparams["title"].blank?
      raise API::Error, "title must not be blank"
    end

    unless myparams["key"] or (request[:media] and request[:media][:tempfile].respond_to? :read)
      raise API::Error, "media invalid or missing"
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
      @client.collect_new_video(
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
    rescue Sequel::ValidationFailed => e
      if err = e.errors[[:video_id, :group_id]]
        raise API::Error, err
      else
        raise e
      end
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
