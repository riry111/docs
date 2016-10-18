#===============================#
# You can change these parameters 
#===============================#
OS_USER = ENV['OS_USER']
OS_PASSWD = ENV['OS_PASSWD']
HOME_DIR = ENV['HOME_DIR']
JBOSS_DIR = ENV['JBOSS_DIR']
ADMIN_USER = ENV['ADMIN_USER']
ADMIN_PASSWD = ENV['ADMIN_PASSWD']
JBOSS_BIND_ADDRESS = ENV['JBOSS_BIND_ADDRESS']


#===============================#
# Don't Edit these parameters
#===============================#
EAP_VERSION = "6.4.0" 
ARCHIVE_DIR = "#{HOME_DIR}/archive"
JBOSS_HOME = "#{JBOSS_DIR}/jboss-eap-#{EAP_VERSION[0,3]}"
EAP_FILE = "jboss-eap-#{EAP_VERSION}"
STIME = "5"


######################
# kill JBoss User Process	
######################
execute "kill JBoss User Process" do
        action :run
        user "root"
        command <<-EOS
        kill $(ps -u #{OS_USER} | grep -v "PID" | awk '{print $1}')
	sleep #{STIME}
        EOS
        only_if "ps -u #{OS_USER}"
end


######################
# Delete OS User for JBoss	
######################
execute "Delete OS User for JBoss" do
	action :run
	user "root"
	command <<-EOS
	/usr/sbin/userdel -r #{OS_USER}
	EOS
	only_if "id #{OS_USER}"
end

######################
# Add OS User for JBoss	
######################
execute "Add OS User for JBoss" do
	action :run
	user "root"
	command <<-EOS
	/usr/sbin/useradd #{OS_USER}
	echo #{OS_PASSWD} | /usr/bin/passwd --stdin #{OS_USER}
	mkdir #{ARCHIVE_DIR}
	chown #{OS_USER}:#{OS_USER} #{ARCHIVE_DIR}
	EOS
	not_if "id #{OS_USER}"
end

######################
# Create JBoss Install Directory
######################
execute "Create JBoss Install Directory" do
	action :run
	user "root"
	command <<-EOS
	mkdir -p #{JBOSS_DIR}
	chown #{OS_USER}:#{OS_USER} #{JBOSS_DIR}
	EOS
	not_if "ls #{JBOSS_DIR}"
end

######################
# Copy EAP Archive File
######################
remote_file "#{ARCHIVE_DIR}/#{EAP_FILE}.zip" do
	action :create
	source "./files#{ARCHIVE_DIR}/#{EAP_FILE}.zip"
	mode "644"
	owner "#{OS_USER}"
	group "#{OS_USER}"
	not_if "ls #{ARCHIVE_DIR}/#{EAP_FILE}.zip"
end

######################
# Install JBoss EAP
######################
execute "Install JBoss EAP" do
	action :run
	user "#{OS_USER}"
	cwd "#{JBOSS_DIR}"
	command <<-EOS
	rm -rf #{JBOSS_HOME}
	unzip #{ARCHIVE_DIR}/#{EAP_FILE}.zip
	#{JBOSS_HOME}/bin/add-user.sh -u #{ADMIN_USER} -p #{ADMIN_PASSWD} --silent
	rm -f #{ARCHIVE_DIR}/#{EAP_FILE}.zip
	EOS
end


######################
# Add JBoss EAP Start Command
######################
execute "Add JBoss EAP Start Command" do
	action :run
	command <<-EOS
	sed -i -e '/^\\/sbin\\/service sshd start$/a\\/sbin\\/runuser -l jboss -c "#{JBOSS_HOME}/bin/standalone.sh -c standalone.xml -b #{JBOSS_BIND_ADDRESS} -bmanagement #{JBOSS_BIND_ADDRESS}"' /usr/local/bin/init.sh
	EOS
	not_if "grep #{JBOSS_HOME}/bin/standalone.sh /usr/local/bin/init.sh"
end

