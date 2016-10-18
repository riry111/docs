#===============================#
# You can change these parameters
#===============================#
IMAGE_NAME = ENV['IMAGE_NAME']
CONTAINER_NAME = ENV['CONTAINER_NAME']
EAP_IMAGE_NAME = ENV['EAP_IMAGE_NAME']
DOCKER_REGISTRY = ENV['DOCKER_REGISTRY']

SSH_PORT = ENV['SSH_PORT']
WEB_PORT = ENV['WEB_PORT']
MANAGE_PORT = ENV['MANAGE_PORT']
NATIVE_PORT = ENV['NATIVE_PORT']


#===============================#
# Don't Edit these parameters
#===============================#
SCRIPT_DIR = "/root/DockerScripts/rhel6-ssh"
TMPFS = "/tmp/shm"

######################
# Stop Docker Container
######################
execute "Stop Docker Container" do
	action :run
	command <<-EOS
	docker stop #{CONTAINER_NAME}
	docker rm #{CONTAINER_NAME}
	EOS
	only_if "docker ps | grep #{CONTAINER_NAME}"
end

######################
# Remove Docker Container
######################
execute "Remove Docker Container" do
	action :run
	command <<-EOS
	docker rm #{CONTAINER_NAME}
	EOS
	only_if "docker ps -a | grep #{CONTAINER_NAME}"
end


######################
# Remove Docker Images
######################
execute "Remove Docker Images" do
        action :run
        command <<-EOS
	docker rmi #{DOCKER_REGISTRY}/#{EAP_IMAGE_NAME}
        docker rmi #{IMAGE_NAME} #{EAP_IMAGE_NAME}
        EOS
end


######################
# umount tmpfs dir
######################
execute "Execute mount tmpfs dir ${TMPFS}" do
	action :run
	command <<-EOS
	umount #{TMPFS}
	rm -rf #{TMPFS}
	EOS
	only_if "df | grep #{TMPFS}"
end

######################
# Remove EAP Image on Private Registry 
#  crulのリターンコートが3でエラーになるため最後に実施
######################
execute "Remove EAP Image on Private Registry" do
        action :run
        command <<-EOS
        curl -X DELETE -s https://#{DOCKER_REGISTRY}/v1/repositories/#{EAP_IMAGE_NAME}/tags/latest  -k /etc/docker/certs.d/docker-reg.example.com\:5000/ca.crt
        EOS
end
