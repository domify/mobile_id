require 'rails'

module MobileId
  class Railtie < ::Rails::Railtie #:nodoc:
    initializer 'mobile_id' do |app|
      DeviseI18n::Railtie.instance_eval do
        app.config.i18n.available_locales.each do |loc|
          I18n.load_path << Dir[File.expand_path("lib/mobile_id/locales") + "/#{loc}.yml"]
        end
      end
    end
  end
end
