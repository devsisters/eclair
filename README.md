# Eclair

![eclair gif](out.gif)

Simple ssh helper for Amazon EC2

## Requirements

```
tmux
~/.aws/credentials (created by AWS CLI)
```

## Installation

```console
$ gem install ecl
```

### Install from Source

To use the latest functionality use:
(Note: Backwards compatibility is not supported)

```console
$ gem build eclair.gemspec
  Successfully built RubyGem
  Name: ecl

$ gem install ecl-3.0.0.pre.alpha1.gem
Successfully installed ecl-3.0.0.pre.alpha1
Parsing documentation for ecl-3.0.0.pre.alpha1
Done installing documentation for ecl after 0 seconds
1 gem installed
```

## Usage

```console
$ ecl
```

First execution will create `~/.ecl/config.rb` file. Edit this file and run again.

## Configurations

### aws_region

AWS region to connect.

```ruby
config.aws_region = "ap-northeast-1"
```

### columns

Max number of columns displayed in eclair.

```ruby
config.columns = 4
```

### ssh_username

Function to find username from image.
Returns username of given image.
Uses image data from [EC2::Client#describe_images](https://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/Client.html#describe_images-instance_method) API call

```ruby
config.ssh_username = lambda do |image|
  case image.name
  when /ubuntu/
    "ubuntu"
  else
    "ec2-user"
  end
end
```

### group_by

Function to find group name from instance.
Returns group name from instance data.
Uses instance data from [EC2::Client#describe_instances](https://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/Client.html#describe_instances-instance_method) API call.

Example)
Group by security groups.

```ruby
config.group_by = lambda do |instance|
  if instance.security_groups.first
    instance.security_groups.first.group_name
  else
    "no_group"
  end
end
```

Group by instance name.

```ruby
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
```

Do not group instances.

```ruby
config.group_by = nil
```

### ssh_ports
Port numbers to try ssh.

```ruby
config.ssh_ports = [1234, 22]
```

### ssh_options
Extra options passed to ssh.

```ruby
config.ssh_options = "-o ConnectTimeout=1 -o StrictHostKeyChecking=no"
```

### ssh_hostname
Hostname to use in ssh.
Choose from :public_dns_name, :public_ip_address, :private_dns_name, :private_ip_address

```ruby
config.ssh_hostname = :public_ip_address
```

### ssh_keys
Hash of EC2 keypair name => key_path in local.
If your key has been already registered in ssh-agent, you don't have to configure this.

```ruby
config.ssh_keys = {
  "keypair1" => "/path/to/key1",
  "keypair2" => "/path/to/key2",
}
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

