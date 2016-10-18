package "java-1.8.0-openjdk.x86_64"
package "java-1.8.0-openjdk-devel.x86_64"


######################
# Delete yum cache
######################
execute "Delete yum cache" do
        action :run
        command <<-EOS
	yum clean all
        EOS
end
