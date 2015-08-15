# Eclair

Simple ssh helper for Amazon EC2

## Requirements
    
    tmux
    ~/.aws/credentials (created by AWS CLI)

## Installation

    $ gem install ecl

## Usage

    $ ecl

First execution will create ~/.eclrc file. Edit this file and run again.

## Configurations

### aws_region

AWS region to connect.

	config.aws_region = "ap-northeast-1"

### columns

Max number of columns displayed in eclair.

	$ config.columns = 4

### ssh_username 

Function to find username from image.  
Returns username of given image.  
Uses image data from [EC2::Client#describe_images](https://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/Client.html#describe_images-instance_method) API call

	config.ssh_username = lambda do |image|
	  case image.name
	  when /ubuntu/
	    "ubuntu"
	  else
	    "ec2-user"
	  end
	end

### group_by

Function to find group name from instance.  
Returns group name from instance data.
Uses instance data from [EC2::Client#describe_instances](https://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/Client.html#describe_instances-instance_method) API call.

Example)  
Group by security groups.  

	config.group_by = lambda do |instance|
	  if instance.security_groups.first
	    instance.security_groups.first.group_name
	  else
	    "no_group"
	  end
	end

Group by instance name.

	config.group_by = lambda do |instance|
	  nametag = instance.tags.find{|t| t.key == "Name"}
	  return "Noname" unless nametag
	  case nametag.value
	  when /^production/
	    "production servers"
	  when /^test/
	    "test servers"
	  end
	end

Do not group instances.
	
	config.group_by = nil


### ssh_ports
Port numbers to try ssh.  

	config.ssh_ports = [1234, 22]


### ssh_options
Extra options passed to ssh.

	config.ssh_options = "-o ConnectTimeout=1 -o StrictHostKeyChecking=no"

### ssh_hostname
Hostname to use in ssh.  
Choose from :public_dns_name, :public_ip_address, :private_dns_name, :private_ip_address
	
	config.ssh_hostname = :public_ip_address


### ssh_keys
Hash of EC2 keypair name => key_path in local.  
If your key has been already registered in ssh-agent, you don't have to configure this.

	config.ssh_keys = {
	  "keypair1" => "/path/to/key1",
	  "keypair2" => "/path/to/key2",
	}

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

