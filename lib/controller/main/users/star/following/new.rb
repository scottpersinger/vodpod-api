class API::MainController
  # Follow a user
  h 'users', :*, 'following', 'new' do |user_key|
    require_write_auth

    unless user = Vodpod::User.api_get(user_key).first and user === @client
      raise API::Error, "can't follow on behalf of another user"
    end

    begin
      user.follow API.user(request[:key])
      true
    rescue Sequel::DatabaseError => e
      if e.message[/Duplicate entry/]
        raise API::Error, "already following user (#{request[:key]})"
      else
        raise e
      end
    rescue ArgumentError => e
      # Argument errors are raised for following one's self.
      raise API::Error, e.message
    end
  end
end
