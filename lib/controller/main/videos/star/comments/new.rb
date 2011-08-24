class API::MainController
  # Create a comment
  h 'videos', :*, 'comments', 'new' do |video_key|
    require_write_auth

    begin
      API.video(video_key).comment(
        :text => request[:text],
        :user => @client
      )
    rescue Vodpod::InvalidRecord => e
      raise API::Error, e.message
    end
  end
end
