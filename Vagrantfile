# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.

  config.vm.define "ubuntu14", primary: true do |ubuntu14|
    ubuntu14.vm.box = "ubuntu/trusty64"
    ubuntu14.vm.network :forwarded_port, guest: 80, host: 8014 # Passenger Webserver
    config.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y apache2 libapache2-mod-fastcgi php5 php5-fpm links2
      a2enmod actions fastcgi alias rewrite
      service apache2 restart
    SHELL
  end

  config.vm.define "ubuntu16", primary: true do |ubuntu16|
    ubuntu16.vm.box = "ubuntu/xenial64"
    ubuntu16.vm.network :forwarded_port, guest: 80, host: 8016 # Passenger Webserver
    config.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y apache2 libapache2-mod-fastcgi php7.0 php7.0-fpm links2
      a2enmod actions fastcgi alias rewrite
      service apache2 restart
    SHELL
  end
end
