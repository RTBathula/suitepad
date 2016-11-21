class Amazonec2Controller < ApplicationController
	require 'json'
	include ApplicationController::Amazonec2Helper

	def get_ec2instance
		username = params[:username]
		password = params[:password]

		if !username || !password
			return render :text => 'username and password are required', :status => '404'
		end		
		
		resp =create_get_instance()
		resp = resp.to_json

		#create_linux_user_by(resp['dns_name'], resp['default_user'], username, password)	

	    msg = {
	    	:result             => 'Your have successfully created AWS instance!', 
	    	:instance_ipaddress => resp['dns_name']
	    }
		render :json => resp,:status => '200'
	end
end
