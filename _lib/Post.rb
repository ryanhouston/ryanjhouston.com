require 'date'

class Post
  attr_accessor :extension
  attr_reader :title
  attr_reader :category

  def self.create_stub(post_title, category)
    post = Post.new(post_title, category)
    post.write_stub
  end

  def initialize(post_title, category)
    @category =  category || ''
    raise ArguementError, 'Post title must be provided' if post_title.nil?
    @title = post_title
    @extension = 'markdown'
  end

  def directory
    @path ||= "/#{@category}/_posts/"
  end

  def basename
    post_slugged = @title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    date_stamp = Date.today.to_s
    post_filetitle = "#{date_stamp}-#{post_slugged}"
  end

  def fullpath
    @fullpath ||= directory + basename + "." + @extension
  end

  def write_stub
    stub_path = Dir.pwd + fullpath
    File.open(stub_path, "w") do |stub|
      stub.write(front_matter)
    end
    stub_path
  end

  def front_matter
    content = "---\n" +
            "title: #{title}\n" +
            "layout: #{layout}\n"
    if category
      content += "category: #{category}\n"
    end
    content += "date: " + Date.today.to_s + "\n"
    content += "disqus-id: #{basename}\n"
    content += "---\n"
    content
  end

  def layout
    layout ||= 'post'
  end

end
