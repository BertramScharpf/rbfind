#
#  Rakefile  --  build RbFind project
#

task "README" do |t|
  File.open t.name, "w" do |readme|
    readme.puts `ruby -I lib bin/rbfind --version`
    readme.puts
    readme.puts `ruby -I lib bin/rbfind --examples`
  end
end

task :default => "README"

task :clean do |t|
  sh "rm", "-fv", "README"
end

