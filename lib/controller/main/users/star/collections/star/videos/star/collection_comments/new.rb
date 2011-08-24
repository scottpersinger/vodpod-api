class API::MainController
  # Create a collection comment
  h 'users', :*, 'collections', :*, 'videos', :*, 'collection_comments', 'new' do |user_key, collection_key, video_key|
    require_write_auth

#    unless request.post?
#      raise API::Error, 'HTTP POST required'
#    end

    unless user_key == @client.key
      raise API::Error, "can't comment on another user's collection video. check that your API key or login matches the user in the path."
    end

    if !request[:user].blank? and request[:user].kind_of? Hash
      user = request[:user]
    elsif request[:user].blank?
      user = @client
    else
      raise API::Error, "invalid value for parameter 'user'"
    end

    begin
      API.video(user_key, collection_key, video_key).collection_comment(
        :text => request[:text],
        :user => request[:user]
      )
    rescue Vodpod::InvalidRecord => e
      raise API::Error, e.message
    end
  end
end
