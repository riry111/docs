#Linuxコマンド備忘録
##サブスクリプション関連

* サーバ登録、サブスクリプション紐付け

	* register

			# subscription-manager register --username=<ID> --password=<Passwd> --name <Server Name>

	* Subscripton を　attachする			# subscription-manager attach --pool 8a85f98144844aff014488d058bf15be

	* リポジトリ一覧を出力する			# LANG=C			# subscription-manager repos --list > repos-list.txt	* 一旦、全てのリポジトリを disable に設定する 			# grep 'Repo ID' repos-list.txt | sed -E 's/^Repo ID:\s+/ --disable=/' | tr -d '\n' | sed -e 's/^/subscription-manager repos/' | sh -x
			→ subscription-manager repos --list コマンドで確認すると全て　[Enabled: 0] になっている	* 必要なyumレポジトリのみ有効化する	
		~~~
	# subscription-manager repos \	 --enable=rhel-6-server-rpms \	 --enable=jb-eap-6-for-rhel-6-server-rpms
~~~

* サブスクリプション登録削除
	 
	* Check SerialNumber			
			# subscription-manager list --consumed		* unscrive
			# subscription-manager unsubscribe --serial=4702622899585238953



##ネットワーク設定関連

* ホスト名確認・変更	~~~	
    # nmcli general hostname    # nmcli general hostname osev302.local~~~* GUIでのネットワーク設定変更		
		# nmtui

* IPアドレス設定	
		# nmcli con mod eno16777736 ipv4.addresses "192.168.172.XXX/24"
		

## パケットキャプチャー関連

* tcpdump コマンドで wiresharkで読み込めるログを出力

	~~~
# tcpdump -n -s 0 -i ens3 -w dump.dat
# tcpdump -i ens3 host 192.168.xxx.xxx -w dump.dat
# tcpdump -i ens3 port 443 -w dump.dat
~~~

##シェル関連

* ファイル名のフルパスからディレクトリ作成

	~~~
$ export PFILE=/home/guest/work/dir/test.pid
$ mkdir $(dirname $PFILE)
~~~

##SSH関連
* RSAのキーペアを作って公開鍵をリモートホストにコピー

	~~~
# ssh-keygen -t rsa
# ssh-copy-id -i /root/.ssh/id_rsa.pub  root@cicd02
~~~

##インストール時の初期設定メモ

* サブスクリプション登録 (Employ Subscriptionの紐付け)

	~~~
subscription-manager register --username=mamurai1@redhat.com
subscription-manager attach --pool 8a85f98144844aff014488d058bf15be
~~~

* RPMリポジトリ 参照先設定変更 (RHEL6の場合)

	~~~
subscription-manager repos --disable="*"
subscription-manager repos --enable="rhel-6-server-rpms"
~~~

* OS Update

	~~~
yum -y update
~~~

* KVM 初期スナップショット取得

	~~~
virsh snapshot-create-as rhev-mgr01 sn_init_rhev-mgr01
~~~

## RHEL USB DISK 作成 (MAC上)

~~~
diskutil list
diskutil umountDisk /dev/disk2
sudo dd if=/Users/mamurai/Downloads/rhel-server-7.2-x86_64-dvd.iso of=/dev/rdisk2 bs=1m
~~~