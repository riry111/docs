========================================
EAP6.4.3 Docker Image 登録用 ansibleスクリプト

Create 2015/09/25 
=========================================

[構成]
.
└── ansible-root
	├── hosts	ansible 設定対象 host 設定ファイル
	└── playbooks
		├── DockerImageRHEL6.5	RHEL6.5 コンテナイメージ作成、コンテナ起動
		├── DockerRegistryPush	EAP導入済みコンテナイメージ作成、Private Registry登録
		├── JBossEAP6.4			EAP6.4 新規インストール
		├── JBossEAP6.4.3_patch	EAP6.4.3 パッチ適用
		├── OpenJDK-1.8.0		OpenJDK−1.8.0 インストール、yum キャッシュクリア
		└── vars					playbookで利用する変数設定ファイル
		

ansible用のplaybookは、全て main.yml という名前で統一しています。
＊DockerImageRHEL6.5 と DockerRegistryPushには ansibleのdockerモジュールを利用したmain-docker.yml を格納
　なお、RHEL7.1環境では、pythonの依存関係の問題で dockerモジュールは利用できない
  https://bugzilla.redhat.com/show_bug.cgi?id=1252422

[事前準備]
	1. 次の3環境のサーバを準備
		1) ansible インストールサーバ	
		2) Docker インストールサーバ
		3) Docker Registry インストールサーバ

	2. JBoss EAP アーカイブファイルを以下に格納します
		./ansible-root/playbooks/JBossEAP6.4/files/home/jboss/archive/jboss-eap-6.4.0.zip
		./ansible-root/playbooks/JBossEAP6.4.3_patch/files/home/jboss/archive/jboss-eap-6.4.3-patch.zip
	
	3. ansible実行 サーバ root ユーザで パスフレーズ無しの RSA キーペアを作成
		# ssh-keygen -t RSA
	
	4. docker コンテナに登録する 以下のファイルに 上記3で作成した /root/.ssh/id_rsa.pub を追加する
		./ansible-root/playbooks/DockerImageRHEL6.5/files/root/DockerScripts/rhel6-ssh/authorized_keys	
	
	5. Docker image ビルド用の Dockerfile記載された rootパスワードを変更する [Default:redhat1!]
		./ansible-root/playbooks/DockerImageRHEL6.5/files/root/DockerScripts/rhel6-ssh/Dockerfile
		[変更箇所]
		===================================
		RUN echo 'root:redhat1!' |chpasswd
		===================================
	
	6. 各種playbookのパラメータを必要に応じて変更する
	   全てvar_fileで設定します。./ansible-root/vars/main.yml を必要に応じて編集してください
		[初期設定]
		===========================================================
		OS_USER: jboss					#JBoss起動 OSユーザ
		OS_PASSWD: redhat1!				#JBoss起動 OSユーザ パスワード
		HOME_DIR: /home/jboss			#JBoss起動 OSユーザ ホームディレクトリ
		JBOSS_DIR: /opt/jboss/eap		#JBoss EAP 導入ディレクトリ
		ADMIN_USER: admin				#EAP管理者ユーザ
		ADMIN_PASSWD: redhat1!			#EAP管理者パスワード
		IMAGE_NAME: rhel6.5-ssh-an		#sshd 起動用 Docker image名
		CONTAINER_NAME: rhel6.5sd-an	#JBoss EAPインストール用Dockerコンテナ名
		EAP_IMAGE_NAME: rhel6.5eap-an	#JBoss EAPインストール済みDocker image名
		DOCKER_REGISTRY: docker-reg.example.com:5000	#Private Registryのホスト名:ポート番号
		SSH_PORT: 20022		#DockerコンテナSSH(22)ポート portfoward先
		WEB_PORT: 28080		#DockerコンテナWEB(8080)ポート portfoward先
		MANAGE_PORT: 29990	#DockerコンテナMANAGE(9990)ポートportfoward先
		NATIVE_PORT: 29999	#DockerコンテナNATIVE(9999)ポートportfoward先
		JBOSS_BIND_ADDRESS: 0.0.0.0		#JBOSS EAP BINDアドレス
		TMPFS: /tmp/shm-an
		SCRIPT_DIR: /root/DockerScripts/rhel6-ssh-an
		===========================================================
	
	7. ansible実行用 hosts ファイルの設定を変更後、
		./ansible-root/hosts ファイルを /etc/ansible/hosts に上書きします。

		hostsファイルは下記の設定をしております。必要に応じて ansible_ssh_port, ansible_ssh_host の値を変更してください。
		なお、　docker は docker起動サーバ、ssh-container は JBossEAPをインストールする dockerコンテナ になります。

		[初期設定]
		===========================================================
		docker ansible_ssh_port=22 ansible_ssh_host=192.168.122.202
		ssh-container ansible_ssh_port=20022 ansible_ssh_host=192.168.122.202
		===========================================================


[環境構築]
	
	1. /root/.ssh/known_hosts より Dockerコンテナのレコードを削除します
		削除対象：dockerホスト:20022

	2. ansible 導入サーバより、ansible-playbook コマンドを 次の順番で実行する　(#root権限での実行が必要)
		なお、実行コマンドの詳細をみるには -v を 変更を行わず動作を確認するには、--check オプションを付ける
	
		1) RHEL6.5 コンテナイメージ作成、コンテナ起動
		# ansible-playbook ./ansible-root/playbooks/DockerImageRHEL6.5/main.yml

		2) OpenJDK−1.8.0 インストール、yum キャッシュクリア
		# ansible-playbook ./ansible-root/playbooks/OpenJDK-1.8.0/main.yml

		3) EAP6.4 新規インストール
		# ansible-playbook ./ansible-root/playbooks/JBossEAP6.4/main.yml

		4) EAP6.4.3 パッチ適用
		# ansible-playbook ./ansible-root/playbooks/JBossEAP6.4.3_patch/main.yml
		
		5) EAP導入済みコンテナイメージ作成、Private Registry登録
		# ansible-playbook ./ansible-root/playbooks/DockerRegistryPush/main.yml

[確認]
	1. Docker Private Registory 確認
		以下の例では、Docker Registry を https://docker-reg.example.com:5000
		image名を rhel6.5eap-an で起動した場合の例を示す
	
		1) Pushしたイメージの存在確認
		curl -s https://docker-reg.example.com:5000/v1/repositories/rhel6.5eap-an/tags  -k /etc/docker/certs.d/docker-reg.example.com\:5000/ca.crt 
		
		2) 削除用コマンド　(DockerRegistryPush では 上書き可能のため使う必要はありません)
		curl -X DELETE -s https://docker-reg.example.com:5000/v1/repositories/rhel6.5eap-an/tags/latest  -k /etc/docker/certs.d/docker-reg.example.com\:5000/ca.crt 



	2. JBoss EAP コンテナ稼働確認
		1) dockerサーバにてEAPインストール済みイメージからコンテナを起動する
		# docker run 20022:22 -p 29999:9999 -p 29990:9990 -p 28080:8080 --name eap6-an -t -d docker-reg.example.com:5000/rhel6.5eap-an

		2) ブラウザから docker:29990 にアクセスし、JBossEAPの管理者画面が起動していることを確認する

以　上


