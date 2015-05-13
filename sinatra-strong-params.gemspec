Gem::Specification.new do |s|
  s.name        = 'sinatra-strong-params'
  s.version     = '0.1.0'
  s.licenses    = ['MIT']
  s.summary     = "Strong parameters for sinatra applications"
  s.description = "Strong parameters for sinatra applications"
  s.authors     = ['Nicolay Hvidsten']
  s.email       = 'nicohvi@gmail.com'
  s.files       = ['lib/sinatra/strong_parameters.rb']
  s.homepage    = 'https://rubygems.org/gems/sinatra-strong-params'

  s.add_dependency('hashie', '>=3.4.0')
  
  s.add_development_dependency('rspec', '>=3.0.0')
  s.add_development_dependency('guard', '>=2.12.5')
  s.add_development_dependency('guard-rspec', '4.5.0')
end
