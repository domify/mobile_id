Gem::Specification.new do |s|
  s.name        = 'MobileID'
  s.version     = '0.0.1'
  s.date        = '2020-09-22'
  s.summary     = "Estonia Mobile ID authentication"
  s.description = "Estonia Mobile ID authentication, more info at https://www.id.ee/en/"
  s.authors     = ["Priit Tark"]
  s.email       = 'priit@gitlab.eu'
  s.files       = ["lib/mobile_id.rb"]
  s.homepage    = 'https://rubygems.org/gems/mobile_id'
  s.license     = 'MIT'
  s.add_runtime_dependency 'httparty'
  s.add_runtime_dependency 'openssl', '>= 2.2.0'
  s.add_runtime_dependency 'i18n'
  s.add_runtime_dependency 'activesupport'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry'
end
