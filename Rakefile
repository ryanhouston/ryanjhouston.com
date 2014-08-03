require 'rake'
require 'tmpdir'
require 'jekyll'


desc "Create stub for new post"
task :new_post do
  require '_lib/Post.rb'
  stub_path = Post.create_stub(ENV['title'], ENV['category'])
  puts "Created stub: #{stub_path}"
end

namespace :server do
  desc "Start local server"
  task :start do
    sh "jekyll serve"
  end

  desc "Start local server with auto-update"
  task :auto do
    sh "jekyll serve --watch"
  end
end


# :generate and :publish tasks lifted from:
# http://blog.nitrous.io/2013/08/30/using-jekyll-plugins-on-github-pages.html

desc "Generate blog files"
task :generate do
  Jekyll::Site.new(Jekyll.configuration({
    "source"      => ".",
    "destination" => "_site"
  })).process
end


desc "Generate and publish blog to gh-pages"
task :publish => [:generate] do
  Dir.mktmpdir do |tmp|
    system "mv _site/* #{tmp}"
    system "git checkout -B gh-pages"
    system "rm -rf *"
    system "mv #{tmp}/* ."
    message = "Site updated at #{Time.now.utc}"
    system "git add ."
    system "git commit -am #{message.shellescape}"
    system "git push origin gh-pages --force"
    system "git checkout master"
    system "echo done"
  end
end

task :default => 'generate'

