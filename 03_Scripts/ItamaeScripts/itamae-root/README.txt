========================================
EAP6.4.3 Docker Image 登録用 Itamae レシピ

Create 2015/09/11 
Modify 2015/09/17 DockerImageRHEL6.5 docker run 実施時のポート番号を環境変数に保持
                  JBoss コンテナ起動時にEAPプロセスを起動するよう変更
Modify 2015/09/28 RHEL6.5ベースイメージがある場合はイメージ作成をスキップ
=========================================

[構成]
.
└── itamae-root
	└── itamae-root
		├── _env	itamaeスクリプト環境変数定義ファイル
		└── cookbooks
			├── DockerImageRHEL6.5	RHEL6.5 コンテナイメージ作成、コンテナ起動
			├── DockerRegistryPush	EAP導入済みコンテナイメージ作成、Private Registry登録
			├── JBossEAP6.4			EAP6.4 新規インストール
			├── JBossEAP6.4.3_patch	EAP6.4.3 パッチ適用
			└── OpenJDK-1.8.0		OpenJDK−1.8.0 インストール、yum キャッシュクリア

itamae用のレシピファイルは、全て default.rb という名前で統一しています。


[事前準備]
	1. 次の3環境のサーバを準備
		1) Itamae (Ruby) インストールサーバ	
		2) Docker インストールサーバ
		3) Docker Registry インストールサーバ

	2. JBoss EAP アーカイブファイルを以下に格納します
		./itamae-root/cookbooks/JBossEAP6.4/files/home/jboss/archive/jboss-eap-6.4.0.zip
		./itamae-root/cookbooks/JBossEAP6.4.3_patch/files/home/jboss/archive/jboss-eap-6.4.3-patch.zip
	
	3. itamae サーバ root ユーザで パスフレーズ無しの RSA キーペアを作成
		# ssh-keygen -t RSA
	
	4. docker コンテナに登録する 以下のファイルに 上記3で作成した /root/.ssh/id_rsa.pub を追加する
		./itamae-root/cookbooks/DockerImageRHEL6.5/files/root/DockerScripts/rhel6-ssh/authorized_keys	
	
        5. docker サーバ rootユーザーの authorized_keys に 上記3 で作成した公開鍵を追加する (次のコマンドを実行 ${dockerサーバホスト名} は環境に合わせて変更)
		# ssh-copy-id -i ~/.ssh/id_rsa.pub root@${dockeサーバホスト名}

	6. Docker image ビルド用の Dockerfile記載された rootパスワードを変更する [Default:redhat1!]
		./itamae-root/cookbooks/DockerImageRHEL6.5/files/root/DockerScripts/rhel6-ssh/Dockerfile
		[変更箇所]
		===================================
		RUN echo 'root:redhat1!' |chpasswd
		===================================
	
	7. 各種レシピファイルのパラメータを必要に応じて変更する
	   全て環境変数で設定します。./itamae-root/_env を必要に応じて編集してください
		[初期設定]
		===========================================================
		export OS_USER="jboss"			#JBoss起動 OSユーザ
		export OS_PASSWD="redhat1!"		#JBoss起動 OSユーザ パスワード
		export HOME_DIR="/home/jboss"		#JBoss起動 OSユーザ ホームディレクトリ
		export JBOSS_DIR="/opt/jboss/eap"	#JBoss EAP 導入ディレクトリ
		export ADMIN_USER="admin"		#EAP管理者ユーザ
		export ADMIN_PASSWD="redhat1!"		#EAP管理者パスワード	
		export IMAGE_NAME="rhel6.5-ssh"		#sshd 起動用 Docker image名
		export CONTAINER_NAME="rhel6.5sd"	#JBoss EAPインストール用Dockerコンテナ名
		export EAP_IMAGE_NAME="rhel6.5eap"	#JBoss EAPインストール済みDocker image名
		export DOCKER_REGISTRY="docker-reg.example.com:5000"	#Private Registryのホスト名:ポート番号
		export SSH_PORT="10022"			#DockerコンテナSSH(22)ポート portfoward先
		export WEB_PORT="8080"			#DockerコンテナWEB(8080)ポート portfoward先
		export MANAGE_PORT="9990"		#DockerコンテナMANAGE(9990)ポートportfoward先
		export NATIVE_PORT="9999"		#DockerコンテナNATIVE(9999)ポートportfoward先
		export JBOSS_BIND_ADDRESS="0.0.0.0"	#JBOSS EAP BINDアドレス
		===========================================================



[環境構築]
	1. 環境変数ファイルを読み込みます
		# . ./itamae-root/_env
	
	2. /root/.ssh/known_hosts より Dockerコンテナのレコードを削除します
		削除対象：dockerホスト:10022

	3. itame 導入サーバより、itame コマンドを 次の順番で実行する　(#root権限での実行が必要)
		なお、ログレベルをあげるには --log-level=debug  変更を行わず動作を確認するには、--dry-run オプションを付ける
	
		1) RHEL6.5 コンテナイメージ作成、コンテナ起動
		# itamae ssh --host docker --user root  ./itamae-root/cookbooks/DockerImageRHEL6.5/default.rb

		2) OpenJDK−1.8.0 インストール、yum キャッシュクリア
		# itamae ssh --host docker -p 10022 --user root ./itamae-root/cookbooks/OpenJDK-1.8.0/default.rb 

		3) EAP6.4 新規インストール
		# itamae ssh --host docker -p 10022 --user root ./itamae-root/cookbooks/JBossEAP6.4/default.rb 

		4) EAP6.4.3 パッチ適用
		# itamae ssh --host docker -p 10022 --user root ./itamae-root/cookbooks/JBossEAP6.4.3_patch/default.rb 
		
		5) EAP導入済みコンテナイメージ作成、Private Registry登録
		# itamae ssh --host docker --user root ./itamae-root/cookbooks/DockerRegistryPush/default.rb

[確認]
	1. Docker Private Registory 確認
		以下の例では、Docker Registry を https://docker-reg.example.com:5000
		image名を rhel6.5eap で起動した場合の例を示す
	
		1) Pushしたイメージの存在確認
		curl -s https://docker-reg.example.com:5000/v1/repositories/rhel6.5eap/tags  -k /etc/docker/certs.d/docker-reg.example.com\:5000/ca.crt 
		
		2) 削除用コマンド　(DockerRegistryPush では 上書き可能のため使う必要はありません)
		curl -X DELETE -s https://docker-reg.example.com:5000/v1/repositories/rhel6.5eap/tags/latest  -k /etc/docker/certs.d/docker-reg.example.com\:5000/ca.crt 



	2. JBoss EAP コンテナ稼働確認
		1) dockerサーバにてEAPインストール済みイメージからコンテナを起動する
		# docker run --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 10022:22 -p 19999:9999 -p 19990:9990 -p 18080:8080 --name eap6 -t -d docker-reg.example.com:5000/rhel6.5eap

		2) ブラウザから docker:19990 にアクセスし、JBossEAPの管理者画面が起動していることを確認する

以　上


