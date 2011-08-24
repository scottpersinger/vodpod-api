class API::MainController
  # Show the default collection for a user.
  h 'users', :*, 'collection', :** do |user, *args|
    index 'users', user, 'collections', :default, *args
  end
end
