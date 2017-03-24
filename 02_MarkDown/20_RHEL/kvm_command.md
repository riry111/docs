##KVM 使い方メモ

* IPアドレスの確認

~~~
1) 定義している仮想マシンの確認
	virsh list --all
	
2) MACアドレス確認
	virsh domiflist <ホスト名>

3) ARP より IPアドレス確認 (2)の MACアドレスを活用
	arp -e
~~~


* 仮想マシンの起動・停止

~~~
1) 定義している仮想マシンの確認
	virsh list --all

2) 仮想マシンの起動
	virsh start  <ホスト名>

3) 仮想マシンの停止
	virsh shutdown <ホスト名>

4) 仮想マシンの強制終了
	virsh destroy <ホスト名>

5) 仮装マシンへのコンソール接続
	virsh console ドメイン名
~~~

* 仮想マシンの 削除 / Clone 作成

~~~
1) 既存仮想マシンの削除
	virsh undefine <ホスト名>

2) 仮想マシンの Clone
	virt-clone --original rhel7-min --name cicd01 \
	--file /var/lib/libvirt/images/cicd01.qcow2
~~~

---

### 仮想マシンのコンソールを有効にする
1. RHEL6 までの場合

1) /etc/grub.conf にカーネルオプションを追加設定

	~~~
kernel /vmlinuz-2.6.18-238.el6 の最後に 次の記述を追加する
console=tty0 console=ttyS0,115200n8
~~~

2) /etc/inittab にコンソールモードの設定を追加する
	
	~~~
S0:12345:respawn:/sbin/agetty ttyS0 115200
~~~

3) 仮想マシン reboot 後、コンソール接続を実施

	~~~
# virsh console <ドメイン名>
~~~

2. RHEL7 の場合

1) /etc/default/grub ファイルに次の記述を追加

	~~~
GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
~~~

2) GRUBの変更を有効にするため次のコマンドを実行
	
	~~~
# grub2-mkconfig -o /boot/grub2/grub.cfg
~~~

3) 仮想マシン reboot 後、コンソール接続を実施

	~~~
# virsh console <ドメイン名>
~~~

---

### 仮想マシンに固定IPを払い出す (デフォルトの仮想ネットワークを利用)
* default ネットワークの設定を変更

~~~
# virsh net-edit default
~~~

* <dhcp> 以下に固定アドレスを登録する

~~~
<network>
  <name>default</name>
  <uuid>635f418b-5c9b-40ed-93bc-f7b598352eb6</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:77:71:1e'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.99'/>
      <host mac='52:54:00:06:0e:9d' name='docker-reg' ip='192.168.122.201'/>
      <host mac='52:54:00:a4:42:aa' name='docker' ip='192.168.122.202'/>
      <host mac='52:54:00:90:9e:ad' name='repo02' ip='192.168.122.202'/>
      <host mac='52:54:00:11:77:04' name='cicd01' ip='192.168.122.204'/>
      <host mac='52:54:00:ab:8d:2a' name='cicd02' ip='192.168.122.205'/>
    </dhcp>
  </ip>
</network>
~~~

*ネットワークを再起動する

~~~
# virsh net-destroy default
# virsh net-start default
~~~

* 固定アドレスが登録されている事を確認する

~~~
# cat /var/lib/libvirt/dnsmasq/default.hostsfile
52:54:00:06:0e:9d,192.168.122.201,docker-reg
52:54:00:a4:42:aa,192.168.122.202,docker
52:54:00:90:9e:ad,192.168.122.202,repo02
52:54:00:11:77:04,192.168.122.204,cicd01
52:54:00:ab:8d:2a,192.168.122.205,cicd02
~~~

* VMを停止・起動して指定したアドレスが設定される事を確認する

---

### 仮想サーバのネットワークをブリッジ接続にする

1. ホストサーバ側で ブリッジI/F br0 を作成する

	1) /etc/sysconfig/network-scripts/ifcfg-br0 を作成する
	
	~~~
DEVICE=br0
TYPE=Bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=dhcp
~~~

2. ホストの I/F enp0s25 を初期化して enp0s25 を br0 に接続

	1) /etc/sysconfig/network-scripts/ifcfg-enp0s25 を変数する	
	* BRIDGE=br0 を追加
	* BOOTPROTO=dhcp をコメントアウト (もしくは none に変更)

	~~~
BRIDGE=br0
#BOOTPROTO=dhcp
~~~


3. 仮想マシン側の設定を変更し インターフェースを br0 に設定

	1) 仮想マシンのinterface 設定を bridgeに変更  (rhev-m01 の場合)
	
	~~~
# virsh edit rhev-m01
~~~

	2) interface の記述を以下に変更する。 type='network' の記述は削除

	~~~
<interface type='bridge'>
      <mac address='52:54:00:25:5e:f5'/>
      <source bridge='br0'/>
</interface>
~~~

	[参考] 変更前の interface設定
	
	~~~
