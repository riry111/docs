USER = "jboss"
PASSWORD = "redhat1!"
HOME_DIR = "/home/jboss"
ARCHIVE_DIR = "#{HOME_DIR}/archive"
EAP_VERSION = "6.4.0"
EAP_FILE = "jboss-eap-#{EAP_VERSION}"
EAP_PATCH = "jboss-eap-6.4.3-patch.zip"
JBOSS_DIR = "/opt/jboss/eap"

# Uninstall JBoss EAP
execute "Uninstall JBoss EAP" do
	action :run
	user "root"
	command <<-EOS
	userdel -rf #{USER}
	rm -rf #{JBOSS_DIR}
	EOS
end
