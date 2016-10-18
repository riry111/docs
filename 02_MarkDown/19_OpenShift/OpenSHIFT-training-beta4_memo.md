#OpenSHIFT v3 beta-4-training


##Setting Up the Environment

###過去のDockerデータを削除

~~~
[root@master]# yum -y remove docker
[root@master]# rm /etc/sysconfig/docker*
[root@master]# yum -y install docker
~~~

###Docker Storage Setup (optional, recommended)
Dockerのデフォルトストレージは、loopback devicesを利用。本番環境には適さない。レッドハットでは、dm.thinpooldev strage を推奨
**docker-1.6.2-6.el7.x86_64.** より新しいバージョンを利用する必要がある。


####LVM上にDocker Strageを作成するため、LV(Logical Volume)を縮小する

1. LVMの状況確認

	1.1 現在の物理ボリュームの状況確認

	~~~
[root@master]# pvscan
  PV /dev/sda2   VG rhel   lvm2 [99.51 GiB / 64.00 MiB free]
  Total: 1 [99.51 GiB] / in use: 1 [99.51 GiB] / in no VG: 0 [0   ]
~~~

	1.2 現在のLocal Volumeの状況を確認

	~~~
[root@master]# lvscan
  ACTIVE            '/dev/rhel/swap' [2.00 GiB] inherit
  ACTIVE            '/dev/rhel/home' [47.45 GiB] inherit
  ACTIVE            '/dev/rhel/root' [50.00 GiB] inherit
~~~
Logcal Volume /dev/rhel/home を  47.45GB -> 10GBに縮小し、docker-pool用のスペースを確保する

2. LV /dev/rhel/home の再作成

	2.1 /home のコンテンツのバックアップを取得する
	
	~~~
[root@master]# cd /home
[root@master]# ta cvf /var/home.tar ./*
~~~
	2.2 /home を umount 後、LV /dev/rhel/home を削除

	~~~
[root@master]# umount /home
[root@master]# lvremove /dev/rhel/home
Do you really want to remove active logical volume home? [y/n]: y
  Logical volume "home" successfully removed
~~~
	2.3 LV /dev/rhel/home を 10GBで再作成し、xfsでファイルシステムを作成

	~~~
[root@master]# lvcreate -L 10G -n /dev/rhel/home rhel
WARNING: xfs signature detected on /dev/rhel/home at offset 0. Wipe it? [y/n]: y
  Logical volume "home" created.
[root@master]# mkfs -t xfs /dev/rhel/home 
meta-data=/dev/rhel/home         isize=256    agcount=4, agsize=655360 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=0        finobt=0
data     =                       bsize=4096   blocks=2621440, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
~~~
	2.4 /home をマウントしバックアップしたファイルを元に戻す

	~~~
[root@master]# mount /home
[root@master]# cd /home
[root@master]# tar xvf /var/home.tar
~~~

#### LVM Voluem に Docker用のストレージを作成する

~~~
[root@master]# echo <<EOF > /etc/sysconfig/docker-storage-setup
> VG=docker-vg
> SETUP_LVM_THIN_POOL=yes
> EOF
[root@master]# docker-storage-setup
  Rounding up size to full physical extent 104.00 MiB
  Logical volume "docker-poolmeta" created.
  Logical volume "docker-pool" created.
  WARNING: Converting logical volume rhel/docker-pool and rhel/docker-poolmeta to pool's data and metadata volumes.
  THIS WILL DESTROY CONTENT OF LOGICAL VOLUME (filesystem etc.)
  Converted rhel/docker-pool to thin pool.
  Logical volume "docker-pool" changed.
~~~

LVMの設定を確認

~~~
[root@master]# lvs
  LV          VG   Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool rhel twi-a-t--- 22.44g             0.00   0.05                            
  home        rhel -wi-ao---- 10.00g                                                    
  root        rhel -wi-ao---- 50.00g                                                    
  swap        rhel -wi-ao----  2.00g  
~~~
Logical Volume **docker-pool** が作成されたことが確認できます。

docker-strageの設定ファイルを確認

~~~
[root@master]# cat /etc/sysconfig/docker-storage
DOCKER_STORAGE_OPTIONS=-s devicemapper --storage-opt dm.fs=xfs --storage-opt dm.thinpooldev=/dev/mapper/rhel-docker--pool
~~~


###Grab Docker Images (optional, recommended)

1. 過去にOpenSHIFTのトレーニングを実施ている場合は、次のコマンドを実施してdocker を再インストールする

	~~~
[root@master]# yum -y remove docker
[root@master]# rm /etc/sysconfig/docker*
[root@master]# yum -y install docker
~~~

2. /etc/sysconfig/docker の OPTIONS に「--insecure-registry 0.0.0.0/0」を追加後、docker を起動
 
	~~~
[root@master]# systemctl start docker
~~~

3.  以下のimagesを取得する

	~~~
