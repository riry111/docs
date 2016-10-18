## Private Docker Registry 

		
* レジストリへのアクセスは **HTTP** と **HTTPS** の２通りある。
 HTTPを利用するためには**/etc/sysconfig/docker**ファイルに次の設定が必要となる。

	~~~
INSECURE_REGISTRY='--insecure-registry reghost.example.com:5000'
~~~

	docker-registryサービスをHTTPSで起動するには、証明書の指定 **--certfile** と 秘密鍵の指定 **--keyfile**オプションが必要となる。
	
	以下では、HTTPSでdocker-registryサービスを起動する例を示す。
なお、、docker registryのFQDNを **docker-reg.example.com** デフォルトの5000ポートで起動する。


## Docker Registry構築手順

* 仮想サーバの準備 (既存のkvmイメージより複製)

		# virt-clone --original rhel7-min --name docker-reg --file /var/lib/libvirt/images/docker-reg.qcow2
		# virsh start docker-reg

* docker-reg の IPアドレスを確認

	~~~
1)MAC アドレスを確認
# virsh domiflist docker-reg
インターフェース 種類     ソース  モデル   MAC
-------------------------------------------------------
vnet3      network    default    rtl8139     52:54:00:06:0e:9d
2) ARPテーブルよりIPアドレスを確認
# arp -e | grep "52:54:00:06:0e:9d"
cicd02                   ether   52:54:00:06:0e:9d   C                     virbr0
~~~


* SSH で docker-reg に接続しホスト名を変更

		# ssh docker-reg
		# nmcli general hostname docker-reg
		
* サブスクリプションを登録

		# subscription-manager register --username=<ID> --password=<Passwd> --name 
		# subscription-manager attach --pool 8a85f98144844aff014488d058bf15be
		
### Docker registry用のサーバにログインしてリポジトリを構築

1. インストールに必要なリポジトリ **rhel-7-server-rpms** **rhel7-server-extras-rpms** **rhel-7-server-optional-rpms** を有効にする

	~~~
[root@docker-reg ~]# subscription-manager repos --disable='*' \
						--enable=rhel-7-server-rpms \
						--enable=rhel-7-server-extras-rpms \
						--enable=rhel-7-server-optional-rpms
~~~
2. docker-registry の RPMをインストール

	~~~
[root@docker-reg ~]# yum install -y docker-registry
~~~
3. 自己署名の証明書を作成

	3.1 openssl でプライベートキーを生成する
	
	~~~
[root@docker-reg ~]# openssl genrsa -out /etc/pki/tls/private/self.key 1024
Generating RSA private key, 1024 bit long modulus
..........++++++
...........++++++
e is 65537 (0x10001)
~~~

	3.2 作成したプライベートキーを利用して自己署名した証明書を作成する
	
	~~~
