Gem::Specification.new do |s|
  s.name        = 'mobile_id'
  s.version     = '0.0.8'
  s.date        = '2020-09-22'
  s.summary     = "Estonia Mobile ID authentication"
  s.description = "Estonia Mobile ID authentication"
  s.authors     = ["Priit Tark"]
  s.email       = 'priit@gitlab.eu'
  s.files       = Dir.glob("{lib}/**/*") + %w(MIT-LICENSE README.md CHANGELOG.md)
  s.homepage    = 'https://github.com/gitlabeu/mobile_id'
  s.license     = 'MIT'
  s.add_runtime_dependency 'httparty'
  s.add_runtime_dependency 'openssl', '>= 2.2.0'
  s.add_runtime_dependency 'i18n'
  s.add_runtime_dependency 'activesupport'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry'
end
