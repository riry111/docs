#===============================#
# You can change these parameters
#===============================#
CONTAINER_NAME = ENV['CONTAINER_NAME']
EAP_IMAGE_NAME = ENV['EAP_IMAGE_NAME']
DOCKER_REGISTRY = ENV['DOCKER_REGISTRY']


######################
# STOP EAP Docker Container
######################
execute "Stop Docker Container  #{CONTAINER_NAME}" do
	action :run
	command <<-EOS
	docker stop #{CONTAINER_NAME}
	EOS
	only_if "docker ps | grep \"#{CONTAINER_NAME}\s\""
end

######################
# Create EAP Docker Image
######################
execute "Create EAP Docker Image #{EAP_IMAGE_NAME}" do
	action :run
	command <<-EOS
	docker commit #{CONTAINER_NAME} #{EAP_IMAGE_NAME}
	EOS
end

######################
# Add tag to EAP Docker Image
######################
execute "Execute Add docker tag to EAP Docker Image" do
	action :run
	command <<-EOS
	docker tag -f #{EAP_IMAGE_NAME} #{DOCKER_REGISTRY}/#{EAP_IMAGE_NAME}
	EOS
end

######################
# Push Image to Registry
######################
execute "Execute push image to Registry" do
	action :run
	command <<-EOS
	docker push #{DOCKER_REGISTRY}/#{EAP_IMAGE_NAME}
	EOS
end

