class API::MainController
  # Recommend a user's video
  h 'users', :*, 'collections', :*, 'videos', :*, 'recommend' do |user_key, collection_key, video_key|
    require_write_auth

    if API.video(user_key, collection_key, video_key).recommend(@client, request.env['HTTP_X_REAL_IP']) 
      true
    else
      raise API::Error, "already recommended"
    end
  end
end
