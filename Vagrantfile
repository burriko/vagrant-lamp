# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # Set box configuration
  config.vm.box = "precise32"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"

  # Assign this VM to a host-only network IP, allowing you to access it via the IP.
  config.vm.network :hostonly, "33.33.33.10"

  config.vm.forward_port 80, 8080

  config.vm.share_folder "careers", "/vagrant/public/local.dev", "E:\\Dropbox\\NclWork\\www"
  config.vm.share_folder "db_dumps", "/vagrant/db_dumps", "E:\\db dumps"

  # Enable provisioning with chef solo, specifying a cookbooks path (relative
  # to this Vagrantfile), and adding some recipes and/or roles.
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.data_bags_path = "data_bags"
    chef.add_recipe "vagrant_main"

    chef.json.merge!({
      "mysql" => {
        "server_root_password" => "vagrant",
        "server_debian_password" => "vagrant",
        "server_repl_password" => "vagrant",
        "bind_address"=> "127.0.0.1"
      },
      "oh_my_zsh" => {
        :users => [
          {
            :login => 'vagrant',
            :theme => 'blinks',
            :plugins => ['git', 'gem']
          }
        ]
      },
      "node" => {
        "revision" => "v0.10.18"
      }
    })
  end
end
