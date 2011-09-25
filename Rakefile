require 'rake'

task :default => 'build'

desc "Create stub for new post"
task :new_post do
  require '_lib/Post.rb'
  stub_path = Post.create_stub(ENV['title'], ENV['category'])
  puts "Created stub: #{stub_path}"
end

desc "Clean dir structure. Empty /_site"
task :clean do
  sh "rm -rf _sites/*"
end

desc "Exec jekyll"
task :build => :clean do
  sh "jekyll"
end

desc "Deploy files to server"
task :deploy => :build do
  require '_lib/Deployer.rb'
  deployer = Deployer.new
  deployer.deploy_to :live
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
