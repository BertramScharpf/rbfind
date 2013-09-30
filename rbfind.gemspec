#
#  rbfind.gemspec  --  RbFind Gem specification
#

require "./lib/rbfind"

Gem::Specification.new do |s|
  s.name              = "rbfind"
  s.rubyforge_project = "NONE"
  s.version           = RbFind::VERSION
  s.summary           = "Ruby replacement for the standard Unix find tool"
  s.description       = <<EOT
A replacement for the standard UNIX command find.
Files may be examined using Ruby expressions.
Full ls-style output support including color.
Full grep-style output support.
EOT
  s.license           = "BSD"
  s.authors           = [ "Bertram Scharpf"]
  s.email             = "<software@bertram-scharpf.de>"
  s.homepage          = "http://www.bertram-scharpf.de/software/rbfind"

  s.requirements      = "just Ruby"

  s.extensions        = %w(
                          Rakefile
                        )
  s.files             = %w(
                          lib/rbfind.rb
                          lib/humansiz.rb
                        )
  s.executables       = %w(
                          rbfind
                        )

  s.has_rdoc          = true
  s.rdoc_options.concat %w(--charset utf-8 --main README)
  s.extra_rdoc_files  = %w(
                          LICENSE
                        )
end

