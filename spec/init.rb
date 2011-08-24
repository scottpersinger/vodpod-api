require 'rubygems'
require 'ramaze'
require 'ramaze/spec/bacon'
require 'sequel/extensions/blank'

require __DIR__('shared')
require __DIR__('../lib/vodpod-api')

Ramaze.options.roots = __DIR__('../')
API.init
API.start

include 
