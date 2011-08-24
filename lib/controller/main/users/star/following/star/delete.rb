class API::MainController
  # Unfollow a user
  h 'users', :*, 'following', :*, 'delete' do |user_key, target_key|
    require_write_auth

    unless user = Vodpod::User.api_get(user_key).first and user === @client
      raise API::Error, "can't unfollow on behalf of another user"
    end

    begin
      begin
        user.unfollow API.user(target_key)
        true
      rescue Sequel::DatabaseError => e
        if e.message[/Duplicate entry/]
          raise API::Error, "not currently following user (#{request[:key]})"
        else
          raise e
        end
      end
    rescue ArgumentError => e
      # ArgumentErrors are raised for following one's self.
      raise API::Error, e.message
    end
  end
end
