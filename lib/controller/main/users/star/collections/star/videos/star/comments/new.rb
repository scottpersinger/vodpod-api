class API::MainController
  # Create a comment
  h 'users', :*, 'collections', :*, 'videos', :*, 'comments', 'new' do |user_key, collection_key, video_key|
    require_write_auth

    begin
      API.video(user_key, collection_key, video_key).comment(
        :text => request[:text],
        :user => @client
      )
    rescue Vodpod::InvalidRecord => e
      raise API::Error, e.message
    end
  end
end
