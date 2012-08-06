Gem::Specification.new do |s|
  s.name = %q{bakery}
  s.version = "0.0.2"
  s.authors = ["Di Wu", "Siwon Choi"]
  s.email = ["wudiac@gmail.com", "bakery@coo.ki"]
  s.date = %q{2012-08-05}
  s.homepage = "http://coo.ki"
  s.summary = %q{Bakery From Coo.Ki}
  s.description = %q{Bakery fork from ruby-readability}

  s.files = `git ls-files`.split("\n")

  s.require_paths = ["lib"]

  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_development_dependency "rspec", ">= 2.8"
  s.add_development_dependency "rspec-expectations", ">= 2.8"
  s.add_development_dependency "rr", ">= 1.0"
  s.add_dependency 'nokogiri', '>= 1.4.2'
  s.add_dependency 'guess_html_encoding', '>= 0.0.4'
end
