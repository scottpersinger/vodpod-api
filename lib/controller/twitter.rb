class API::TwitterController < Ramaze::Controller
  map '/twitter'
  
  # Compatible with http://twitpic.com/api.do
  def upload
    unless request.post?
      error_404
    end

    # Get user
    begin
      provider = URI.parse request[:x_auth_service_provider]
      if provider.host =~ /twitter\.com$/ and
         authorization = request[:x_verify_credentials_authorization]
         # This is an oauth echo request.
         user = Vodpod::User.authenticate_twitter(nil, nil, :provider => provider, :authorization => authorization, :create => true)
      else
        user = Vodpod::User.authenticate_twitter(request[:username], request[:password]) or raise Vodpod::Twitter::InvalidPasswordException
      end
    rescue Sequel::DatabaseDisconnectError => e
      # Rack will recover and retry for us.
      raise e
    rescue Vodpod::Twitter::InvalidPasswordException
      error 1001, 'Invalid twitter username or password'
    rescue => e
      Ramaze::Log.error e
      error 2001, "Server error"
    end

    # Title
    message = request[:message]
    if message.blank?
      message = request[:username] + ' on ' + Time.now.strftime("%b %d %Y")
    end

    # Description
    if request[:source].blank?
      description = ''
    else
      description = "Posted with #{request[:source]}"
    end

    # Collect video
    begin
      v = user.collect_new_video(
        :title => message,
        :description => description,
        :media => request[:media][:tempfile],
        :provenance => Vodpod::Provenance::FROM_TWITTER,
        :s3_opts => {
          'Cache-Control' => '10'
        }
      )
      success v
    rescue Vodpod::UploadError => e
      Ramaze::Log.error e
      error 2001, "Server error"
    rescue Vodpod::SaveError => e
      Ramaze::Log.error e
      error 2001, "Server error"
    end
  end

  private

  def error(code, message)
    Ramaze::Log.error "Twitpic error: #{code} #{message}"

    doc = LibXML::XML::Document.new
    doc.root = root = LibXML::XML::Node.new('rsp')
    root['stat'] = 'fail'
    
    root << (err = LibXML::XML::Node.new('err'))
    err['code'] = code.to_s
    err['msg'] = message.to_s

    respond doc.to_s, 200, {'Content-Type' => 'text/xml'}
  end

  def success(video)
    doc = LibXML::XML::Document.new
    doc.root = root = LibXML::XML::Node.new('rsp')
    root['stat'] = 'ok'

    root << (mediaid = LibXML::XML::Node.new('mediaid'))
    mediaid << video.key.to_s
    
    root << (mediaurl = LibXML::XML::Node.new('mediaurl'))
    mediaurl << video.url.to_s

    respond doc.to_s, 200, {'Content-Type' => 'text/xml'}
  end
end
