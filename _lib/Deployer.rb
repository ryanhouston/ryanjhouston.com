require 'yaml'

class Deployer

  def load_config(env)
    config = YAML::load(File.open(File.dirname(__FILE__) + '/../_config.yml'))

    env = env.to_s
    @hostname = config['deploy'][env]['hostname']
    @username = config['deploy'][env]['username']
    @dest_path = config['deploy'][env]['dest_path']
  end

  def deploy_to(env)
    load_config env
    puts "Deploying site to #{env} environment"

    site_dir = File.dirname(__FILE__) + '/../_site/';
    cmd = "rsync -avz --delete #{site_dir} #{@username}@#{@hostname}:#{@dest_path}"
    puts cmd
    `#{cmd}`
  end

end
