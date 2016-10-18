#OpenShift 3.1 Quick インストールメモ

---

* 構成：master x 1, node x 2
* KVM を利用。DHCPから直接アドレスを取得(ブリッジ接続)：[KVM設定メモ](./kvm_command.md)
* [OpenShift 3 インストールガイド](https://access.redhat.com/documentation/en/openshift-enterprise/version-3.1/installation-and-configuration)
* [大溝さん ose31 インストール手順](https://github.com/akubicharm/openshift-playground/blob/master/docs/Install31.md)

---

##OpenShift 3.1 インストール準備



ベースはRHEL7の minimam インストール

1. サブスクリプション関連の設定 (Master/node 共通)


	* サブスクリプション有効化

	~~~
# subscription-manager register --username=<user_name> --password=<password>
~~~

	 * Pool Id の紐付け

	~~~
# subscription-manager attach --pool=<pool_id>
# subscription-manager attach --pool 8a85f98144844aff014488d058bf15be
~~~

	* Yumリポジトリのサブスクライブ

	~~~
# subscription-manager repos --disable="*"
# subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-optional-rpms" \
    --enable="rhel-7-server-ose-3.1-rpms"
~~~

* master 2台構成の場合 (masterのみ？ 未検証)

	~~~
# subscription-manager repos \
    --enable="rhel-ha-for-rhel-7-server-rpms"
~~~

## ベースパッケージのインストール

* 必要なパッケージを導入

	~~~
# yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion httpd-tools
~~~

* パッケージアップデート実行

	~~~
# yum update
~~~ 

* quick/adanced インストールに必要なパッケージの導入

	~~~
# yum install atomic-openshift-utils
~~~

## Dockerのインストール

* master/node 双方でOpenShiftインストール前にDocker 1.8.2 より新しいバージョンをインストール、起動する


* docker インストール

	~~~
# yum install docker
~~~

* **/etc/sysconfig/docker** ファイルに次のオプションを設定する

	~~~
OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'
~~~

* /etc/sysconfig/docker-strage-setup の設定

	次の3通りの設定がある。設定方法はマニュアルを参照

	* ブロックデバイスを追加
	* 既存の Volume Group　を設定
	* root file system の空き容量を利用する

* docker 起動設定

	~~~
# systemctl start docker.service 
# systemctl enable docker.service 
~~~

* docker の初期化を実施する

	~~~
# systemctl stop docker
# rm -rf /var/lib/docker/*
# systemctl restart docker
~~~

## OSE起動ユーザ で パスワード無しログインの設定(SSH)
* DNSサーバ参照設定 (事前にDNS Serverの構築が必要)

	~~~
# vi /etc/resolv.conf
=======
search osaka.redhat.com
nameserver 192.168.99.250 <--追加
nameserver 192.168.99.51
=======
~~~

* OSE起動ユーザーの作成

	~~~
# useradd ose3
# passwd ose3
# su - ose3
~~~

* SSH キーペアの作成

	~~~
$ ssh-keygen
~~~

* SSH キーの配布

	~~~
$ for host in master.ose3.example.com \
    do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
    done
~~~

* sudo の設定

	~~~
# visudo
============
ose3    ALL=(ALL)       NOPASSWD: ALL
============
~~~
	
## OpenShift 3.1 Quick Installation


* **~/.config/openshift/installer.cfg.yml** にインストールファイルを準備
* 
~~~
version: v1
variant: openshift-enterprise
variant_version: 3.1
ansible_ssh_user: ose3
ansible_log_path: /tmp/ansible.log
hosts:
- ip: 192.168.172.251
  hostname: master
  public_ip: 192.168.172.251
  public_hostname: master.ose3.example.com
  master: true
  node: true
  containerized: true
  connect_to: 192.168.172.251
~~~

* Ansible Installer の起動

	~~~
$ atomic-openshift-installer -u install
~~~

## ユーザ認証方式の変更

クイックインストールの場合は、ユーザ認証方式が設定されず deny_all になっているので、誰も使えません。HTPasswd認証ができるように変更します。

変更前

~~~
oauthConfig:
  assetPublicURL: https://ose-master.example.com:8443/console/
  grantConfig:
    method: auto
  identityProviders:
  - name: deny_all
    challenge: True
    login: True
    provider:
      apiVersion: v1
      kind: DenyAllPasswordIdentityProvider
~~~

変更後

~~~
oauthConfig:
  assetPublicURL: https://ose-master.example.com:8443/console/
  grantConfig:
    method: auto
  identityProviders:
  - name: htpasswd_auth  ←ここを編集
    challenge: True
    login: True
    provider:
      apiVersion: v1
      kind: HTPasswdPasswordIdentityProvider  ←ここを編集
      file: /etc/origin/openshift-htpasswd      ←ここを追加
~~~

認証ファイルとして指定する　**/etc/origin/openshift-htpasswd** ファイルが存在しない場合、openshift-master の起動に失敗します。

## nodeへのタグ付与(必要な場合のみ)
~~~
# su - ose3
$ oc label node/ose3-master.example.com region=infra$ oc label node/ose3-node1.example.com region=primary zone=east$ oc label node/ose3-node2.example.com region=primary zone=west~~~

## スケジューリングの有効化
インストール直後は、masterサーバはスケジューリング不可 (Podのデプロイ不可)になっているので、スケジューリングを可能にする。

~~~
# oadm manage-node master --schedulable=true
~~~

## Docker Registry の設定

* Docker Image を格納するローカルのレジストリ。**system:registry**ロールを持つ regular user を作成する必要がある。

* HTPASSWD認証の例

	~~~
# htpasswd -c /etc/origin/openshift-htpasswd reguser
# oadm policy add-role-to-user system:registry reguser
~~~

* Deploying the Registry

	~~~
# mkdir -p /registry
# chcon -R -t svirt_sandbox_file_t /registry 
# oadm registry --selector="region=infra" --config=/etc/origin/master/admin.kubeconfig --credentials=/etc/origin/master/openshift-registry.kubeconfig --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' --replicas=1 --service-account=registry --mount-host=/registry
~~~


## Router の作成
* route 作成
	
	~~~
# oadm router   --selector="region=infra" --config=/etc/origin/master/admin.kubeconfig --credentials=/etc/origin/master/openshift-router.kubeconfig   --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' --replicas=1 --service-account=router
~~~

## アプリケーションドメインのデフォルト値変更
アプリケーションのドメイン名の接尾辞が cloudapps.example.com となるように変更します。

[/etc/origin/master/master-config.yaml]

* 変更前

	~~~
routingConfig:
  subdomain:  ""
~~~

* 変更後
* 
	~~~
routingConfig:
subdomain:  "cloudapps.example.com"
~~~


## 利用者の追加

* -b オプションで ID/パスワード を指定

	~~~
# htpasswd -b /etc/origin/openshift-htpasswd joe redhat
~~~

##ブラウザアクセスのための IPTABLES 設定 (不要)

* master にて次のコマンドを実行

	~~~
# iptables -I INPUT 7 -m state --state NEW -m tcp -p tcp --dport 8443 -j ACCEPT# service iptables save
~~~

##ログイン

* 管理ユーザーでのログイン

	~~~
# oc login -u system:admin -n default
~~~

* 個人ユーザーでのログイン

	~~~
# oc login -u mamurai --server=https://ose3-master.example.com:8443
~~~

* 大溝さん環境へのログイン

	~~~
$ oc login -u mamurai --insecure-skip-tls-verify=true --server=https://master.m1n2.cloud:8443
~~~
## OpenShift Image Streams の作成

* GitHubからスクリプト取得

	~~~
# git clone https://github.com/openshift/openshift-ansible
~~~

* Image Streams の作成 （これ以降は設定が存在するので実行せず)

	~~~
# oc create -f \
    openshift-ansible/roles/openshift_examples/files/examples/v1.1/image-streams/image-streams-rhel7.json \
    -n openshift
~~~

## OSE アプリ作成

* ユーザー作成

	~~~
# useradd mamurai
# htpasswd /etc/origin/openshift-htpasswd mamurai
~~~

* プロジェクト作成

	~~~
# oadm new-project demo --display-name="OpenShift 3.1 Demo" \
--description="This is the first demo project with OpenShift v3.1" \
--admin=mamurai
~~~

* プロジェクト一覧確認

	~~~
# oc get project
~~~


