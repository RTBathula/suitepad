module Amazonec2Helper	

	require 'rubygems'
	require 'net/ssh'

	def create_get_instance	

		AWS.config(:access_key_id  => '',
           :secret_access_key => '')

		ec2                 = AWS::EC2.new.regions['us-west-2']            # choose region here
		ami_name            = 'amzn-ami-hvm-2016.09.0.20161028-x86_64-gp2' # which AMI to search for and use
		key_pair_name       = 'suitpad'                                    # key pair name		
		security_group_name = 'launch-wizard-1'                            # security group name
		instance_type       = 't2.micro'                                   # machine instance type (must be approriate for chosen AMI)
		ssh_username        = 'ec2-user'                                   # default user name for ssh'ing

		# find the AMI based on name (memoize so only 1 api call made for image)
		image = AWS.memoize do
		  ec2.images.filter("root-device-type", "ebs").filter('name', ami_name).first
		end

		if image
		  puts "Using AMI: #{image.id}"
		else
		  raise "No image found matching #{ami_name}"
		end

		# find or create a key pair
		key_pair = ec2.key_pairs[key_pair_name]
		puts "Using keypair #{key_pair.name}, fingerprint: #{key_pair.fingerprint}"

		# find security group
		security_group = ec2.security_groups.find{|sg| sg.name == security_group_name }
		puts "Using security group: #{security_group.name}" 

		# create the instance (and launch it)
		instance = ec2.instances.create(:image_id        => image.id, 
		                                :instance_type   => instance_type,
		                                :count           => 1,
		                                :security_groups => security_group,
		                                :key_pair        => key_pair)
		puts "Launching machine ..."

		# wait until battle station is fully operational
		sleep 1 until instance.status != :pending
		puts "Launched instance #{instance.id}, status: #{instance.status}, public dns: #{instance.dns_name}, public ip: #{instance.ip_address}"
		exit 1 unless instance.status == :running

		puts "Your instance is launched successfully!"	

		return {
			:default_user => ssh_username, 
			:dns_name     => instance.dns_name, 
			:ip_address   => instance.ip_address
		}			
	end

	def create_linux_user_by(dns_name, default_user, username, password)

		puts "#{Rails.root}/suitpad.pem"		

		Net::SSH.start(dns_name, default_user, :keys => '#{Rails.root}/suitpad', :timeout => 60) do |ssh|
				
  			ssh.exec! "sudo su"
  			ssh.exec! "useradd "+username
  			ssh.exec! "passwd "+username
  			ssh.exec! password
  			ssh.exec! password
  			ssh.close
			
		end	
	end
end