[root@docker-reg ~]# openssl req -new -key /etc/pki/tls/private/self.key -x509 -out /etc/pki/tls/certs/self.crt
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:JP
State or Province Name (full name) []:Osaka
Locality Name (eg, city) [Default City]:Osaka-city
Organization Name (eg, company) [Default Company Ltd]:Red Hat KK
Organizational Unit Name (eg, section) []:Service
Common Name (eg, your name or your server's hostname) []:docker-reg.example.com
Email Address []:mamurai@redhat.com
~~~

	3.3 **docker-registry** の設定ファイル**/etc/systemd/system/docker-registry.service**に作成した秘密鍵と証明書を設定する
	
	~~~
[root@docker-reg ~]# vi /etc/systemd/system/docker-registry.service 
[root@docker-reg ~]# diff /usr/lib/systemd/system/docker-registry.service  /etc/systemd/system/docker-registry.service 
9c9,10
< ExecStart=/usr/bin/gunicorn --access-logfile - --max-requests 100 --graceful-timeout 3600 -t 3600 -k gevent -b ${REGISTRY_ADDRESS}:${REGISTRY_PORT} -w $GUNICORN_WORKERS docker_registry.wsgi:application
---
> ExecStart=/usr/bin/gunicorn --certfile /etc/pki/tls/certs/self.crt --keyfile /etc/pki/tls/private/self.key --access-logfile - --debug --max-requests 100 --graceful-timeout 3600 -t 3600 -k gevent -b ${REGISTRY_ADDRESS}:${REGISTRY_PORT} -w $GUNICORN_WORKERS docker_registry.wsgi:application
~~~
4. **docker-registry** サービスを起動

	4.1 **docker-registry**サービスの有効化
	
	~~~
[root@docker-reg ~]# systemctl enable docker-registry 
ln -s '/etc/systemd/system/docker-registry.service' '/etc/systemd/system/multi-user.target.wants/docker-registry.service'
~~~
	4.2  **docker-registry**サービスの起動
	
	~~~
[root@docker-reg ~]# systemctl start docker-registry
[root@docker-reg ~]# systemctl status docker-registry
docker-registry.service - Registry server for Docker
   Loaded: loaded (/etc/systemd/system/docker-registry.service; enabled)
   Active: active (running) since 水 2015-09-09 19:37:11 JST; 5s ago
 Main PID: 2650 (gunicorn)
   CGroup: /system.slice/docker-registry.service
           ├─2650 /usr/bin/python /usr/bin/gunicorn --certfile /etc/pki/tls/certs/self.crt --keyfile /etc/pki/tls/pri...
~~~   
	4.3 5000番ポートへのアクセス許可
		
	~~~
[root@docker-reg ~]# firewall-cmd --zone=public --add-port=5000/tcp
[root@docker-reg ~]# firewall-cmd --zone=public --add-port=5000/tcp --permanent
~~~

### dockerサーバ側設定


1. docker サーバから docker-registryサーバの証明書を取得する

	~~~
[root@docker ~]# mkdir /etc/docker/certs.d/docker-reg.example.com:5000/
[root@docker ~]# scp docker-reg.example.com:/etc/pki/tls/certs/self.crt /etc/docker/certs.d/docker-reg.example.com\:5000/ca.crt
~~~

2. servera の rhel7-ssh イメージにプライベートリポジトリのタグ付けをする

	~~~
[root@docker ~]# docker tag rhel7-ssh  docker-reg.example.com:5000/rhel7-ssh[root@docker ~]# docker imagesREPOSITORY                              TAG                 IMAGE ID            CREATED             VIRTUAL SIZErhel7-ssh                               latest              053cdd6a08e7        26 hours ago        446.3 MBdocker-reg.example.com:5000/rhel7-ssh   latest              053cdd6a08e7        26 hours ago        446.3 MB
~~~


3. プライベートリポジトリへのイメージのpushを実行

	~~~
[root@docker ~]# docker push docker-reg.example.com:5000/rhel7-ssh
The push refers to a repository [docker-reg.example.com:5000/rhel7-ssh] (len: 1)
Sending image list
Pushing repository docker-reg.example.com:5000/rhel7-ssh (1 tags)
275be1d3d070: Image successfully pushed 
・・・
053cdd6a08e7: Image successfully pushed 
Pushing tag for rev [053cdd6a08e7] on {https://docker-reg.example.com:5000/v1/repositories/rhel7-ssh/tags/latest}
~~~

4. 確認のため、ローカルの　docker image を削除後　registry上のイメージから起動する事を確認

	4.1 ローカルイメージを削除
	
	~~~
[root@docker ~]# docker rmi 053cdd6a08e7Untagged: docker-reg.example.com:5000/rhel7-ssh:latestDeleted: 053cdd6a08e75bf0f1c573df082c0768df80417242322737b6876227042c5667
~~~
	4.2 docker registry上のイメージを指定して コンテナを起動する
	
	~~~
[root@docker ~]# docker run --name rhel7 -p 20022:22 -p 29999:9999 -p 29990:9990 -p 28080:8080 -d -t docker-reg.example.com:5000/rhel7-sshUnable to find image 'docker-reg.example.com:5000/rhel7-ssh:latest' locallyTrying to pull repository docker-reg.example.com:5000/rhel7-ssh ...053cdd6a08e7: Download complete 275be1d3d070: Download complete 
~~~

	4.3 コンテナ起動確認

	~~~
[root@docker ~]# docker ps
CONTAINER ID        IMAGE                                   COMMAND             CREATED             STATUS              PORTS                                                                                              NAMES
f658e4b89949        docker-reg.example.com:5000/rhel7-ssh   "/usr/sbin/init"    7 seconds ago       Up 6 seconds        0.0.0.0:20022->22/tcp, 0.0.0.0:28080->8080/tcp, 0.0.0.0:29990->9990/tcp, 0.0.0.0:29999->9999/tcp   rhel7 
~~~

5. Private Docker registry 内のイメージを確認

	~~~
[root@docker ~]# curl -s https://docker-reg.example.com:5000/v1/repositories/rhel7-ssh/tags  -k /etc/docker/certs.d/docker-reg.example.com\:5000/ca.crt 
{"latest": "053cdd6a08e75bf0f1c573df082c0768df80417242322737b6876227042c5667"}
~~~

6. Private Docker registry 内のイメージを削除

	~~~
[root@docker ~]# curl -X DELETE -s https://docker-reg.example.com:5000/v1/repositories/rhel6.5eap/tags/latest  -k /etc/docker/certs.d/docker-reg.example.com\:5000/ca.crt 
true
~~~

以　上

