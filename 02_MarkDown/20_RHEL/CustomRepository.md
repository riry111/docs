##RHEL カスタムリポジトリ作成手順###[サーバ側の作業]1. ダウンロードに使用するサーバを準備します  - 対象とするRHEL(バージョン、アーキテクチャ)がインストールされていること  - HDDに十分な空き容量があること(チャンネル数によりますが10GBもあれば十分)  - rhn_registerによるRHNクラシックへの登録が完了していること 
	~~~
# rhn_check# echo $?0
~~~  - ダウンロードしたいチャンネルの購読設定を終えていること	
	~~~    # rhn-channel -l    rhel-x86_64-server-6    rhel-x86_64-server-optional-6    ...    => (必要なチャンネルが表示されていることを確認)~~~
2. ダウンロードする場所(ディレクトリ)を用意します  (例)		# mkdir -p /var/www/html/repo3. 最新パッケージのダウンロード  		# reposync -n -l -p /var/www/html/repo  		(購読している全チャンネルが対象です)4. リポジトリの作成  		
  		# createrepo /var/www/html/repo5. 作成したリポジトリを何らかの方法で公開する(nfs/http/ftp等)	~~~(例:httpdで公開する場合)# service httpd start# (必要に応じてfirewallの調整なども実施)~~~
###[クライアント側の作業]1. リポジトリ指定ファイルを作成して、/etc/yum.repos.d/ へ保管  (例) /etc/yum.repos.d/rhel6-x86_64.repo というファイルを作成(<server>は、上記のリポジトリを公開するサーバ)	~~~===== ここから ======[rhel6-x86_64]name=RHEL6 x86_64 repositorybaseurl=http://<server>/repogpgcheck=0enabled=1===== ここまで ======~~~2. キャッシュ等をクリア	~~~# yum clean all~~~
3. アップデート
		# yum --noplugins update  		(確認だけならば y/n に対してnを入力してキャンセル)以上になります。* 同様の手順について、ナレッジベースで公開されている情報もありますので、適宜参照して下さい：		https://access.redhat.com/site/ja/solutions/257763		https://access.redhat.com/site/solutions/9892* パッケージをダウンロードするのではなく、新しいバージョンのインストールDVDをそのままリポジトリとして利用する方法もあります：		https://access.redhat.com/site/solutions/40539


### [リポジトリ更新]
	# reposync -p /opt/RHEL/7.1/x86_64 -r rhel-7-server-extras-rpms 
	# reposync -p /opt/RHEL/7.1/x86_64 -r rhel-7-server-optional-rpms
	# reposync -p /opt/RHEL/7.1/x86_64 -r rhel-7-server-rpms
	# reposync -p /opt/RHEL/7.1/x86_64 -r rhel-server-7-ose-beta-rpms
	# reposync -p /opt/RHEL/7.1/x86_64 -r jb-eap-6-for-rhel-7-server-rpms
	
	
##作業実施ログ
 1. リポジトリデータのミラー　reposync　作成  [URL] <http://access.redhat.com/solutions/23016>	~~~  # yum -y install yum-utils createrepo # reposync --gpgcheck -l --repoid=channel-id for example: # reposync --gpgcheck -l --repoid=rhel-7-server-rpms \           --download_path=/root/download/rpm # reposync --gpgcheck -l --repoid=rhel-7-server-optional-rpms \           --download_path=/root/download/rpm # reposync --gpgcheck -l --repoid=rhel-server-7-ose-beta-rpms \           --download_path=/root/download/rpm
 # reposync --gpgcheck -l --repoid=jb-eap-6-for-rhel-7-server-rpms \ 
           --download_path=/opt/RHEL/7.1/x86_64	~~~
	2. reposyncでダウンロードしたrpmのリポジトリを作成	~~~    # cd /var/www/html/<download directory>    # createrepo -v /root/download/rpm~~~3. リポジトリを http で公開	[公開URL] http://192.168.172.201/RHEL/7.1/x86_64/	1)httpdのインストール・起動	
	~~~	# yum install httpd	# systemctl start httpd	# systemctl enable httpd	~~~			2) 80番ポートの公開
	
	~~~	# firewall-cmd --zone=public --add-port=80/tcp --permanent	# firewall-cmd --reload	~~~
		3) SELINUX モード変更	
	~~~
	# vi /etc/selinux/config	SELINUX=disabled	~~~
		4) リポジトリを　/opt 以下に移動	
	~~~
	# mkdir -p /opt/RHEL/7.1/x86_64		# mv /root/download/rpms/* /opt/RHEL/7.1/x86_64
	~~~	
		5) httpd 公開コンテンツとして symlink 作成
	
	~~~	# cd /var/www/html	# ln -s /opt/RHEL/7.1/x86_64 .	~~~4. 各クライアント側の設定	
	~~~# vi /etc/yum.repo.d/rhn-repo01-mirror.repo=============	[rhel-x86_64-server-7-repo01]	name=Red Hat Enterprise Linux Server (v. 7.1 for 64-bit x86_64)	baseurl=http://192.168.172.200/RHEL/7.1/x86_64/	enabled=0	gpgcheck=0	enabled=1	gpgcheck=0=============	~~~
以 上