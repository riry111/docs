#OpenShift 3.1 インストールメモ

---

* 構成：master x 1, node x 2
* KVM を利用。DHCPから直接アドレスを取得(ブリッジ接続)：[KVM設定メモ](./kvm_command.md)
* [OpenShift 3 インストールガイド](https://access.redhat.com/documentation/en/openshift-enterprise/version-3.1/installation-and-configuration)

---

## サーバ準備

* KVMのクローン

	~~~
# for host in ose3m01 ose3n01 ose3n02 
> do
> virt-clone --original rhel7_min --name $host --file /var/lib/libvirt/images/$host.qcow2
> done
~~~

* ネットワークブリッジ設定
* ホスト名変更

		# nmcli general hostname ose3m01
		
* コンソールログインの設定 (rhel7_min で設定済み)


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
# yum -y update
~~~ 

* quick/adanced インストールに必要なパッケージの導入

	~~~
# yum -y install atomic-openshift-utils
~~~

## Dockerのインストール

* master/node 双方でOpenShiftインストール前にDocker 1.8.2 より新しいバージョンをインストール、起動する


* docker インストール

	~~~
# yum -y install docker
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

## root で パスワード無しログインの設定(SSH)
* DNSサーバ参照設定 (事前にDNS Serverの構築が必要)

	~~~
# vi /etc/resolv.conf
=======
search osaka.redhat.com
nameserver 192.168.99.250 <--追加
nameserver 192.168.99.51
=======
~~~

* SSH キーペアの作成

	~~~
# ssh-keygen
~~~

* SSH キーの配布

	~~~
# for host in master.ose3.example.com \
    node1.ose3.example.com \
    node2.ose3.example.com; \
    do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
    done
~~~

## OpenShift インストール前スナップショット取得

* KVMホストにてスナップショット取得

	~~~
# for host in ose3m01 \
	ose3n01 \
	ose3n02 ; \
	do virsh snapshot-create-as $host sn_init_$host "Before OSE3.1 Install SnapShot"; \
	done
~~~

* KVMホストにてスナップショット確認
	
	~~~
# for host in ose3m01 \
	ose3n01 \
	ose3n02 ; \
	do virsh snapshot-list $host; \
	done
~~~
		

## OpenShift 3.1 簡易インストール
see:<http://jp-redhat.com/openeye_online/column/omizo/2856/>

[~/.config/openshift/installer.cfg.yml]

~~~
version: v1 variant: openshift-enterprisevariant_version: 3.1ansible_ssh_user: vagrantansible_log_path: /tmp/ansible.loghosts:- ip: 192.168.99.81  hostname: ose3m01.osaka.redhat.com  public_ip: 192.168.99.81  public_hostname: ose3m01.osaka.redhat.com  master: true  node: true  containerized: false  connect_to: 192.168.99.81- ip: 192.168.99.82  hostname: ose3n01.osaka.redhat.com  public_ip: 192.168.99.82  public_hostname: ose3n01.osaka.redhat.com  node: true  connect_to: 192.168.99.82- ip: 192.168.99.83  hostname: ose3n02.osaka.redhat.com  public_ip: 192.168.99.83  public_hostname: ose3n02.osaka.redhat.com  node: true  connect_to: 192.168.99.83
~~~


## For OpenShift 3.2

~~~
version: v1variant: openshift-enterprisevariant_version: 3.2ansible_ssh_user: rootansible_log_path: /tmp/ansible.loghosts:- ip: 192.168.99.81  hostname: ose3m01.osaka.redhat.com  public_ip: 192.168.99.81  public_hostname: ose3m01.osaka.redhat.com  master: true  node: true  containerized: true  connect_to: 192.168.99.82- ip: 192.168.99.82  hostname: ose3n01.osaka.redhat.com  public_ip: 192.168.99.82  public_hostname: ose3n01.osaka.redhat.com  node: true  connect_to: 192.168.99.82- ip: 192.168.99.83  hostname: ose3n02.osaka.redhat.com  public_ip: 192.168.99.83  public_hostname: ose3n02.osaka.redhat.com  node: true  connect_to: 192.168.99.83
~~~

## OpenShift 3.1 Advanced Installation

* **/etc/ansible/hosts** ファイルの編集
* htpasswd認証を有効にするため、マニュアルのサンプルから「openshift_master_identity_providers=」のコメントアウトを削除

~~~
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=root

# If ansible_ssh_user is not root, ansible_sudo must be set to true
#ansible_sudo=true

deployment_type=openshift-enterprise

# uncomment the following to enable htpasswd authentication; defaults to DenyAllPasswordIdentityProvider
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/openshift-htpasswd'}]

# host group for masters
[masters]
master.ose3.example.com

# host group for nodes, includes region info
[nodes]
master.ose3.example.com openshift_node_labels="{'region': 'infra', 'zone': 'default'}"
node1.ose3.example.com openshift_node_labels="{'region': 'primary', 'zone': 'east'}"
node2.ose3.example.com openshift_node_labels="{'region': 'primary', 'zone': 'west'}"
~~~

* Ansible Installer の起動

	~~~
# ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
~~~

## ラベルの手動設定
~~~
oc label node master.ose3.example.com region=infra zone=default
oc label node node1.ose3.example.com region=primary zone=east
oc label node node2.ose3.example.com region=primary zone=west
~~~

* Verifying the Installation [(2.4.6)](https://access.redhat.com/documentation/en/openshift-enterprise/version-3.1/installation-and-configuration/#verifying-the-installation)

## スケジューリングの有効化
インストール直後は、masterサーバはスケジューリング不可 (Podのデプロイ不可)になっているので、スケジューリングを可能にする。

~~~
# oadm manage-node master.ose3.example.com --schedulable=true
~~~

## Docker Registry の設定

* Docker Image を格納するローカルのレジストリ。**system:registry**ロールを持つ regular user を作成する必要がある。

* HTPASSWD認証の例

	~~~
# htpasswd /etc/origin/openshift-htpasswd reguser
# oadm policy add-role-to-user system:registry reguser
~~~

* Deploying the Registry

	~~~
# mkdir -p /registry
# chmod 777 /registry 
# oadm registry  --service-account=registry  --config=/etc/origin/master/admin.kubeconfig  --credentials=/etc/origin/master/openshift-registry.kubeconfig --images='registry.access.redhat.com/openshift3/ose-${component}:${version}'   --mount-host=/registry  --selector="region=infra" --replicas=1
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
# oc login -u mamurai --server=https://master.ose3.example.com:8443
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


