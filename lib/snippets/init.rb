%w(xml json symbol rackfix).each do |snippet|
  require File.expand_path(File.join(File.dirname(__FILE__), snippet))
end
