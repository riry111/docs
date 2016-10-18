#===============================#
# You can change these parameters
#===============================#
OS_USER = ENV['OS_USER']
OS_PASSWD = ENV['OS_PASSWD']
HOME_DIR = ENV['HOME_DIR']
JBOSS_DIR = ENV['JBOSS_DIR']

#===============================#
# Don't Edit these parameters
#===============================#
EAP_VERSION = "6.4.0"
EAP_PATCH_VERSION = "6.4.3"

ARCHIVE_DIR = "#{HOME_DIR}/archive"
EAP_FILE = "jboss-eap-#{EAP_VERSION}"
EAP_PATCH_FILE = "jboss-eap-#{EAP_PATCH_VERSION}-patch.zip"
JBOSS_HOME = "#{JBOSS_DIR}/jboss-eap-#{EAP_VERSION[0,3]}"

######################
# Copy EAP Patch Archive File
######################
remote_file "#{ARCHIVE_DIR}/#{EAP_PATCH_FILE}" do
	action :create
	source "./files#{ARCHIVE_DIR}/#{EAP_PATCH_FILE}"
	mode "644"
	owner "#{OS_USER}"
	group "#{OS_USER}"
	not_if "ls #{ARCHIVE_DIR}/#{EAP_PATCH_FILE}"
end

######################
# Start JBoss EAP
######################
execute "Start JBoss EAP" do
	command <<-EOS
	nohup ${JBOSS_HOME}/bin/standalone.sh -c standalone.xml 2>&1 > /dev/null &
	EOS
	not_if "ps -ef | grep java | grep -server | grep #{JBOSS_HOME}"
end

######################
# Apply JBoss EAP Patch
######################
execute "Apply JBoss EAP Patch " do
	action :run
	user "jboss"
	command <<-EOS
	#{JBOSS_HOME}/bin/jboss-cli.sh "patch apply #{ARCHIVE_DIR}/#{EAP_PATCH_FILE}" 
	EOS
	only_if "ls #{ARCHIVE_DIR}/#{EAP_PATCH_FILE}"
end

######################
# Delete JBoss EAP Patch Archive
######################
execute "Delete JBoss EAP Patch Archive" do
	action :run
	user "jboss"
	command <<-EOS
	rm -f #{ARCHIVE_DIR}/#{EAP_PATCH_FILE}
	EOS
	only_if "ls #{ARCHIVE_DIR}/#{EAP_PATCH_FILE}"
end

