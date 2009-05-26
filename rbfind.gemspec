#
#  rbfind.gemspec  --  RbFind Gem specification
#

require "rubygems"


class Gem::Specification

  def extract_version
    File.open "bin/rbfind" do |f|
      f.each { |l|
        l =~ /^rbfind\s*(\S*)\s*--/ and return $1
      }
    end
    nil
  end

  alias files_orig files
  def files
    @built ||= system "rake"
    @built or raise "build (rake) failed."
    files_orig
  end

end



SPEC = Gem::Specification.new do |s|
  s.name              = "rbfind"
  s.rubyforge_project = "rbfind"
  s.version           = s.extract_version
  s.summary           = "Ruby replacement for the standard Unix find tool"
  s.description       = <<EOT
A replacement for the standard UNIX command find.
Files may be examined using Ruby expressions.
Full ls-style output support including color.
Full grep-style output support.
EOT
  s.authors           = [ "Bertram Scharpf"]
  s.email             = "<software@bertram-scharpf.de>"
  s.homepage          = "http://www.bertram-scharpf.de"
  s.requirements      = "just Ruby"
  s.has_rdoc          = true
  s.files             = %w(
                          rbfind.rb
                          humansiz.rb
                        ).map do |p| File.join "lib", p end
  s.executables       = %w(
                          rbfind
                        )
  s.extra_rdoc_files  = %w(
                          README
                          LICENSE
                        )
end

if $0 == __FILE__ then
  Gem::Builder.new( SPEC).build
end

