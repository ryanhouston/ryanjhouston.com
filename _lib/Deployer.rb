require 'yaml'

class Deployer

  def load_config(env)
    config = YAML::load(File.open(File.dirname(__FILE__) + '/../_config.yml'))

    env = env.to_s
    @hostname = config['deploy'][env]['hostname']
    @username = config['deploy'][env]['username']
    @password = config['deploy'][env]['password']
    @repo_path = config['deploy'][env]['repo_path']
  end

  def deploy_to(env)
    load_config env
puts "ssh://#{@username}:#{@password}@#{@hostname}#{@repo_path}"
  end

end
