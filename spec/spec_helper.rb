# frozen_string_literal: true

require 'bundler/setup'
Bundler.setup

require 'pry'
require 'mobile_id'
require 'i18n'
I18n.config.available_locales = :en
I18n.load_path << Dir["#{File.expand_path('lib/mobile_id/locales')}/*.yml"]

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end
