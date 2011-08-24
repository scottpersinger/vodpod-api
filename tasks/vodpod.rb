desc 'Publish to gems.vodpod.com'
task :publish do
  port = '45432'

  # Open SSH tunnel through backend1
  tunnel = Thread.new do
    puts "Opening tunnel"
    `ssh -f -L #{port}:gems.vodpod.com:22 #{ENV['USER']}@backend1.vodpod.com sleep 5`
  end

  # Wait for the tunnel to come online.
  sleep 2

  # Upload
  gemfile = "pkg/vodpod-api-#{API::VERSION}.gem"
  puts "Uploading gem #{gemfile}"
  File.chmod 0664, gemfile
  `scp -p -P #{port} #{gemfile} localhost:/pub/gems/gems/`

  # Regenerate index
  puts "Regenerating gem index"
  `ssh -p #{port} localhost "gem generate_index -d /pub/gems; chmod -R g+w /pub/gems/*; chgrp -R gems /pub/gems/*"`

  # Close tunnel thread
  tunnel.exit
  
  puts "Done."
end

desc "Reinstall gem"
task :reinstall do
  `sudo gem uninstall --executables vodpod-api`
  Rake::Task["build"].execute
  Rake::Task["install"].execute
end