docker pull registry.access.redhat.com/openshift3/ose-haproxy-router
docker pull registry.access.redhat.com/openshift3/ose-deployer
docker pull registry.access.redhat.com/openshift3/ose-sti-builder
docker pull registry.access.redhat.com/openshift3/ose-sti-image-builder
docker pull registry.access.redhat.com/openshift3/ose-docker-builder
docker pull registry.access.redhat.com/openshift3/ose-pod
docker pull registry.access.redhat.com/openshift3/ose-docker-registry
docker pull registry.access.redhat.com/openshift3/ose-keepalived-ipfailover
docker pull registry.access.redhat.com/openshift3/ruby-20-rhel7
docker pull registry.access.redhat.com/openshift3/mysql-55-rhel7
docker pull registry.access.redhat.com/openshift3/php-55-rhel7
docker pull registry.access.redhat.com/jboss-eap-6/eap-openshift
docker pull openshift/hello-openshift
~~~
sti-basicauthurl は サポート対象外になったようなので対象から外す。See: [Bug 1238838](https://bugzilla.redhat.com/show_bug.cgi?id=1238838)

4. 取得したimageをアーカイブを作成

	~~~
[root@master]# docker save -o beta4-images.tar \
registry.access.redhat.com/openshift3/ose-haproxy-router \
registry.access.redhat.com/openshift3/ose-deployer \
registry.access.redhat.com/openshift3/ose-sti-builder \
registry.access.redhat.com/openshift3/ose-sti-image-builder \
registry.access.redhat.com/openshift3/ose-docker-builder \
registry.access.redhat.com/openshift3/ose-pod \
registry.access.redhat.com/openshift3/ose-docker-registry \
registry.access.redhat.com/openshift3/ose-keepalived-ipfailover \
registry.access.redhat.com/openshift3/ruby-20-rhel7 \
registry.access.redhat.com/openshift3/mysql-55-rhel7 \
registry.access.redhat.com/openshift3/php-55-rhel7 \
registry.access.redhat.com/jboss-eap-6/eap-openshift \
docker.io/openshift/hello-openshift
~~~
5. node側へdocker images のアーカイブをインポート

	~~~
[root@node]# docker load -i beta4-image.tar
~~~	

###Clone the Training Repository
トレーニングコンテンツをローカルにダウンロードする

~~~
[root@master]# cd
[root@master]# git clone https://github.com/openshift/training.git
~~~

###Add Development Users
開発者がOpenShift を個人の端末から利用する。その際に利用するアカウント joe と  alice を **master サーバ**に作成する。このユーザに対して *htpasswd* の認証を設定する。

~~~
[root@master]# useradd joe
[root@master]# useradd alice
~~~
これらのユーザは後ほど利用します。必ず **master** サーバのみ作成してください。決して node 側には作成しないこと。

##Ansible-based Installer
###Install Ansible
1. EPELをインストール

	~~~
[root@master]# yum -y install \
http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
~~~
2. EPEL のyumリポジトリを無効化

	~~~
[root@master]# sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
~~~

3. Ansible パッケージのインストール

	~~~
[root@master]# yum -y --enablerepo=epel install ansible
~~~

###Generate SSH Keys
Ansible インストール実施時に、node側へのパスフレーズ無しのSSHログインが必要となるのでSSH キーペア認証の設定を実施する

* sshキーペアの生成

	~~~
[root@master]# ssh-keygen
~~~
パスワードをつけないこと

###Distribute SSH Keys
* 作成した公開鍵を各サーバへ配布する

	~~~
[root@master]# for host in ose3-master.example.com ose3-node1.example.com \
ose3-node2.example.com; do ssh-copy-id -i ~/.ssh/id_rsa.pub \
$host; done
~~~

###Clone the Ansible Repository
* Github 上から Ansible Repositoryを取得する

	~~~
[root@master]# cd
[root@master]# git clone https://github.com/openshift/openshift-ansible
[root@master]# cd ~/openshift-ansible
~~~

###Configure Ansible
* /etc/ansible/hostsを 以下のように変更する 設定は: [OSEv3.0管理者ガイド](https://access.redhat.com/beta/documentation/en/openshift-enterprise-30-administrator-guide/chapter-1-installation) 参照

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

# To deploy origin, change deployment_type to origin
deployment_type=enterprise

# enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/openshift/openshift-passwd'}]

# host group for masters
[masters]
ose3-master.example.com

# host group for nodes, includes region info
[nodes]
ose3-master.example.com openshift_node_labels="{'region': 'infra', 'zone': 'default'}"
ose3-node1.example.com openshift_node_labels="{'region': 'primary', 'zone': 'east'}"
ose3-node2.example.com openshift_node_labels="{'region': 'primary', 'zone': 'west'}"
~~~

###Run the Ansible Installer
* Ansible installer を実行する

	~~~
[root@master]# ansible-playbook ~/openshift-ansible/playbooks/byo/config.yml
~~~

* Ansible でOSEを再インストールする場合は下記のコマンドを実行する
<br>過去にインストールしたファイルが残っている場合は、ansibleインストールが失敗する

	~~~
[root@master]# yum -y remove openshift openshift-sdn
[root@master]# rm -rf /root/.ansible /root/.kube /etc/openshift /etc/openshift-sdn /root/config.retry /usr/share/openshift /var/lib/openshift/ /etc/sysconfig/openshift*  /run/openshift-sdn 
[root@master]# ansible-playbook ~/openshift-ansible/playbooks/byo/config.yml
~~~

###Add Cloud Domain
* アプリケーション用のドメインとして **cloudapps.example.com** を利用する場合は、**/etc/sysconfig/openshift-master** に次のエントリーを追加する

	~~~
OPENSHIFT_ROUTE_SUBDOMAIN=cloudapps.example.com
~~~


##Regions and Zones

OpenShift 2 では "regions" と "zone" でアプリケーションの配置を制御できたが、Kubernetes ではこの機能は存在しない。OpenShift V3 ではこの要件を満たす先進的な機能を提供している。今回の例では、"region" と "zone" について説明しているが、例えば "secure" と "insecure" というグループ分けも可能である。

まずは、"scheduler" のセッティングについて見ていく

###Scheduler and Defaults
"scheduler" は  OpenShift master の機能であり、pod を作成する際に、どこに作成するか示す機能です。デフォルト設定は以下のようなJSON形式でOpenShiftのコードに埋め込まれている。

~~~
{
  "predicates" : [
    {"name" : "PodFitsResources"},
    {"name" : "MatchNodeSelector"},
    {"name" : "HostName"},
    {"name" : "PodFitsPorts"},
    {"name" : "NoDiskConflict"}
  ],"priorities" : [
    {"name" : "LeastRequestedPriority", "weight" : 1},
    {"name" : "ServiceSpreadingPriority", "weight" : 1}
  ]
}
~~~



###Customizing the Scheduler Configuration
Ansible installer で導入した場合、"regions" と "zones" の設定がデフォルトで入っている。**/etc/openshift/master/master-config.yaml** ファイルの **schedulerConfigFile** で設定されている。

~~~
schedulerConfigFile: "/etc/openshift/master/scheduler.json"
~~~

**/etc/openshift/master/scheduler.json**の設定は次の通り

~~~
{
  "predicates" : [
    {"name" : "PodFitsResources"},
    {"name" : "PodFitsPorts"},
    {"name" : "NoDiskConflict"},
    {"name" : "Region", "argument" : {"serviceAffinity" : { "labels" : ["region"]}}}
  ],"priorities" : [
    {"name" : "LeastRequestedPriority", "weight" : 1},
    {"name" : "ServiceSpreadingPriority", "weight" : 1},
    {"name" : "Zone", "weight" : 2, "argument" : {"serviceAntiAffinity" : { "label" : "zone" }}}
  ]
}
~~~

oc get nodes コマンドで、LABELに zone/regionが設定されないのはバグ[Bug 1235953](https://bugzilla.redhat.com/show_bug.cgi?id=1235953)

~~~
[root@master]# oc get nodes
NAME                      LABELS                                           STATUS
ose3-master.example.com   kubernetes.io/hostname=ose3-master.example.com   Ready
ose3-node1.example.com    kubernetes.io/hostname=ose3-node1.example.com    Ready
ose3-node2.example.com    kubernetes.io/hostname=ose3-node2.example.com    Ready
~~~
**本来、LABEL に zone と resion が設定されるはずだが設定されず。**


### [備忘録]　training beta-3 の手順を参考に nodeのLABELを変更する<br>oc update node を実施したが設定が変更されず。。。

-----

1. 既存の node 設定を取得する

	~~~
oc get node -o json | sed -e '/"resourceVersion"/d' > nodes.json
~~~

2. labels　の記述を変更する (以下はmasterの例)

	~~~
[root@master]# vi nodes.json 
"labels": {
  "kubernetes.io/hostname": "ose3-master.example.com",
  "region" : "infra",
  "zone" : "NA"
}
~~~

3. 修正した node.json の内容で、node設定を更新する

	~~~
[root@master]# oc update node -f nodes.json
~~~
ここまでNG

----

### Case [01467759](https://c.na7.visual.force.com/apex/Case_View?id=500A000000RRNCH&sfdc.override=1) にワークアラウンドあり
* ワークアラウンド実行

~~~
[root@master]# oc label --overwrite node ose3-master.example.com region=infra zone=default
[root@master]# oc label --overwrite node ose3-node1.example.com region=primary zone=east
[root@master]# oc label --overwrite node ose3-node2.example.com region=primary zone=west
~~~

* 実行後の nodes設定確認 (resion/zone が設定されていることを確認)

~~~
[root@master]# oc get nodes
NAME                      LABELS                                                                     STATUS
ose3-master.example.com   kubernetes.io/hostname=ose3-master.example.com,region=infra,zone=default   Ready
ose3-node1.example.com    kubernetes.io/hostname=ose3-node1.example.com,region=primary,zone=east     Ready
ose3-node2.example.com    kubernetes.io/hostname=ose3-node2.example.com,region=primary,zone=west     Ready
~~~

###Useful Openshift Logs
* RHEL7 の systemd journal のログ確認は、journalctl コマンドで実行する


	~~~
journalctl -f -u openshift-master
journalctl -f -u openshift-node
~~~

##Auth, Projects, and the Web Console
###Configuring htpasswd Authentication

* OpenShift v3 では様々な認証メカニズムを準備している。最も簡単なに方法は **htpasswd** ベースの認証です。htpasswd のバイナリーが必要なので、インストールします。

	~~~
[root@master]# yum -y install httpd-tools
~~~

* Joe と Alice ユーザのパスワードを作成します。

	~~~
touch /etc/openshift/openshift-passwd
htpasswd -b /etc/openshift/openshift-passwd joe redhat
htpasswd -b /etc/openshift/openshift-passwd alice redhat
~~~

* OpenShiftの設定は YAMLファイルで **/etc/openshift/master/master-config.yaml.** に格納されている。この中で認証は次のように設定されている

	~~~
  identityProviders:
  - name: htpasswd_auth
    challenge: true
    login: true
    provider:
      apiVersion: v1
      kind: HTPasswdPasswordIdentityProvider
      file: /etc/openshift/openshift-passwd
~~~

* **identityProviders** についてのさらなる情報が必要な場合は、[管理ガイド](http://docs.openshift.org/latest/admin_guide/configuring_authentication.html#HTPasswdPasswordIdentityProvider)を参照

###A Project for Everything
V3 は "project" という "pod" や "service" と異なるリソースがある。OpenShift V2 の "namespaces" と同じような位置付け。

次のコマンドでプロジェクトを作成すると共に、プロジェクトの管理ユーザの割り当てを実施する

* demo プロジェクトを管理者 joe で作成

	~~~
[root@master]# oadm new-project demo --display-name="OpenShift 3 Demo" \
--description="This is the first demo project with OpenShift v3" \
--admin=joe
~~~

* プロジェクトが作成されたことを確認

	~~~
[root@ose3-master ~]# oc get project
NAME              DISPLAY NAME       STATUS
default                              Active
demo              OpenShift 3 Demo   Active
~~~

### Web Console

* Web Console (管理者画面)は、ブラウザからは次のURLでアクセスできる

	~~~
https://ose3-master.example.com:8443/console/
~~~
Web Consoleは、master 再起動後に90秒程度起動時間がかかる。自己署名のSSL証明書を利用しているため、初回アクセス時はブラウザにてこの証明書を受け入れる設定が必要。認証時のIDは **joe** パスワードは **redhat** でログインできる


##Your First Application

### Resources
OpenShift v3 では creating/destroying apps, scaling, building などの 様々なResources を制限することができる。

~~~
{
  "apiVersion": "v1beta3",
  "kind": "ResourceQuota",
  "metadata": {
    "name": "test-quota"
  },
  "spec": {
    "hard": {
      "memory": "512Mi",
      "cpu": "200m",
      "pods": "3",
      "services": "3",
      "replicationcontrollers": "3",
      "resourcequotas": "1"
    }
  }
}
~~~

* Memory

割り当てるメモリ量を設定する。(単位: Mi (mebibytes), Gi (gibibytes))

* CPU

CPUの設定は複雑で、"Kubernetes Computer Unit"(KCU)という単位で設定している。UNITは、シングルコアのhyperthreaded CPU コア数とほぼ同じ。(設定例:"200m"=0.2KCU)となる。

pods, services, reprication controllers についても制限を掛ける。
**resourcequotas**  は無視しても問題ない。Kubernetes は 同じnamespace に複数のquotasを割り当てを試みていた。

### Applying Quota to Project

* quotaの設定 (namespace demo に quota.json を適用する)

~~~
[root@master]# oc create -f quota.json --namespace=demo
resourcequotas/test-quota
~~~
* quota.json の設定内容

~~~
{
  "apiVersion": "v1beta3",
  "kind": "ResourceQuota",
  "metadata": {
    "name": "test-quota"
  },
  "spec": {
    "hard": {
      "memory": "512Mi",
      "cpu": "200m",
      "pods": "3",
      "services": "3",
      "replicationcontrollers": "3",
      "resourcequotas": "1"
    }
  }
}
~~~

*作成したquotaの確認

~~~
[root@master]# oc get -n demo quota
NAME
test-quota
~~~

*quotaで設定した制限の確認

~~~
[root@master]# oc describe quota test-quota -n demo
Name:						test-quota
Resource					Used	Hard
--------					----	----
cpu							0	200m
memory						0	512Mi
pods						0	3
replicationcontrollers	0	3
resourcequotas			1	1
services					0	3
~~~

###Applying Limit Ranges to Projects
コンテナとpod に割り当てる Memory と CPU リソースの最小値、最大値、初期値を設定することができる。

* limitranges の設定

~~~
[root@master]# oc create -f limits.json --namespace=demo
limitranges/limits
~~~
* limit.json の設定内容

~~~
{
    "kind": "LimitRange",
    "apiVersion": "v1beta3",
    "metadata": {
        "name": "limits",
        "creationTimestamp": null
    },
    "spec": {
        "limits": [
            {
                "type": "Pod",
                "max": {
                    "cpu": "500m",
                    "memory": "750Mi"
                },
                "min": {
                    "cpu": "10m",
                    "memory": "5Mi"
                }
            },
            {
                "type": "Container",
                "max": {
                    "cpu": "500m",
                    "memory": "750Mi"
                },
                "min": {
                    "cpu": "10m",
                    "memory": "5Mi"
                },
                "default": {
                    "cpu": "100m",
                    "memory": "100Mi"
                }
            }
        ]
    }
}
~~~

*Namespace demo に割り当てた limitrange 名の確認

~~~
[root@master]# oc get limitrange -n demo
NAME
limits
~~~

*Nemespace demo に割り当てた limitrange limitsの設定確認

~~~
[root@master]# oc describe limitrange limits -n demo
Name:		limits
Type		Resource	Min		Max	Default
----		--------	---		---		---
Pod			cpu			10m		500m	-
Pod			memory		5Mi		750Mi	-
Container	cpu			10m		500m	100m
Container	memory		5Mi		750Mi	100Mi
~~~

###Login
joe ユーザが demo プロジェクトにアクセスするためのコマンドを実行します。

~~~
[root@master]# su - joe
[joe@master]$ oc login -u joe \
 --certificate-authority=/etc/openshift/master/ca.crt \
 --server=https://ose3-master.example.com:8443
Authentication required for https://ose3-master.example.com:8443 (openshift)
Password: 
Login successful.

Using project "demo".
Welcome to OpenShift! See 'oc help' to get started.
~~~

OpenShift はデフォルトでは自己署名の証明書を使っている。そのためコマンドツールを利用する際は証明書ファイルが必要となります。

この**ログイン**プロセスは、**~/.kube/config** ファイルを作成します。
なお、default token lifetime は4時間に設定されています。

* ~/.kube/config の確認

~~~
[joe@master]$ cat ~/.kube/config 
apiVersion: v1
clusters:
- cluster:
    certificate-authority: ../../../etc/openshift/master/ca.crt
    server: https://ose3-master.example.com:8443
  name: ose3-master-example-com:8443
contexts:
- context:
    cluster: ose3-master-example-com:8443
    namespace: demo
    user: joe/ose3-master-example-com:8443
  name: demo/ose3-master-example-com:8443/joe
current-context: demo/ose3-master-example-com:8443/joe
kind: Config
preferences: {}
users:
- name: joe/ose3-master-example-com:8443
  user:
    token: JV6cBwzScm9sLeiOgnaSJSO-HMFH666rrRBgJQokWjw
~~~

### Grab the Training Repo Again
joeユーザでトレーニングマテリアルを取得します。

~~~
[joe@master]$ cd
[joe@master]$ git clone https://github.com/openshift/training.git
[joe@master]$ cd ~/training/beta4
~~~

###The Hello World Definition JSON

* hello-pod.jsonを cat コマンドなどで確認

~~~
{
  "kind": "Pod",
  "apiVersion": "v1beta3",
  "metadata": {
    "name": "hello-openshift",
    "creationTimestamp": null,
    "labels": {
      "name": "hello-openshift"
    }
  },
  "spec": {
    "containers": [
      {
        "name": "hello-openshift",
        "image": "openshift/hello-openshift:v0.4.3",
        "ports": [
          {
            "hostPort": 36061,
            "containerPort": 8080,
            "protocol": "TCP"
          }
        ],
        "resources": {
          "limits": {
            "cpu": "10m",
            "memory": "16Mi"
          }
        },
        "terminationMessagePath": "/dev/termination-log",
        "imagePullPolicy": "IfNotPresent",
        "capabilities": {},
        "securityContext": {
          "capabilities": {},
          "privileged": false
        },
        "nodeSelector": {
          "region": "primary"
        }
      }
    ],
    "restartPolicy": "Always",
    "dnsPolicy": "ClusterFirst",
    "serviceAccount": ""
  },
  "status": {}
}
~~~
pod はアプリケーションのインスタンス。OpenShift V2をご存知であれば、gear のようなものだが、実際はもっと複雑。

###Run the Pod
JSON ファイルを使い、joe ユーザでpodを作成する

~~~
[joe@master]$ oc create -f hello-pod.json 
pods/hello-openshift
~~~

pod の一覧を表示

~~~
[joe@master]$ oc get pods
NAME              READY     REASON    RESTARTS   AGE
hello-openshift   1/1       Running   0          4m
~~~

作成したpod **hello-openshift** の詳細を確認

~~~
[joe@master]$ oc describe pod hello-openshift
Name:				hello-openshift
Image(s):			openshift/hello-openshift:v0.4.3
Host:				ose3-node1.example.com/192.168.172.202
Labels:				name=hello-openshift
Status:				Running
IP:				10.1.1.2
Replication Controllers:	<none>
Containers:
  hello-openshift:
    Image:		openshift/hello-openshift:v0.4.3
    State:		Running
      Started:		Wed, 15 Jul 2015 08:41:19 +0900
    Ready:		True
    Restart Count:	0
Conditions:
  Type		Status
  Ready 	True 
Events:
  FirstSeen				LastSeen			Count	From					SubobjectPath				Reason		Message
  Wed, 15 Jul 2015 08:41:00 +0900	Wed, 15 Jul 2015 08:41:00 +0900	1	{scheduler }									scheduled	Successfully assigned hello-openshift to ose3-node1.example.com
  Wed, 15 Jul 2015 08:41:15 +0900	Wed, 15 Jul 2015 08:41:15 +0900	1	{kubelet ose3-node1.example.com}	implicitly required container POD	pulled		Successfully pulled image "openshift3/ose-pod:v3.0.0.1"
  Wed, 15 Jul 2015 08:41:16 +0900	Wed, 15 Jul 2015 08:41:16 +0900	1	{kubelet ose3-node1.example.com}	implicitly required container POD	created		Created with docker id b78edfa28048fad1bf32e1429dda4b8028fe4a8c2d045daed8c07469ebdd79e2
  Wed, 15 Jul 2015 08:41:17 +0900	Wed, 15 Jul 2015 08:41:17 +0900	1	{kubelet ose3-node1.example.com}	implicitly required container POD	started		Started with docker id b78edfa28048fad1bf32e1429dda4b8028fe4a8c2d045daed8c07469ebdd79e2
  Wed, 15 Jul 2015 08:41:18 +0900	Wed, 15 Jul 2015 08:41:18 +0900	1	{kubelet ose3-node1.example.com}	spec.containers{hello-openshift}	created		Created with docker id 8f9213d2b4670c4ff70b662e74bc0f999d476a8d581adb984ba535687eb5f6ef
  Wed, 15 Jul 2015 08:41:19 +0900	Wed, 15 Jul 2015 08:41:19 +0900	1	{kubelet ose3-node1.example.com}	spec.containers{hello-openshift}	started		Started with docker id 8f9213d2b4670c4ff70b662e74bc0f999d476a8d581adb984ba535687eb5f6ef
~~~

* node1 側で docker ps コマンドを実行すると、Dockerコンテナが起動していることが確認できる。今回のコンテナはホストの36061ポートをコンテナの8080にフォワードしています。

~~~
[root@node1]# docker ps 
CONTAINER ID        IMAGE                              COMMAND              CREATED             STATUS              PORTS                     NAMES
8f9213d2b467        openshift/hello-openshift:v0.4.3   "/hello-openshift"   4 minutes ago       Up 4 minutes                                  k8s_hello-openshift.2320d9d8_hello-openshift_demo_c82d05c7-2a81-11e5-b093-000c29bb6935_98ab72b8   
b78edfa28048        openshift3/ose-pod:v3.0.0.1        "/pod"               5 minutes ago       Up 4 minutes        0.0.0.0:36061->8080/tcp   k8s_POD.af0ce572_hello-openshift_demo_c82d05c7-2a81-11e5-b093-000c29bb6935_c2ecf36d   
~~~

* node1からcrulコマンドで36061ポートにアクセスすると、podが起動している確認ができます。

~~~
[root@ose3-node1 /]# curl localhost:36061
Hello OpenShift!
~~~

###Lokking at the Pod in the Web Console
Web Console の Overview タブを確認すると次のことが確認できます。

* pod のステータスが Running
* SDN IP address podに紐付けられたアドレス (10.X.X.X)
* pod のコンテナが利用している internal port (8080)
* nodeサーバ側に転送される port (36061)
* service がこのpod に紐づいていないこと

![logo](./images/OpenSHIFT-training-beta4_memo_001.png)

###Quota Usage
podを作成したので、podsのUsedの値が1に変わっていることが確認できます。

~~~
[joe@master]$ oc describe quota test-quota -n demo
Name:						test-quota
Resource					Used		Hard
--------					----		----
cpu							10m		200m
memory						16777216	512Mi
pods						1		3
replicationcontrollers	0		3
resourcequotas			1		1
services					0		3
~~~

###Delete the Pod
joe ユーザーで次のコマンドを実行しpodsを削除する

~~~
[joe@master]$ oc delete pod hello-openshift
pods/hello-openshift
~~~

###Quota Enforcement
hello-quotaの設定ではpodsの最大値を3にしているので4番目のpodを作成したばあいにエラーが発生することが確認できる。

joe ユーザで hello-pod.json をコピーして name を変更したものを準備し、以下のように oc create コマンドを実行する

~~~
[joe@master]$ oc create -f hello-pod.json 
[joe@master]$ oc create -f hello-pod2.json 
[joe@master]$ oc create -f hello-pod3.json 
[joe@master]$ oc create -f hello-pod4.json 
Error from server: Pod "hello-openshift4" is forbidden: Limited to 3 pods
~~~

作成したpodsを削除する

~~~
[joe@master]$ oc delete pod --all
~~~


##Service

pod の設定をみてみると、**"label"** という設定があった。

~~~
 "labels": {
    "name": "hello-openshift"
  },
~~~

以下は、**service** の設定になる。
~~~
{
  "kind": "Service",
  "apiVersion": "v1beta3",
  "metadata": {
    "name": "hello-service"
  },
  "spec": {
    "selector": {
      "name":"hello-openshift"
    },
    "ports": [
      {
        "protocol": "TCP",
        "port": 80,
        "targetPort": 9376
      }
    ]
  }
}
~~~
service は **selector**エレメントを持っている。これは、key:value のペアで、name:hello-opensift で設定されている。この値は、masterサーバ上で、**oc get pods** コマンドの実行結果の **label** で保持している。

~~~
name=hello-openshift
~~~

service は ネットワークへの接続。podsへのInput Point になっている。
しかしアプリケーションへ接続する際に、FQDNでアクセスしたい。そのために **routing** を利用する 


##Routing
OpenShiftの touting レイヤーは、FQDNで各podへのアクセスをかのうにする。**openshift3/ose-haproxy-router** コンテナが　HAProxyのサービスを実行する際に起動される。

 * サンプルのJSON定義

~~~
{
  "kind": "Route",
  "apiVersion": "v1beta3",
  "metadata": {
    "name": "hello-openshift-route"
  },
  "spec": {
    "host": "hello-openshift.cloudapps.example.com",
    "to": {
      "name": "hello-openshift-service"
    },
    "tls": {
      "termination": "edge"
    }
  }
}
~~~

oc コマンドで route を作成した場合、新しいインスタンスとして route リソースがOpenShiftのデータストアに作成されます。この route リソースは service に関連しています。

HAProxy/Router は route リソースの変更を監視している。新しい route を見つけた場合、HAProxy pool が作成される。また、route 定義が変更されたばあい、pool も 更新される。

HAProxy pool には、最終的に、serviceName が 定義さrている service に紐付いた全てのpodが含まれます。

サンプルJSONの中に TLS edge termination が設定されている。これは、この route で HTTPS を提供することを意味している。ただし、route と pods 間の通信は暗号化されていない。

TLS termination の詳細については、[マニュアル](http://docs.openshift.org/latest/architecture/core_objects/routing.html#securing-routes) を参照。


###Creating a Wildcard Certification

HTTPSで通信するため、各アプリケーションの cloud domain 毎に証明書を作成する必要がある。
そのため、route に設定する ワイルドカードの証明書を作成する必要がある。OpenShiftには、key/certの作成と署名を行うツールも提供している。

* root で cloudapps.example.com 用の証明書を作成

~~~
[root@master]# mkdir /root/CA; cd /root/CA
[root@master]# CA=/etc/openshift/master
[root@master]#　oadm create-server-cert --signer-cert=$CA/ca.crt \
      --signer-key=$CA/ca.key --signer-serial=$CA/ca.serial.txt \
      --hostnames='*.cloudapps.example.com' \
      --cert=cloudapps.crt --key=cloudapps.key
~~~

作成した cloudapps.crt と cloudapps.key と 認証局の証明書をまとめる必要があります。

~~~
[root@master]#　cat cloudapps.crt cloudapps.key $CA/ca.crt > cloudapps.router.pem
~~~

### Creating the Router

OpenShifgの管理者こmなどで route と pods を 自動的にデプロイします。

~~~
[root@master]# oadm router
error: router could not be created; you must specify a .kubeconfig file path containing credentials for connecting the router to the master with --credentials
~~~

OpenShiftのコンポーネントでは、SSLで利用する証明書と認証方式が必要となります。cloudapp 用に作成したワイルドカード cert/key も設定します。

~~~
[root@master]# oadm router --default-cert=/root/CA/cloudapps.router.pem \
--credentials=/etc/openshift/master/openshift-router.kubeconfig \
--selector='region=infra' \
--images='registry.access.redhat.com/openshift3/ose-${component}:${version}'
~~~

正常に動作すれば、次の文言が表示されます。

~~~
deploymentconfigs/router
services/router
~~~

pods を確認する

~~~
[root@ose3-master ~]# oc get pod
NAME             READY     REASON    RESTARTS   AGE
router-1-hu8sf   1/1       Running   0          21s
[root@ose3-master ~]# oc describe pod router-1-hu8sf
Name:				router-1-hu8sf
Image(s):			registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.1
Host:				ose3-master.example.com/192.168.172.201
Labels:				deployment=router-1,deploymentconfig=router,router=router
Status:				Running
IP:				10.1.2.6
Replication Controllers:	router-1 (1/1 replicas created)
Containers:
  router:
    Image:		registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.1
    State:		Running
      Started:		Wed, 15 Jul 2015 13:04:39 +0900
    Ready:		True
    Restart Count:	0
Conditions:
  Type		Status
  Ready 	True 
Events:
  FirstSeen				LastSeen			Count	From					SubobjectPath				Reason		Message
  Wed, 15 Jul 2015 13:04:37 +0900	Wed, 15 Jul 2015 13:04:37 +0900	1	{scheduler }									scheduled	Successfully assigned router-1-hu8sf to ose3-master.example.com
  Wed, 15 Jul 2015 13:04:38 +0900	Wed, 15 Jul 2015 13:04:38 +0900	1	{kubelet ose3-master.example.com}	implicitly required container POD	pulled		Successfully pulled image "openshift3/ose-pod:v3.0.0.1"
  Wed, 15 Jul 2015 13:04:38 +0900	Wed, 15 Jul 2015 13:04:38 +0900	1	{kubelet ose3-master.example.com}	implicitly required container POD	created		Created with docker id 99a7d98df26bdc40a771001aa350ccd6d62a97365499f1d50655d08bc29f44b7
  Wed, 15 Jul 2015 13:04:38 +0900	Wed, 15 Jul 2015 13:04:38 +0900	1	{kubelet ose3-master.example.com}	implicitly required container POD	started		Started with docker id 99a7d98df26bdc40a771001aa350ccd6d62a97365499f1d50655d08bc29f44b7
  Wed, 15 Jul 2015 13:04:39 +0900	Wed, 15 Jul 2015 13:04:39 +0900	1	{kubelet ose3-master.example.com}	spec.containers{router}			created		Created with docker id 4e35822b0da6a6d088106372cd3c88b5ff97be62d972ec877255919bdf1da288
  Wed, 15 Jul 2015 13:04:39 +0900	Wed, 15 Jul 2015 13:04:39 +0900	1	{kubelet ose3-master.example.com}	spec.containers{router}			started		Started with docker id 4e35822b0da6a6d088106372cd3c88b5ff97be62d972ec877255919bdf1da288
~~~

route を削除する場合は、service , deploymentConfig(dc) , pod を削除する

~~~
[root@master]# oc delete service router
[root@master]# oc delete deploymentConfig router
[root@master]# oc delete pod router-1-deploy
~~~

全ての router は、infra region に作成してください

###Viewing Router Stats
HAProxy は port 1936 で ステータス表示画面を提供している。アクセスパスワードは、
oadm router コマンドで router 作成時に 自動生成されています。

~~~
password for stats user admin has been set to ins9bKUjC8
~~~

なお、アクセスするためには、master サーバの 1936 ポートへのアクセスを許可する必要があります。

~~~
[root@master]# iptables -I OS_FIREWALL_ALLOW -p tcp -m tcp --dport 1936 -j ACCEPT
~~~

* HAProxy stats 画面表示

~~~
http://admin:ins9bKUjC8@ose3-master.example.com:1936 
~~~
http://ose3-master.example.com:1936 にアクセスしてBasic認証を入力してもよい。

![logo](./images/OpenSHIFT-training-beta4_memo_002.png)


###The Complete Pod-Service-Route

joe ユーザにて ocコマンドにて test-complete.json を実行します。

~~~
{
  "kind": "List",
  "apiVersion": "v1beta3",
  "metadata": {
    "name": "hello-service-complete-example"
  },
  "items": [
    {
      "kind": "Service",
      "apiVersion": "v1beta3",
      "metadata": {
        "name": "hello-openshift-service"
      },
      "spec": {
        "selector": {
          "name": "hello-openshift"
        },
        "ports": [
          {
            "protocol": "TCP",
            "port": 27017,
            "targetPort": 8080
          }
        ]
      }
    },
    {
      "kind": "Route",
      "apiVersion": "v1beta3",
      "metadata": {
        "name": "hello-openshift-route"
      },
      "spec": {
        "host": "hello-openshift.cloudapps.example.com",
        "to": {
          "name": "hello-openshift-service"
        },
        "tls": {
          "termination": "edge"
        }
      }
    },
    {
      "kind": "DeploymentConfig",
      "apiVersion": "v1beta3",
      "metadata": {
        "name": "hello-openshift"
      },
      "spec": {
        "strategy": {
          "type": "Recreate",
          "resources": {}
        },
        "triggers": [
          {
            "type": "ConfigChange"
          }
        ],
        "replicas": 1,
        "selector": {
          "name": "hello-openshift"
        },
        "template": {
          "metadata": {
            "creationTimestamp": null,
            "labels": {
              "name": "hello-openshift"
            }
          },
          "spec": {
            "containers": [
              {
                "name": "hello-openshift",
                "image": "openshift/hello-openshift:v0.4.3",
                "ports": [
                  {
                    "name": "hello-openshift-tcp-8080",
                    "containerPort": 8080,
                    "protocol": "TCP"
                  }
                ],
                "resources": {
                  "limits": {
                    "cpu": "10m",
                    "memory": "16Mi"
                  }
                },
                "terminationMessagePath": "/dev/termination-log",
                "imagePullPolicy": "IfNotPresent",
                "capabilities": {},
                "securityContext": {
                  "capabilities": {},
                  "privileged": false
                },
                "livenessProbe": {
                  "tcpSocket": {
                    "port": 8080
                  },
                  "timeoutSeconds": 1,
                  "initialDelaySeconds": 10
                }
              }
            ],
            "restartPolicy": "Always",
            "dnsPolicy": "ClusterFirst",
            "serviceAccount": "",
            "nodeSelector": {
              "region": "primary"
            }
          }
        }
      }
    }
  ]
}
~~~
上記のJSONでは

* コンテナの label に **name=hello-openshift-label**　nodeSelectorに **region=primary** が設定されている
* serviceの設定
	* id が **hello-openshift-service**
	* selector が　**name=hello-openshift** 
* routerの設定
	* FQDN が **hello-openshift.cloudapps.example.com**
	* spec の to に **hello-openshift-service** 

route から podにアクセスした場合：

* route **hello-openshift.cloudapps.example.com** は HAProxy pool を持つ
* pool に紐づく service は **hello-openshift-service** 
* service **hello-openshift-service** は、label **name=hello-openshift-label** が設定された pod を含んでいる
* **name=hello-openshift-label** の1つのpodとコンテナが起動する


~~~
[joe@master]$ oc create -f test-complete.json
~~~
material そのままではエラーが発生したので、以下を修正している。

~~~
[joe@master]$ diff test-complete.json murai/test-complete.json 
2c2
<   "kind": "Config",
---
>   "kind": "List",
89c89
<                 "imagePullPolicy": "PullIfNotPresent",
---
>                 "imagePullPolicy": "IfNotPresent",
~~~

次のようなメッセージ出力されます

~~~
services/hello-openshift-service
routes/hello-openshift-route
pods/hello-openshift
~~~

ocコマンドでの設定確認

~~~
[joe@master]$ oc get pods
NAME                      READY     REASON    RESTARTS   AGE
hello-openshift-1-c5nsf   1/1       Running   1          1d
[joe@master]$ oc get services
NAME                      LABELS    SELECTOR               IP(S)            PORT(S)
hello-openshift-service   <none>    name=hello-openshift   172.30.206.232   27017/TCP
[joe@master]$ oc get routes
NAME                    HOST/PORT                               PATH      SERVICE                   LABELS
hello-openshift-route   hello-openshift.cloudapps.example.com             hello-openshift-service   
~~~

### Project Status
OpenShift では **oc status** コマンドでカレントプロジェクトのリソースを確認することができます。

~~~
[joe@master]$ oc status
In project OpenShift 3 Demo (demo)

service hello-openshift-service (172.30.206.232:27017 -> 8080)
  hello-openshift deploys docker.io/openshift/hello-openshift:v0.4.3 
    #1 deployed 28 hours ago - 1 pod

To see more information about a Service or DeploymentConfig, use 'oc describe service <name>' or 'oc describe dc <name>'.
You can use 'oc get all' to see lists of each of the types described above.
~~~

###Verifying the Service
Service は、ローカルIPアドレス(eg: 172.x.x.x)で Listen しているため、route サービスが起動していない限り、外部からアクセスできません。

~~~
[joe@master]$ oc get services
NAME                      LABELS    SELECTOR               IP(S)            PORT(S)
hello-openshift-service   <none>    name=hello-openshift   172.30.206.232   27017/TCP
~~~

JSONで定義したサービスの動作確認を実施します。**oc get pods** でpodのステータスが running であることを確認した後に、下記のコマンドで確認できます。

~~~
[joe@master]$  curl `oc get services | grep hello-openshift | awk '{print $4":"$5}' | sed -e 's/\/.*//'`
Hello OpenShift!
~~~

###Verifying the Routing
routeing の確認は少し複雑。コンテナは "infra" region ですので masterサーバに作成されています。Docker コンテナは masterサーバ上にありますので、**root** でmasterサーバにログインします。

**oc exec ** コマンドで　起動中のコンテナの中の bash プロセスを取得します。コマンドは以下の通りです。

~~~
[root@ose3-master ~]# oc exec -it -p $(oc get pods | grep router | awk {'print $1}'| head -n 1) /bin/bash
~~~

ターミナルでは、router を起動しているコンテナの中の bash を起動しています。

HAProxy を router として利用していますので、**roouters.json** ファイルで設定を確認できます。

~~~
bash-4.2$ cat /var/lib/containers/router/routes.json
~~~

routers.json の内容は次の通りです

~~~
{
  "default/kubernetes": {
    "Name": "default/kubernetes",
    "EndpointTable": [
      {
        "ID": "192.168.172.201:8443",
        "IP": "192.168.172.201",
        "Port": "8443",
        "TargetName": "192.168.172.201"
      }
    ],
    "ServiceAliasConfigs": {}
  },
  "default/kubernetes-ro": {
    "Name": "default/kubernetes-ro",
    "EndpointTable": [
      {
        "ID": "192.168.172.201:8443",
        "IP": "192.168.172.201",
        "Port": "8443",
        "TargetName": "192.168.172.201"
      }
    ],
    "ServiceAliasConfigs": {}
  },
  "default/router": {
    "Name": "default/router",
    "EndpointTable": [
      {
        "ID": "10.1.2.2:80",
        "IP": "10.1.2.2",
        "Port": "80",
        "TargetName": "router-1-hu8sf"
      }
    ],
    "ServiceAliasConfigs": {}
  },
  "demo/hello-openshift-service": {
    "Name": "demo/hello-openshift-service",
    "EndpointTable": [
      {
        "ID": "10.1.0.2:8080",
        "IP": "10.1.0.2",
        "Port": "8080",
        "TargetName": "hello-openshift-1-c5nsf"
      }
    ],
    "ServiceAliasConfigs": {
      "demo-hello-openshift-route": {
        "Host": "hello-openshift.cloudapps.example.com",
        "Path": "",
        "TLSTermination": "edge",
        "Certificates": {
          "hello-openshift.cloudapps.example.com": {
            "ID": "demo-hello-openshift-route",
            "Contents": "",
            "PrivateKey": ""
          }
        },
        "Status": ""
      }
    }
  }
}
~~~

routerが起動していることは確認できました。HAProxyが設定通りに動作するか確認します。

**exit** を実行しコンテナから抜けてください。

~~~
[root@router-1-hu8sf]# exit
exit
~~~

正しい証明書を利用して router にアクセスする方法は次の2通りあります。

~~~
[root@ose3-master ~]# curl --cacert /etc/openshift/master/ca.crt \
         https://hello-openshift.cloudapps.example.com
Hello OpenShift!
~~~

~~~
[root@ose3-master ~]# openssl s_client -connect hello-openshift.cloudapps.example.com:443 \
         -CAfile /etc/openshift/master/ca.crt
CONNECTED(00000003)
depth=1 CN = openshift-signer@1436900280
verify return:1
[...]
~~~
先ほど、OpenShiftのCA証明書を使って、ワイルドカードのSSL証明書を作成しました。アプリケーションにSSL接続する際は、CA証明書が必要となります。ただし自己署名の証明書ではなく正規の証明書を利用している場合は、CAファイルを指定する必要はありません。


###The Web Console
Web console からは先ほど作成したリソースが全て確認できます。

![logo](./images/OpenSHIFT-training-beta4_memo_003.png)


##Project Administration
demo プロジェクト作成時に管理者として joe を設定しました。以下では、 joe が alice に プロジェクトを参照させる場合、管理者権限を与える場合の手順を示します。

参照権限のみ **alice** に付与する場合
~~~
[joe@ose3-master ~]$ oadm policy add-role-to-user view alice
~~~

**Note:** oadm は実行ユーザが持っているプロジェクトが対象となります。joe ユーザで実行しているので、demo プロジェクトへの参照権限が付与されます。

別のターミナルを開き、 **alice** ユーザでログインします

~~~
[root@master]# su - alice
~~~

alice ユーザでOpenShift にログインします。

~~~
[alice@master]$ oc login -u alice \
--certificate-authority=/etc/openshift/master/ca.crt \
--server=https://ose3-master.example.com:8443
~~~
ログイン成功時は下記の文言が表示されます

~~~
Authentication required for https://ose3-master.example.com:8443 (openshift)
Password: 
Login successful.

Using project "demo".
Welcome to OpenShift! See 'oc help' to get started.
~~~

**alice** は自分のプロジェクトは持っていないが、**demo** プロジェクトの参照権限を付与したので、**oc status** や **oc get pods** などの参照コマンドで demo プロジェクトのリソースを確認できます。

~~~
[alice@master]$ oc get pods
NAME                      READY     REASON    RESTARTS   AGE
hello-openshift-1-c5nsf   1/1       Running   1          1d
~~~

しかし、現時点では変更をすることはできません。

~~~
[alice@ose3-master ~]$ oc delete pod hello-openshift-1-c5nsf
Error from server: User "alice" cannot delete pods in project "demo"
~~~

また、Web Console に alice でログインし、demoプロジェクトを参照することもできます。

joe は  alice に変更権限を付与することもできます。

~~~
[joe@ose3-master ~]$ oadm policy add-role-to-user edit alice
~~~

現状では、podの削除はできますが、他のユーザへ demo プロジェクトへのアクセスを許可することはできません。これを許可するには、alice に **admin**権限を付与する必要があります。

~~~
[joe@ose3-master ~]$ oadm policy add-role-to-user admin alice
~~~

プロジェクトにオーナーがいない場合や、プロジェクトは管理者を付与しないで作成することもできます。
alice と joe が　お互いの管理者権限を取り消すこともできますし、自分自身の権限を取り消すこともできます。

~~~
[joe@ose3-master ~]$ oadm policy remove-user joe
Removing admin from users [joe] in project demo.
~~~

権限付与のコマンドの詳細は、**oadm policy -h** で確認できます。
ここでは簡単な権限付与について説明しましたが、ブロジェクト毎やリソース毎でグループ権限を付与する場合などは次のドキュメントをご確認ください。

* [http://docs.openshift.org/latest/dev_guide/authorization.html](http://docs.openshift.org/latest/dev_guide/authorization.html)
* [https://github.com/openshift/origin/blob/master/docs/proposals/policy.md](https://github.com/openshift/origin/blob/master/docs/proposals/policy.md)

###Deleting a Project
demoプロジェクトの確認が終わりました。管理者は **alice** ですので、以下のコマンドを **alice**で実行して demo プロジェクトを削除します。このコマンドで demo プロジェクトに紐づく全ての pods や リソースも合わせて削除されます。 

~~~
[alice@ose3-master ~]$ oc delete project demo
projects/demo
~~~

削除実行後であれば、 root で **oc get project** を実行すると、プロジェクトのステータスは、**"Terminating"** と表示されます。**oc get pod -n demo** コマンドも参照できます。
約60秒後に demo プロジェクト削除が完了後は、上記コマンドを実行しても結果が表示されません。

##Preparing for S2I: the Registry
OpenShift v3 は ソースコードからDocker Image を生成しデプロイします。また、OpenShift環境内部のみで利用できる Docker Registry も提供します。

###Storage for the registry
レジストリは、docker image と metadata を格納します。もしレジストリ用のpodをデプロイするのであれば、レジストリは短期間で削除されますし、pushしたイメージも削除されてしまいます。
そこで、demo では masterホストの永続化ストレージを利用します。プロダクション環境では、HA Strage solution をバックエンドで NFS mount して利用することも選択できます。

今回はディレクトリレベルで NFS を設定します。まずは master サーバ　**root** でディレクトリを作成します。

~~~
[root@ose3-master ~]# mkdir -p /mnt/registry
~~~

###Creating the registry

**--mount-host=** オプションを利用して ホスト側のディレクトリを利用する場合は、pod を privileged containers として起動する必要がある。詳細はマニュアルの[Deploying a Docker Registry](https://docs.openshift.com/enterprise/3.0/admin_guide/install/docker_registry.html#storage-for-the-registry) を参照

**osadm** コマンドを **root** で実行し レジストリを作成します。

1. ServiceAccount **registry** を作成

	~~~
[root@ose3-master ~]# echo '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"registry"}}' | oc create -f -
~~~

2. 作成した **registry** ユーザに privileged containers の起動を許可する

	~~~
[root@ose3-master ~]# oc edit scc privileged
~~~
**users:** 以下に「- system:serviceaccount:default:registry」を追加する

	~~~
	users:
- system:serviceaccount:default:registry
- system:serviceaccount:openshift-infra:build-controller
~~~

3. service account を利用して registryを作成する
~~~
[root@ose3-master ~]# oadm registry --service-account=registry \
--credentials=/etc/openshift/master/admin.kubeconfig  \
--images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
--selector="region=infra" --mount-host=/mnt/registry
~~~
コマンド実行後、下記のメッセージが表示されます

~~~
deploymentconfigs/docker-registry
services/docker-registry
~~~
**oc get pods** , **oc get services** , **oc get deploymentconfig** や **oc status** コマンドを root で実行できます

~~~
[root@ose3-master ~]# oc status
In project default

service docker-registry (172.30.69.60:5000)
  docker-registry deploys registry.access.redhat.com/openshift3/ose-docker-registry:v3.0.0.1 
    #1 deployed 23 minutes ago - 1 pod

service kubernetes (172.30.0.2:443)

service kubernetes-ro (172.30.0.1:80)

service router (172.30.202.64:80)
  router deploys registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.0.1 
    #1 deployed 37 hours ago - 1 pod
~~~

Docker registry の起動は下記のコマンドで確認できます。

~~~
[root@ose3-master ~]# curl -v `oc get services | grep registry | awk '{print $4":"$5}/v2/' | sed 's,/[^/]\+$,/v2/,'`
~~~

podが起動して service proxyが更新されるまでは時間がかかります。下記のコマンドで endpointsの設定を確認できます。

~~~
[root@ose3-master ~]# oc describe service docker-registry
Name:			docker-registry
Labels:			docker-registry=default
Selector:		docker-registry=default
Type:			ClusterIP
IP:			172.30.69.60
Port:			<unnamed>	5000/TCP
Endpoints:		10.1.1.3:5000
Session Affinity:	None
No events.
~~~


##S2I - What Is It?
S2Iは source-to-image のことで、アプリケーションのソースコードからDocker Image を作成するもの。Openshiftの コードリポジトリやDockerリポジトリのimageを利用できる。

### Create a New Project
joe ユーザで 最初のS2I を putするためのプロジェクトを作成します。

~~~
[joe@ose3-master ~]$ oc new-project sinatra --display-name="Sinatra Example" \
 --description="This is your first build on OpenShift 3" 
~~~
Web Console **joe** ユーザでログインすると新しいプロジェクト作成されたことが確認できます。

###Switch Projects
**joe** ユーザでプロジェクトを **shinatra** に変更します

~~~
[joe@ose3-master ~]$ oc project sinatra
Now using project "sinatra" on server "https://ose3-master.example.com:8443".
~~~

いま接続しているプロジェクトの表示するには次のコマンドを実行します

~~~
[joe@ose3-master ~]$ oc whoami -c
sinatra/ose3-master-example-com:8443/joe
~~~

###A Simple Code Example
GitHub上にある 簡単なサンプルを利用する。Ruby/Sinatra application は Go アプリケーション

アプリケーションのソースコードは次のURLから取得できる

~~~
https://github.com/openshift/simple-openshift-sinatra-sti
~~~

以下のコマンドを実行して出力される JSON を確認してください

~~~
oc new-app -o json https://github.com/openshift/simple-openshift-sinatra-sti.git
~~~

JSONが生成されます。こちらには、**BuildConfig** , **ImageStream** など見慣れたキーワドが含まれてます。

S2Iプロセスの要点:

1. Docker image を生成するために必要なコンポーネントを生成する
2. Docker image を生成する
3. Docker image を Pod にデプロイし、Service に紐付ける

### CLI versus Console
Souce codeからプロジェクトを生成する方法は2種類ある。CLI は (new-app) ツールを利用して生成する。詳細は **oc new-app --help** コマンドで確認できる。

Web Console は、次に示すように、CLIよりももう少し多くの設定が必要となります。

###Adding the Builder ImageStreams
**new-app** は built-in logic が自動的に実行されて ImageStream を生成します。web console はこの機能がありません。そのため、事前に **root** で利用する ImageStream を生成しておきます。

~~~
[root@master]# oc create -f image-streams-rhel7.json \
-f image-streams-jboss-rhel7.json -n openshift
~~~

###Adding Code Via the Web Console

* web console から "Sinatra Example"プロジェクトを選択 "Create +" ボタンを押す
* GitのソースコードURLに「https://github.com/openshift/simple-openshift-sinatra-sti」を入力し Next ボタンを押す
* Select a builder image で  ruby:2.0 を選択する
* Nameが長いので「ruby-example」に変更後、Create ボタンを押す

上記を実施後、OpenShift上では ruby-example が作成ましたが。joe ユーザで  **oc get pods** を実行します。

~~~
[joe@master]$ oc get pod
NAME      READY     REASON    RESTARTS   AGE
~~~
ないも表示されません。これは、build がまだ完了していないからです。OpenShieft は GitHub などの  webhooks を利用することで自動ビルドすることもできます。

しかしながら、自動ビルドするよりもWeb Consoleで確認後 ビルドを開始する方が好ましいです。

ビルド開始は joe で下記を実行してください。

~~~
[joe@ose3-master beta4]$ oc start-build ruby-example
ruby-example-1
~~~

build の実行は 次のコマンドで実行します。

~~~
[joe@ose3-master beta4]$ oc get build
NAME             TYPE      STATUS     POD
ruby-example-1   Source    Complete   ruby-example-1-build
~~~

build のログは次のコマンドで確認できます
~~~
[joe@ose3-master beta4]$ oc build-logs ruby-example-1
~~~

###The Web Console Revisited

Web Console から 作成された build や podの状況が確認できます。

~~~
SERVICE: RUBY-EXAMPLE routing traffic on 172.30.122.189 port 8080 - 8080 (tcp)
~~~

アプリケーションの確認次のコマンドで実行できます。

~~~
[joe@ose3-master beta4]$ curl `oc get service | grep example | awk '{print $4":"$5}' | sed -e 's/\/.*//'`
Hello, Sinatra!
~~~

###Adding a Route to Our Application

service へ FQDNでアクセスするためには routeの作成が必要です。

次の sinatra-route.json を実行して routeを作成します。

~~~
[joe@ose3-master beta4]$ oc create -f sinatra-route.json
routes/ruby-example-route

[joe@ose3-master beta4]$ oc get route
NAME                 HOST/PORT                                   PATH      SERVICE        LABELS
ruby-example         ruby-example.sinatra.router.default.local             ruby-example   generatedby=OpenShiftWebConsole,name=ruby-example
ruby-example-route   hello-sinatra.cloudapps.example.com                   ruby-example   
~~~

sinatra-route.json

~~~
{
  "kind": "Route",
  "apiVersion": "v1beta3",
  "metadata": {
    "name": "ruby-example-route"
  },
  "spec": {
    "host": "hello-sinatra.cloudapps.example.com",
    "to": {
      "name": "ruby-example"
    }
  }
}
~~~

route 作成後は FQDNでアクセスできるようになっています。

~~~
[joe@ose3-master beta4]$ curl http://hello-sinatra.cloudapps.example.com
Hello, Sinatra!
~~~


##Templates, Instant Apps, and "Quickstarts"
今回の例では front-end の webサーバ と back-end の DBサーバの2つのPodを利用した例を示します。このアプリでは自動生成パラメータとOpenShiftの注目すべき点を紹介します。

###A Project for Quickstart
joe ユーザで下記のコマンドを実行します。

~~~
[joe@ose3-master beta4]$ oc new-project quickstart --display-name="Quickstart" \
 --description='A demonstration of a "quickstart/template"'
~~~

###A Quick Aside on Templates

From the [OpenShift documentation:](https://docs.openshift.org/latest/dev_guide/templates.html)

~~~
A template describes a set of resources intended to be used together that
can be customized and processed to produce a configuration. Each template
can define a list of parameters that can be modified for consumption by
containers.
~~~

このテンプレートでは自動生成用のパラメータが利用されています。

~~~
"parameters": [
  {
    "name": "ADMIN_USERNAME",
    "description": "administrator username",
    "generate": "expression",
    "from": "admin[A-Z0-9]{3}"
  },
~~~
このJSONテンプレートでは、ADMIN_USERNAME が 正規表現で定義されています。

###Adding the Template
**root** で ~traning/beta4 フォルダのスクリプト実行します。

~~~
[root@ose3-master beta4]# oc create -f integrated-template.json -n openshift
templates/quickstart-keyvalue-application
~~~
**注意** integrated-template.json で利用しているimage は openshift3_beta のため、これを openshift3 に変更する必要があります

###Create an Instance of the Template

* joe ユーザで Web Console にログインし 「Create +」ボタンをクリック
* quickstart-keyvalue-application をクリックし Select Template をクリック
* 利用するDocker Image やその他のパラメータが設定できるが、今回は、Create をクリック
* Web Consoleで「Browse」->「Services」を選択すると、Routesに **integrated.cloudapps.example.com** が設定されていることを確認できる


###Using Your App
ブラウザから下記のURLにアクセスするとアプリケーションが確認できます。

~~~
http://integrated.cloudapps.example.com
~~~

![logo](./images/OpenSHIFT-training-beta4_memo_004.png)

##Creating and Wiring Disparate Components
開発者は様々なアプリケーションをマニュアルで設定したいはずです。今回の例では、2つの個別のアプリケーションを扱います。

###Create aNew Project
ターミナルから alice ユーザでプロジェクトを作成します。

~~~
[alice@ose3-master ~]$ oc new-project wiring --display-name="Exploring Parameters" \
 --description='An exploration of wiring using parameters'
Now using project "wiring" on server "https://ose3-master.example.com:8443".
~~~

###Stand Up the Frontend

alice ユーザ で フロントエンドのアプリケーションを作成します。

~~~
[alice@ose3-master beta4]$ oc new-app -i openshift/ruby https://github.com/openshift/ruby-hello-world
I0718 00:25:45.366373    9835 newapp.go:301] Image "openshift/ruby" is a builder, so a repository will be expected unless you also specify --strategy=docker
I0718 00:25:45.367386    9835 newapp.go:337] Using "https://github.com/openshift/ruby-hello-world" as the source for build
imagestreams/ruby-hello-world
buildconfigs/ruby-hello-world
deploymentconfigs/ruby-hello-world
services/ruby-hello-world
A build was created - you can run `oc start-build ruby-hello-world` to start it.
Service "ruby-hello-world" created at 172.30.76.101 with port mappings 8080.
~~~

new-app サブコマンドには [不具合](https://bugzilla.redhat.com/show_bug.cgi?id=1232003) があって、namespace が設定されないため下記のコマンドで BuildConfig の設定を変える必要がある。

~~~
[alice@ose3-master beta4]$ oc edit bc/ruby-hello-world
~~~
[変更点] strategy 以下に namespace を追加します

~~~
  strategy:
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: ruby:latest
        namespace: openshift
~~~

database接続情報は環境変数に設定する必要があります。alice ユーザで oc コマンドで deploymentconfigs を設定します。

~~~
[alice@ose3-master beta4]$ oc env dc/ruby-hello-world MYSQL_USER=root MYSQL_PASSWORD=redhat MYSQL_DATABASE=mydb
deploymentconfigs/ruby-hello-world
~~~ 
設定した環境変数は次のコマンドで確認できます。

~~~
[alice@ose3-master beta4]$ oc env dc/ruby-hello-world --list
# deploymentconfigs ruby-hello-world, container ruby-hello-world
MYSQL_USER=root
MYSQL_PASSWORD=redhat
MYSQL_DATABASE=mydb
~~~

###Expose the Service
oc のサブコマンド **expose** は自動で router を作成します。カレントプロジェクトに  namespace も設定します。

~~~
[alice@ose3-master beta4]$ oc expose service ruby-hello-world
~~~

### [注意] route ruby-hello-world.wiring.cloudapp.example.com が作成されないので手動で追加

~~~
[alice@ose3-master beta4]$ oc create -f ruby-hello-world-route.json
routes/ruby-hello-world-route

[alice@ose3-master beta4]$ cat ruby-hello-world-route.json
{
  "kind": "Route",
  "apiVersion": "v1beta3",
  "metadata": {
    "name": "ruby-hello-world-route"
  },
  "spec": {
    "host": "ruby-hello-world.wiring.cloudapps.example.com",
    "to": {
      "name": "ruby-hello-world"
    }
  }
}
~~~
route を確認します

~~~
[alice@ose3-master beta4]$ oc get route
NAME                     HOST/PORT                                       PATH      SERVICE            LABELS
ruby-hello-world         ruby-hello-world.wiring.router.default.local              ruby-hello-world   
ruby-hello-world-route   ruby-hello-world.wiring.cloudapps.example.com             ruby-hello-world   
~~~
次のことが確認できます

* service name
* namespace name
* route domain



ここまで完了すればフロントエンドアプリにブラウザからアクセス可能です。ただしDatabaseの設定がまだのため、エラーが発生します。

###Add the Database Template
openshift namespace に テンプレートを追加します

~~~
[alice@ose3-master beta4]$ oc create -f mysql-template.json
templates/mysql-ephemeral
~~~

###Create the Database From the Web Console
* alice ユーザで Web Console にログインし wiringプロジェクトを選択し「Create +」をクリック
* テンプレートで「mysql-ephemeral」を選択し”Select template”をクリック
* パラメータを次の値に変更後、Create をクリック

	Parameters | Value | 備考
--- | --- | ---
DATABASE_SERVICE_NAME | database | 
MYSQL_USER | root | 前の lab で設定
MYSQL_PASSWORD | redhat | 前の lab で設定 
MYSQL_DATABASE | mydb | 前の lab で設定

MySQLへの接続確認は次のコマンドで実行できます。

~~~
[alice@ose3-master beta4]$ curl `oc get services | grep database | awk '{print $4}'`:3306
~~~
MySQL は HTTPプロトコルを解釈しないため、下記のような文言が出力されれば起動していると判断できます。

~~~
5.5.41+_{m4U3>??{uW6E8)c8-w3mysql_native_password!??#08S01Got packets out of orde
~~~

###Visit Your Application Again
まだエラーは解消していません。flont-end を先に作成したため、"database" という service を見つけることがでないため、DBにアクセスできません。

###Replication Controllers
Repliation Controllerが flont-end と back−end 双方に起動していることが確認できます。

~~~
[alice@ose3-master beta4]$ oc get replicationcontroller
~~~
起動しているインスタンス数を確認するためには、describe サブコマンドを利用します。

~~~
[alice@ose3-master beta4]$ oc describe rc ruby-hello-world-1
~~~

front-end の podを削除すると、自動的に front-endの podが再作成されます。

~~~
[alice@ose3-master beta4]$ oc delete pod `oc get pod | grep -e "hello-world-[0-9]" | grep -v build | awk '{print $1}'`
~~~


database podが起動しているサーバにて root で次のコマンドを実行すればDB関連パラメータが取得できます。

~~~
[root@ose3-node1 ~]# docker inspect `docker ps | grep hello-world | grep run | awk \
> '{print $1}'` | grep DATABASE
~~~

出力結果は次の通りです。

~~~
            "MYSQL_DATABASE=mydb",
            "DATABASE_PORT_3306_TCP=tcp://172.30.244.94:3306",
            "DATABASE_PORT_3306_TCP_PORT=3306",
            "DATABASE_PORT_3306_TCP_ADDR=172.30.244.94",
            "DATABASE_PORT=tcp://172.30.244.94:3306",
            "DATABASE_SERVICE_PORT_MYSQL=3306",
            "DATABASE_SERVICE_HOST=172.30.244.94",
            "DATABASE_PORT_3306_TCP_PROTO=tcp",
            "DATABASE_SERVICE_PORT=3306",
~~~


###Revisit the Webpage

ブラウザから <http://ruby-hello-world.wiring.cloudapps.example.com> にアクセスするとサンプルプログラムが表示されます


##Rollback/Activate and Code Lifecycle
wiring アプリケーションを修正し、front-end アプリをリビルドする例を示します。

###Fork the Repository
下記のリポジトリを、各自のGitリポジトリに fork します。

~~~
https://github.com/openshift/ruby-hello-world
~~~

###Update the BuildConfig
**BuildConfig** は 次のコマンドで取得できます。

~~~
[alice@ose3-master beta4]$ oc get buildconfig ruby-hello-world -o yaml
apiVersion: v1
kind: BuildConfig
metadata:
  creationTimestamp: 2015-07-17T17:13:10Z
  name: ruby-hello-world
  namespace: wiring
  resourceVersion: "29573"
  selfLink: /osapi/v1beta3/namespaces/wiring/buildconfigs/ruby-hello-world
  uid: 1989de99-2ca7-11e5-b1a5-000c29bb6935
spec:
  output:
    to:
      kind: ImageStreamTag
      name: ruby-hello-world:latest
  resources: {}
  source:
    git:
      uri: https://github.com/openshift/ruby-hello-world
    type: Git
  strategy:
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: ruby:latest
        namespace: openshift
    type: Source
  triggers:
  - github:
      secret: Aw3H7WmwNVkyXnRUA-9k
    type: GitHub
  - generic:
      secret: XvnW85O2MpKSOx0lFeYi
    type: Generic
  - imageChange:
      lastTriggeredImageID: registry.access.redhat.com/openshift3/ruby-20-rhel7:latest
    type: ImageChange
status:
  lastVersion: 1
~~~

現在の設定では、 GitHub の openshift/ruby-hello-world リポジトリを参照していますので、**oc edit** コマンドで各自のリポジトリに変更します。

~~~
[alice@ose3-master beta4]$ oc edit bc ruby-hello-world 
~~~
変更内容は **oc get bc** コマンドのSOURCEで確認できます

~~~
[alice@ose3-master beta4]$ oc get bc
NAME               TYPE      SOURCE
ruby-hello-world   Source    https://github.com/riry111/ruby-hello-world
~~~

###Change the Code
fork した 各自のコード **views/main.rb** を次のように変更します

~~~
<div class="page-header" align=center>
  <h1> This is my crustom demo! </h1>
</div>
~~~


###Start a Build with a Webhook

webhookの接続先は、 **c describe bc** で取得できます。

~~~
[alice@ose3-master beta4]$ oc describe bc ruby-hello-world
~~~

Webhookのレコードを抽出。実行時の seret (**XvnW85O2MpKSOx0lFeYi**) は自動生成されている
~~~
Webhook GitHub:		https://ose3-master.example.com:8443/oapi/v1/namespaces/wiring/buildconfigs/ruby-hello-world/webhooks/Aw3H7WmwNVkyXnRUA-9k/github
Webhook Generic:	https://ose3-master.example.com:8443/oapi/v1/namespaces/wiring/buildconfigs/ruby-hello-world/webhooks/XvnW85O2MpKSOx0lFeYi/generic
~~~

最初に現在の build を確認します

~~~
[alice@ose3-master beta4]$ oc get build
NAME                 TYPE      STATUS     POD
ruby-hello-world-1   Source    Complete   ruby-hello-world-1-build
~~~
curlコマンドで、 次のコマンドを実行します

~~~
curl -i -H "Accept: application/json" \
-H "X-HTTP-Method-Override: PUT" -X POST -k \
https://ose3-master.example.com:8443/oapi/v1/namespaces/wiring/buildconfigs/ruby-hello-world/webhooks/XvnW85O2MpKSOx0lFeYi/generic
~~~

Webhook 実行後は STATUSが Running になっているが、これが Complete になったら更新が完了している。

~~~
[alice@ose3-master beta4]$ oc get build
NAME                 TYPE      STATUS     POD
ruby-hello-world-1   Source    Complete   ruby-hello-world-1-build
ruby-hello-world-2   Source    Running    ruby-hello-world-2-build
~~~

<http://ruby-hello-world.wiring.cloudapps.example.com/>にアクセスするとGitHubの更新内容が反映されていることが確認できる。

デプロイされた履歴は、alice ユーザで Web Consoleにアクセスし、Browse -> Deproyments で確認できる。同じ内容は コマンドからも確認できる。

~~~
[alice@ose3-master beta4]$ oc get replicationcontroller
~~~

###Rollback
ロールバックはCLIより次のコマンドを実行する。例では「」にロールバックしている。

~~~
[alice@ose3-master beta4]$ oc rollback ruby-hello-world-5  --dry-run
~~~
確認コマンドで問題がなければ、以下のコマンドを実行する

~~~
[alice@ose3-master beta4]$ oc rollback ruby-hello-world-5
~~~
これでブラウザからアクセスすると、文言が元に戻っている事が確認できる。


##A Simple PHP Example

### Create a PHP Project
alice ユーザで php-upload プロジェクトを作成する

### Build the APP
アプリケーションのソースは以下より取得する

~~~
https://github.com/rjleaf/openshift-php-upload-demo
~~~

1. プロジェクトの作成

	~~~
[alice@master]$ oc new-project php-upload --display-name="PHP Upload Demo" --description='Demo Project for PHP Upload'
~~~

2. アプリケーションのビルド

	alice ユーザ　で WebConsole にログインし、アプリを作成。その際に Builder Image で PHPを選択する。アプリ名は[php-upload-demo]で設定
	

	
3. route の作成
この手順は不要のはずなのだが、cloudapp.example.com のrouteが作成されないため、手作業で次のファイルを利用して　oc create -f で route を作成する

	~~~
{
  "kind": "Route",
  "apiVersion": "v1beta3",
  "metadata": {
    "name": "php-upload-route"
  },
  "spec": {
    "host": "php-upload-demo.php-upload.cloudapps.example.com",
    "to": {
      "name": "php-upload-demo"
    }
  }
}
~~~

4. ブラウザで下記にアクセスし、PHPアプリが起動する事を確認

	~~~
http://php-upload-demo.php-upload.cloudapps.example.com/form.html
~~~

###Kill Your Pod
oc delete コマンドを利用して アプリケーションを削除し、ローカルのファイルを確認してください。私たちはアプリケーション用の永続的なストレージを持っていません。
podが削除された場合は、ローカルに対して実施した変更は失われてしまう。その場合に備え、OpenShifでは Persistent Strage の機能も存在します。


##Using Persistent Storage (Optional)
スキップ

##Lifecycle Pre and Post Deployment Hooks

###Quickly Clean Up
過去のデプロイやロールバックを削除する場合のコマンド

~~~
oc get pod |\
grep -E "[0-9]-build" |\
awk {'print $1'} |\
xargs -r oc delete pod
~~~


##Arbitrary Docker Image (Builder)

###Create a Project

~~~
[alice@master]$ oc new-project wordpress --display-name="Wordpress" \
--description='Building an arbitrary Wordpress Docker image'
~~~

###Build Wordpress

~~~
[alice@master]$ oc new-app -l name=wordpress https://github.com/openshift/centos7-wordpress.git
~~~

Build を開始する

~~~
[alice@master]$ oc start-build centos7-wordpress
~~~

ブラウザから実行可能にするため、route と service を作成。
以下のyaml を oc create -f <ファイル名> で実行する

~~~
{
  "metadata":{
    "name":"wordpress-additional-items"
  },
  "kind":"List",
  "apiVersion":"v1beta3",
  "creationTimestamp":"2014-09-18T18:28:38-04:00",
  "items":[
    {
      "kind": "Route",
      "apiVersion": "v1beta3",
      "metadata": {
        "name": "wordpress-route"
      },
      "spec": {
        "host": "wordpress.cloudapps.example.com",
        "to": {
          "name": "wordpress-httpd-service"
        }
      }
    },
    {
      "kind": "Service",
      "apiVersion": "v1beta3",
      "metadata": {
        "name": "wordpress-httpd-service"
      },
      "spec": {
        "selector": {
          "name": "wordpress"
        },
        "ports": [
          {
            "protocol": "TCP",
            "port": 80,
            "targetPort": 80
          }
        ]
      }
    }
  ]
}
~~~


### EAP Example
1. テンプレートの作成

	~~~
oc create -f eap6-basic-sti.json
~~~

2. EAPテンプレート用の secret を作成

	~~~
oc create -f eap-app-secret.json
~~~

3. プロジェクトを作成し、変更権限をユーザに付与

	~~~
oc new-project eap --display-name="eap-quickstart" --description='eap-quickstart'oadm policy add-role-to-user admin root -n eap
~~~

4. ブラウザからWebコンソールにログインしテンプレートで **eap6-basic-sti** を選択後、下記のパラメータを変更し、Createを実行する。

	パラメータ | 設定値
--- | ---
APPLICATION_NAME | helloworld
APPLICATION_HOSTNAME | helloworld.cloudapps.example.com
GIT_URL | https://github.com/jboss-developer/jboss-eap-quickstarts
GIT_REF | 6.4.x
GIT_CONTEXT_DIR | helloworld
GITHUB_TRIGGER_SECRET | secret
GENERIC_TRIGGER_SECRET | secret

	[追加情報]　**GIT_CONTEXT_DIR** を初期表示の kitchensink にしておくと、kitchenshinkサンプルアプリをBuildする事になる。

5. Buildの状況確認

	~~~
oc get pod
oc log kitchensink-1-build -f
~~~

6. アプリケーションの動作確認
ブラウザから下記のURLにアクセスする

	~~~
http://helloworld.cloudapps.example.com/jboss-helloworld
~~~


以　上
