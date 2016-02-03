require 'fileutils'
Vagrant.configure(2) do |config|
  config.vm.box = "codeguard/codeguard"
  config.vm.box_url = "https://cg-meta.s3.amazonaws.com/vagrant/codeguard.box?Signature=9cyhnN1c9WkkysSKmN%2FBfSOf3aw%3D&Expires=1464209192&AWSAccessKeyId=AKIAIKWZKWD2J46TI4TQ"

  # Required for NFS to work, pick any local IP
  config.vm.network :private_network, ip: '192.168.50.50'
  # Use NFS for shared folders for better performance
  config.vm.synced_folder ".", "/home/vagrant/work", nfs: true

  config.ssh.password = "vagrant"

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    cd work && bundle install
  SHELL

  # Redis Install
  config.vm.provision "file", source: "vagrantconfig/redis.conf", destination: "/tmp/redis.conf"
  config.vm.provision "file", source: "vagrantconfig/redis.init.d", destination: "/tmp/redis.init.d"
  config.vm.provision :shell, :path => "vagrantconfig/init_redis.sh"

  config.vm.provider "virtualbox" do |v|
    host = RbConfig::CONFIG['host_os']

    # Give VM 1/4 system memory & access to all cpu cores on the host
    if host =~ /darwin/
      cpus = `sysctl -n hw.ncpu`.to_i
      # sysctl returns Bytes and we need to convert to MB
      mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024 / 4
    elsif host =~ /linux/
      cpus = `nproc`.to_i
      # meminfo shows KB and we need to convert to MB
      mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 / 4
    else # sorry Windows folks, I can't help you
      cpus = 2
      mem = 1024
    end

    v.customize ["modifyvm", :id, "--memory", mem]
    v.customize ["modifyvm", :id, "--cpus", cpus]
  end
end
