#===============================#
# You can change these parameters
#===============================#
IMAGE_NAME = ENV['IMAGE_NAME']
CONTAINER_NAME = ENV['CONTAINER_NAME']
SSH_PORT = ENV['SSH_PORT']
WEB_PORT = ENV['WEB_PORT']
MANAGE_PORT = ENV['MANAGE_PORT']
NATIVE_PORT = ENV['NATIVE_PORT']


#===============================#
# Don't Edit these parameters
#===============================#
SCRIPT_DIR = "/root/DockerScripts/rhel6-ssh"
TMPFS = "/tmp/shm"
STIME = "5"

######################
# Create Docker Scripts  Directory
######################
execute "Create Docker Scripts Directory" do
	action :run
	command <<-EOS
	mkdir -p #{SCRIPT_DIR}
	EOS
	not_if "ls #{SCRIPT_DIR}"
end

######################
# Copy Files for docker build 
######################
%w(Dockerfile init.sh authorized_keys).each do |file|
	remote_file "#{SCRIPT_DIR}/#{file}" do
		action :create
		source "./files#{SCRIPT_DIR}/#{file}"
		not_if "ls #{SCRIPT_DIR}/#{file}"
	end
end

######################
# Create Docker Image
######################
execute "Create Docker Image" do
	action :run
	cwd "#{SCRIPT_DIR}"
	command <<-EOS
	docker build -t #{IMAGE_NAME} .
	EOS
	not_if "docker images | grep \"^#{IMAGE_NAME}\s\""
end

######################
# mount tmpfs dir
######################
execute "Execute mount tmpfs dir ${TMPFS}" do
	action :run
	command <<-EOS
	mkdir -p #{TMPFS}
	mount -t tmpfs -o size=1024 swap #{TMPFS}
	EOS
	not_if "df | grep \"#{TMPFS}$\""
end

######################
# Execute docker run
######################
execute "Execute docker run  #{CONTAINER_NAME}" do
	action :run
	command <<-EOS
	docker run --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v #{TMPFS}/:/dev/shm/ -p #{SSH_PORT}:22 -p #{NATIVE_PORT}:9999 -p #{MANAGE_PORT}:9990 -p #{WEB_PORT}:8080 --name #{CONTAINER_NAME} -t -d #{IMAGE_NAME}
	sleep #{STIME}
	EOS
	not_if "docker ps -a | grep \"#{CONTAINER_NAME}\s\""
end


######################
# Start docker process
######################
execute "Start docker process  #{CONTAINER_NAME}" do
	command <<-EOS
	docker start #{CONTAINER_NAME}
	sleep #{STIME}
	EOS
	not_if "docker ps | grep \"#{CONTAINER_NAME}\s\""
end
