class API::MainController
  h 'videos', :*, 'recommend' do |video_key|
    require_write_auth

    if API.video(video_key).recommend(@client, request.env['HTTP_X_REAL_IP'])
      true
    else
      raise API::Error, "already recommended"
    end
  end
end
