#!/usr/bin/ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/bacon'
require 'sequel/extensions/blank'
require 'irb'
require 'irb/completion'

require __DIR__('../spec/shared')
load __DIR__('../bin/vodpod-api')
Ramaze.options.roots = __DIR__('../')

# IRB monkeypatch to let us load a custom context object
class IRB::Irb
  alias initialize_orig initialize
  def initialize(workspace = nil, *args)
    default = IRB.conf[:DEFAULT_OBJECT]
    workspace ||= IRB::WorkSpace.new default if default
    initialize_orig(workspace, *args)
  end
end

module API
  describe '' do
    behaves_like :rack_test
    behaves_like :api

    it '' do
      IRB.conf[:DEFAULT_OBJECT] = self
      IRB.start
    end
  end
end
