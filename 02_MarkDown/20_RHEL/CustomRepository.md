##RHEL カスタムリポジトリ作成手順
	~~~
# rhn_check
~~~
	~~~

  		# createrepo /var/www/html/repo





### [リポジトリ更新]
	# reposync -p /opt/RHEL/7.1/x86_64 -r rhel-7-server-extras-rpms 
	# reposync -p /opt/RHEL/7.1/x86_64 -r rhel-7-server-optional-rpms
	# reposync -p /opt/RHEL/7.1/x86_64 -r rhel-7-server-rpms
	# reposync -p /opt/RHEL/7.1/x86_64 -r rhel-server-7-ose-beta-rpms
	# reposync -p /opt/RHEL/7.1/x86_64 -r jb-eap-6-for-rhel-7-server-rpms
	
	
##作業実施ログ
 1. リポジトリデータのミラー　reposync　作成
 # reposync --gpgcheck -l --repoid=jb-eap-6-for-rhel-7-server-rpms \ 
           --download_path=/opt/RHEL/7.1/x86_64
	
	~~~
	
	~~~
	
	~~~
	# vi /etc/selinux/config
	
	~~~
	# mkdir -p /opt/RHEL/7.1/x86_64	
	~~~
	
	
	~~~
	~~~
