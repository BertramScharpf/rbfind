#
#  Rakefile  --  build RbFind project
#

# $Id: Rakefile 314 2009-03-13 17:42:33Z bsch $


task "README" do |t|
  File.open t.name, "w" do |readme|
    readme.puts `ruby -I lib bin/rbfind --version`
    readme.puts
    readme.puts `ruby -I lib bin/rbfind --examples`
  end
end

task :default => "README"

task :clean do |t|
  sh "rm", "README"
end

