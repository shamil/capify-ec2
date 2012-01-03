# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "capify-ec2"
  s.version     = "1.1.19"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Noah Cantor", "Siddharth Dawara"]
  s.email       = ["noah.cantor@forward.co.uk", "siddharth.dawara@forward.co.uk"]
  s.homepage    = "http://github.com/forward/capify-ec2"
  s.summary     = %q{Grabs roles from ec2's tags and autogenerates capistrano tasks}
  s.description = %q{Grabs roles from ec2's tags and autogenerates capistrano tasks}

  s.rubyforge_project = "capify-ec2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'capistrano', '>=2.1.0'
  s.add_dependency 'fog', '>=0.9.0'
  s.add_dependency 'colored'
end
