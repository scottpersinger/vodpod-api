class DocController < Ramaze::Controller
  map '/doc'
  engine :None
  layout nil

  def index
    redirect '/v2/doc/index.html'
  end
end
