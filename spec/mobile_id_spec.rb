require 'spec_helper'

describe MobileId do
  before do 
    @mid = MobileId::Auth.new(live: false)
  end

  it 'should init hash' do
    @mid.hash.nil?.should == false
  end

  it 'should have demo service url' do
    @mid.url.should == "https://tsp.demo.sk.ee/mid-api"
  end

  it 'should have demo service name' do
    @mid.name.should == "DEMO"
  end

  it 'should have demo service uuid' do
    @mid.uuid.should == "00000000-0000-0000-0000-000000000000"
  end

  it 'should get auth hash with session id' do
    auth = @mid.authenticate!(phone: '00000766', personal_code: '60001019906')
    auth[:session_id].nil?.should == false
    auth[:phone].should == '00000766'
    auth[:phone_calling_code].should == '+372'
  end

  it 'should get verified user attributes' do
    auth = @mid.authenticate!(phone: '00000766', personal_code: '60001019906')
    verify = @mid.verify!(auth)
    verify.should == 
      { 
        "personal_code"=>"60001019906",
        "first_name"=>"MARY ÄNN",
        "last_name"=>"O’CONNEŽ-ŠUSLIK TESTNUMBER",
        "phone"=>"00000766",
        "phone_calling_code"=>"+372",
        "auth_provider"=>"mobileid"
      }
  end

  it 'should raise error with response code' do
    lambda { @mid.long_poll!(session_id: 'wrongid', doc: '') }.should raise_error(MobileId::Error, /There was some error 400/)
  end
end