<interface type='network'>
		<mac address='52:54:00:25:5e:f5'/>
		<source network='default'/>
		<model type='rtl8139'/>
		<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
</interface>
~~~

4. 仮想マシンを再起動

	* 再起動後は、DICPサーバからアドレスを取得している
	* アドレスはコンソール接続 virsh console でログインして確認する

---

### 既存のKVMイメージを利用する方法

1. 既存のKVMイメージを /var/lib/libvirt/images　にコピー
2. /etc/libvirt/qemu 以下の他のKVM設定ファイルをコピーし次の4点を変更

	~~~
<name>rhel6.5-cicd</name>
<uuid>cb2c541d-f086-4e83-8d38-eccef40c2566</uuid>
<source file='/var/lib/libvirt/images/rhel6.5-cicd.qcow2'/>
<mac address='52:54:00:11:77:04'/>
~~~


3. 作成した設定ファイルより KVMを起動

	~~~
[root@intelnuc images]# virsh create /etc/libvirt/qemu/rhel6.5-cicd.xml 
ドメイン rhel6.5-cicd が /etc/libvirt/qemu/rhel6.5-cicd.xml から作成されました
~~~

### KVMに仮想IFを追加する
[参考] <http://qiita.com/masahixixi/items/4eb014eff723d39552ec>

1. kvmの設定を修正

	~~~
[root@intelnuc ~]# virsh edit rhosp7d
===========
    <interface type='bridge'>
      <source bridge='virbr0'/>
      <model type='virtio'/>
    </interface>
===========    
~~~

2. kvmの設定を反映後、rhosp7d を起動する

	~~~
[root@intelnuc ~]# virsh define /etc/libvirt/qemu/rhosp7d.xml 
[root@intelnuc ~]# virsh start rhosp7d
~~~

3. rhosp7d に SSHログインし I/Fを確認する

	~~~
[root@intelnuc ~]# ssh rhosp7d
root@rhosp7d's password: 
Last login: Tue Nov 10 18:49:23 2015 from 192.168.122.1
[root@rhosp7d ~]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:3e:9b:26 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.210/24 brd 192.168.122.255 scope global dynamic ens3
       valid_lft 3266sec preferred_lft 3266sec
    inet6 fe80::5054:ff:fe3e:9b26/64 scope link 
       valid_lft forever preferred_lft forever
3: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:e6:50:38 brd ff:ff:ff:ff:ff:ff
 ~~~
 
 
### fedra23のKVMイメージ/設定ファイルを RHEL7.1に移行
 
1. /etc/libvirt/qemu 以下に xml ファイルをコピー
2. /var/lib/libvirt/images 以下に データファイルをコピー
3. xml ファイルの記述を2箇所修正

	~~~
 [root@intel qemu]# diff cicd01.xml  /root/work/etc/libvirt/qemu/cicd01.xml 
15c15
 <     <type arch='x86_64' machine='pc-i440fx-rhel7.0.0'>hvm</type>
---
>     <type arch='x86_64' machine='pc-i440fx-2.3'>hvm</type>
39c39
<     <emulator>/usr/libexec/qemu-kvm</emulator>
---
>     <emulator>/usr/bin/qemu-kvm</emulator>
~~~

4. virsh create コマンドを実行
	
	~~~
[root@intel qemu]# virsh create /etc/libvirt/qemu/cicd01.xml
ドメイン cicd01 が /etc/libvirt/qemu/cicd01.xml から作成されました
~~~

5. リスト登録

	~~~
[root@intel images]# virsh define /etc/libvirt/qemu/cicd01.xml
~~~


