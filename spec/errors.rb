class API::MainController
  h 'error' do
    HeyImAnUndefinedConstant
  end

  h 'timeout' do
    sleep 10
  end
end

describe 'errors' do
  behaves_like :rack_test
  behaves_like :api

  should 'serialize exceptions to JSON correctly' do
    err = json_plain('/error')[1]
    err['backtrace'].should.not.be.blank
    err['message'].should =~ /uninitialized constant /
  end

  should 'time out with 500' do
    t1 = Time.now
    err = get('/timeout?api_key=123456')
    (Time.now - t1).should < 5
    err.status.should == 500
    e = JSON.parse(err.body)
    e[0].should == false
    e[1]['message'].should == 'timed out'
  end
end
