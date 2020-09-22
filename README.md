# MobileId::Ruby::Gem

Estonia Mobile ID authentication, more info at https://www.id.ee/en/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mobile_id'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mobile_id

## Test usage

Execute irb:

    $ bundle exec irb
    irb(main):001:0> require 'mobile_id'
    => true
    irb(main):002:0> @mid = MobileId.new(live: false)
    => #<MobileId:0x000055ac4cb25630 @url="https://tsp.demo.sk.ee/mid-api", @uuid="00000000-0000-0000-0000-000000000000", @name="DEMO", @hash="two+e7UMoFCAXHo8q9AnWqSC58Hhil74RowY8Gg9xQY=">
    irb(main):003:0> auth = @mid.authenticate!(phone: '00000766', personal_code: '60001019906')
    => {"session_id"=>"34e7eff0-691b-4fad-9798-8db680587b18", "phone"=>"00000766", "phone_calling_code"=>"+372"}
    irb(main):004:0> verify = @mid.verify!(auth)
    => {"personal_code"=>"60001019906", "first_name"=>"MARY ÄNN", "last_name"=>"O’CONNEŽ-ŠUSLIK TESTNUMBER", "phone"=>"00000766", "phone_calling_code"=>"+372", "auth_provider"=>"mobileid"}

You get verified attributes: personal_code, first_name, last_name, phone, phone_calling_code, auth_provider


## Live usage

For live usage, add your relyingPartyUUID (RPUUID) and relyingPartyName what you get from https://www.sk.ee

```ruby
    @mid = MobileId.new(live: true, uuid: "39e7eff0-241b-4fad-2798-9db680587b20", name: 'My service name')
```

Rails with Devise example controller:

```ruby
class MobileSessionsController < ApplicationController
  include Devise::Controllers::Helpers
  skip_authorization_check only: [:new, :show, :create, :update]
  before_action :init_mobile_id, only: [:create, :update]
  
  def new
    @user = User.new
  end

  # makes Mobile ID authentication
  def create
    session[:auth] = @mid.authenticate!(phone: params[:phone], personal_code: params[:personal_code])
    render :show, locals: { verification_code: @mid.verification_code }
  rescue MobileId::Error => e
    render :error, locals: { message: e }
  end

  # verifices Mobile ID user
  def update
    session[:auth] = @mid.verify!(session[:auth])
    find_or_create_user_and_redirect(personal_code: @mid.personal_code)
  rescue MobileId::Error => e
    render :error, locals: { message: e }
  end

  private

  def init_mobile_id
    @mid = MobileId.new(live: true, uuid: ENV['sk_mid_uuid'], name: ENV['sk_mid_name'])
  end

  # It's pure your system business logic what to do here with validated user attributes, example code:
  def find_or_create_user_and_redirect(personal_code:)
    @user = User.find_by(personal_code: personal_code)

    # bind currently present email only account with mobile-id
    if @user.nil? && current_user&.confirmed_email_only_account?
      @user = current_user 
      @user.personal_code = personal_code
      @user.save!
    end

    return redirect_to new_omniuser_url, notice: t(:finish_setup) if @user.nil? || @user.new_record?
    return redirect_to root_url, alert: t(:unlock_info) if @user.access_locked?

    if @user.valid? && @user.confirmed_at
      # overwrite name changes
      @user.first_name = session[:auth]['first_name'] if session[:auth]['first_name'].present?
      @user.last_name  = session[:auth]['last_name']  if session[:auth]['last_name'].present?
      @user.save! if @user.changed?

      sign_in_and_redirect(@user, notice: t('devise.sessions.signed_in'))
    else
      redirect_to edit_omniuser_url(@user), notice: t('devise.failure.unconfirmed')
    end
  end
end
```

## Development

After checking out the repo, run `bundle` to install dependencies. For testing code, run `rspec`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gitlabeu/mobile_id

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Sponsors

Gem development and testing is sponsored by [GiTLAB](https://gitlab.eu).