### KVMのスナップショット
[参考URL KVMのスナップショット](http://blog.etsukata.com/2013/07/virsh.html)

* Internal スナップショット取得

	~~~
[root@intel images]# virsh snapshot-create-as rhev-h01 sn_init_rhev-h01 "Initial SnapShot"
ドメインのスナップショット sn_init_rhev-h01 が作成されました
[root@intel images]# virsh snapshot-list rhev-h01
 名前               作成時間              状態
------------------------------------------------------------
 sn_init_rhev-h01     2015-11-26 19:22:41 +0900 shutoff
 ~~~

* 現時点でどのスナップショットを使っているか確認

	~~~
# virsh snapshot-info rhev-h01 --current
~~~

* Internal スナップショットへの切り戻し
 
	~~~
 # virsh snapshot-revert rhev-h01 sn_init_rhev-h01 
~~~

* Internal スナップショットの削除

	~~~
# virsh snapshot-delete rhev-h01 sn_init_rhev-h01 
~~~

### nested KVM の設定
* kvmのサーバ内でkvmを使う場合は nested kvmの設定が必要
	* KVMホストにて次のコマンドを実行後、再起動

	~~~
# echo "options kvm-intel nested=1" >/etc/modprobe.d/kvm-intel.conf
~~~
	
	* 対象のKVMゲストOSの cpu 設定情報変更 (vmxの設定追加)

	~~~
# virsh edit ドメイン名
<cpu mode='custom' match='exact'>
		<model fallback='allow'>Broadwell-noTSX</model>
		<feature policy='require' name='vmx'/>
</cpu>
~~~


## RHEL6.7 kickstart インストール

* kickstart ファイル /root/Scripts/rhel6/rhev-mgr01_ks.cfg 準備

~~~
# see also: http://red.ht/hvPnf3
install
cdrom
text
bootloader
keyboard jp106
lang ja_JP.UTF-8

rootpw redhat1!

timezone Asia/Tokyo --utc

selinux --enforcing
skipx
authconfig --enableshadow --passalgo=sha512

firewall --service=ssh

network --device=eth0 --onboot=yes --bootproto=static --ip=192.168.99.84 --netmask=255.255.255.0 --gateway=192.168.99.1  --hostname=rhev-mgr01 --nameserver=192.168.99.51,8.8.8.8

zerombr
clearpart --all --initlabel
part /boot --size=500         --asprimary
part pv.100 --size=1 --grow
volgroup vg0 pv.100
logvol /    --name=lv_root --vgname=vg0 --size=1 --grow
logvol swap --name=lv_swap --vgname=vg0 --size=4096 --fstype=swap

reboot

%packages
@core
@japanese-support
@server-policy
%end
~~~

* KVM用のDISK qcow2 100GB で作成

~~~
# qemu-img create -f qcow2 /var/lib/libvirt/images/rhev-mgr01.qcow2 100G
~~~

* virsh install で KVMインストール実行

~~~
virt-install \
  --name rhev-mgr01 \
  --hvm \
  --virt-type kvm \
  --ram 2048 \
  --vcpus 1 \
  --arch x86_64 \
  --os-type linux \
  --os-variant rhel6 \
  --boot hd \
  --disk /var/lib/libvirt/images/rhev-mgr01.qcow2 \
  --network bridge=br0 \
  --graphics none \
  --location /opt/iso/rhel-server-6.7-x86_64-dvd.iso \
  --initrd-inject /root/Scripts/rhel6/rhev-mgr01_ks.cfg \
  --extra-args='ks=file:/rhev-mgr01_ks.cfg console=tty0 console=ttyS0,115200n8 keymap=ja'
~~~

## RHEL7.1 kickstart インストール

* kickstart ファイル /root/Scripts/rhel7/rhev-hpv01_ks.cfg 準備

~~~
cdrom
text
bootloader
# Run the Setup Agent on first boot
firstboot --enable
# Keyboard layouts
keyboard --vckeymap=jp --xlayouts='jp','us'
# System language
lang ja_JP.UTF-8 --addsupport=en_US.UTF-8

rootpw redhat1!

# System timezone
timezone Asia/Tokyo --isUtc

selinux --enforcing
skipx
authconfig --enableshadow --passalgo=sha512

firewall --service=ssh

network --device=eth0 --onboot=yes --bootproto=static --ip=192.168.99.85 --netmask=255.255.255.0 --gateway=192.168.99.1  --hostname=rhev-hpv01 --nameserver=192.168.99.51,8.8.8.8

user --groups=wheel --name=mamurai --password=$6$3aigJWK5h8S1hlfq$LPPird/WpJQEa9TPAKI/8xFLrrYLiYrdcvAxGMr4yBSTccAsN.NGWLwWehSW8IHc3mi.MB5a8EzMM.yuLewsc1 --iscrypted --gecos="Masatoshi Murai"

# System bootloader configuration
bootloader
# Partition clearing information
clearpart --none --initlabel
# Disk partitioning information
part /boot --fstype="xfs" --size=500
part pv.124 --fstype="lvmpv" --size=1 --grow
volgroup rhel --pesize=4096 pv.124
logvol swap  --fstype="swap" --size=2048 --name=swap --vgname=rhel
logvol /  --fstype="xfs" --grow --maxsize=51200 --size=1024 --name=root --vgname=rhel


reboot


%packages
@core
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end
~~~

* KVM用のDISK qcow2 100GB で作成

~~~
# qemu-img create -f qcow2 /var/lib/libvirt/images/rhev-hpv01.qcow2 100G
~~~

* virsh install で KVMインストール実行

~~~
virt-install \
  --name rhev-hpv01 \
  --hvm \
  --virt-type kvm \
  --ram 2048 \
  --vcpus 1 \
  --arch x86_64 \
  --os-type linux \
  --os-variant rhel6 \
  --boot hd \
  --disk /var/lib/libvirt/images/rhev-hpv01.qcow2 \
  --network bridge=br0 \
  --graphics none \
  --location /opt/iso/rhel-server-7.1-x86_64-dvd.iso \
  --initrd-inject /root/Scripts/rhel7/rhev-hpv01_ks.cfg \
  --extra-args='ks=file:/rhev-hpv01_ks.cfg console=tty0 console=ttyS0,115200n8 keymap=ja'
~~~
