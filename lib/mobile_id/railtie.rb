require 'rails'

module MobileId
  class Railtie < ::Rails::Railtie #:nodoc:
    initializer 'mobile_id' do |app|
      DeviseI18n::Railtie.instance_eval do
        (app.config.i18n.available_locales & MobileId::LOCALES).each do |loc|
          I18n.load_path << File.expand_path("locales/#{loc}.yml", __dir__)
        end
      end
    end
  end
end
