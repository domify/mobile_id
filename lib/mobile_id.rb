# frozen_string_literal: true

require 'securerandom'
require 'digest'
require 'httparty'
require 'active_support/core_ext/hash/indifferent_access'
require 'i18n'
if defined?(Rails)
  require 'mobile_id/railtie' 
else
  I18n.load_path << Dir[File.expand_path("lib/mobile_id/locales") + "/*.yml"]
end

module MobileId
  class Error < StandardError; end

  LOCALES = [:en, :et, :ru]
end

require 'mobile_id/cert'
require 'mobile_id/auth'
