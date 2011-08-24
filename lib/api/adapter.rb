#!/usr/bin/ruby

# Require this file after requiring vodpod-api if you would like access to the
# API models and API core without the overhead of the full request parser. Use
# API.users, API.collections, etc.

# Convert symbols to strings
def API.preprocess(params)
  o = {}
  params.each do |param, value|
    o[param.to_s] = value
  end
  o
end
