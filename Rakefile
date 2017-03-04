require 'rake'
require 'tmpdir'
require 'jekyll'

$LOAD_PATH.unshift('_lib')

desc "Create stub for new post"
task :new_post do
  require 'post'
  stub_path = Post.create_stub(ENV['title'], ENV['category'])
  puts "Created stub: #{stub_path}"
end

namespace :server do
  desc "Start local server"
  task :start do
    sh "bundle exec jekyll serve"
  end
end

desc "Generate blog files"
task :generate do
  sh "bundle exec jekyll build"
end

task :default => 'generate'

