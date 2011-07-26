task :default => 'build'

desc "Create stub for new post"
task :new_post do
  # require 'lib/tasks/Post.rb'
  # Post.write_stub(category, post_name)
end

desc "Clean dir structure. Empty /_site"
task :clean do
  sh "rm -rf _sites/*"
end

desc "Exec jekyll"
task :build => :clean do
  sh "jekyll"
end

desc "Deploy files to server (would be nice to use config)"
task :deploy => :build do
end

namespace :server do
  desc "Start local server"
  task :start do
    sh "jekyll --server"
  end

  desc "Start local server with auto-update"
  task :auto do
    sh "jekyll --server --auto"
  end
end
