eclair [![RubyGems total downloads]][RubyGems]
========
![A video showing how Eclair works]

Simple ssh helper for Amazon EC2

```bash
gem install ecl
```

### Requirements
- tmux > 2.0
- Properly configured `~/.aws/credentials`

### Usage
```console
$ ecl
```
First execution will create `~/.ecl/config.rb` file. Edit this file and run again.

&nbsp;

Configurations
--------
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
Function to find username from image. Returns username of given image. Uses
image data from [EC2::Client#describe_images] API call.

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
Function to find group name from instance. Returns group name from instance
data. Uses instance data from [EC2::Client#describe_instances] API call.

You can group instances by security groups with this config:
```ruby
config.group_by = lambda do |instance|
  if instance.security_groups.first
    instance.security_groups.first.group_name
  else
    "no_group"
  end
end
```

Grouping by instance name is also possible:
```ruby
config.group_by = lambda do |instance|
  case instance.name
  when /^production/
    "production servers"
  when /^test/
    "test servers"
  end
end
```

You can disable grouping by assigning nil:
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
Hostname to use in ssh. Choose from `:public_dns_name`, `:public_ip_address`,
`:private_dns_name`, `:private_ip_address`
```ruby
config.ssh_hostname = :public_ip_address
```

### ssh_keys
Hash of EC2 keypair name => key_path in local. If your key has been already
registered in ssh-agent, you don't have to configure this.
```ruby
config.ssh_keys = {
  "keypair1" => "/path/to/key1",
  "keypair2" => "/path/to/key2",
}
```

### filter by vpc_id
Boolean variable. If ture use VPC_ID Environment variable for filtering EC2 instances.
```ruby
config.use_vpc_id_env = true
```

Example VPC_ID variable:
```
VPC_ID=vpc-12345678901234567
```

&nbsp;

Install from Source
--------
If you want to use the latest functionalities, install Eclair from the source.
```bash
# Headers of ncursesw is required to build Eclair in GNU/Linux
sudo apt-get install libncursesw5-dev   # Debian, Ubuntu, etc
sudo yum install libncursesw5-devel     # CentOS, etc

# Build latest eclair gem
gem build eclair.gemspec

# Install eclair into your system
gem install ecl-3.0.1.gem
```

&nbsp;

--------

*eclair* is primarily distributed under the terms of the [MIT License].

[RubyGems]: https://rubygems.org/gems/ecl
[RubyGems total downloads]: https://badgen.net/rubygems/dt/ecl
[A video showing how Eclair works]: out.gif
[EC2::Client#describe_images]: https://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/Client.html#describe_images-instance_method
[EC2::Client#describe_instances]: https://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/Client.html#describe_instances-instance_method
[MIT License]: LICENSE
