#
#  rbfind.gemspec  --  RbFind Gem specification
#

$:.unshift "./lib"
require "rbfind"

Gem::Specification.new do |s|
  s.name              = "rbfind"
  s.version           = RbFind::VERSION
  s.summary           = "Ruby replacement for the standard Unix find tool"
  s.description       = <<~EOT
    A replacement for the standard UNIX command find.
    Files may be examined using Ruby expressions.
    Full ls-style output support including color.
    Full grep-style output support.
  EOT
  s.license           = "BSD-2-Clause+"
  s.authors           = [ "Bertram Scharpf"]
  s.email             = "<software@bertram-scharpf.de>"
  s.homepage          = "http://www.bertram-scharpf.de/software/rbfind"

  s.requirements          = "Just Ruby"
  s.required_ruby_version = ">= 3.1.0"

  s.require_paths     = %w(lib)
  s.bindir            = "bin"

  s.extensions        = %w(
                        )
  s.files             = %w(
                          README.md
                          lib/rbfind.rb
                          lib/rbfind/core.rb
                          lib/rbfind/appl.rb
                          lib/rbfind/csv.rb
                          lib/rbfind/humansiz.rb
                          lib/rbfind/table.rb
                        )
  s.executables       = %w(
                          rbfind
                        )

  s.extra_rdoc_files  = %w(LICENSE README.md)
end

