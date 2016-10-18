#firewalld 設定コマンドメモ

ゾーン確認
---
* 設定一覧の取得
	
		# firewall-cmd --list-all

* 全てのゾーンを確認する場合

		# firewall-cmd --list-all-zones

* デフォルトのゾーン確認

		# firewall-cmd --get-default-zone

* ゾーンのインターフェイスを付け替える

		# firewall-cmd --zone=trusted --change-interface=eno1

サービス関連
---
 * 各サービスの設定を変える場合、/etc/firewalld にコピーして設定する

~~~
[root@localhost ~]# cat /usr/lib/firewalld/services/http.xml 
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>WWW (HTTP)</short>
  <description>HTTP is the protocol used to serve Web pages. If you plan to make your Web server publicly available, enable this option. This option is not required for viewing pages locally or developing Web pages.</description>
  <port protocol="tcp" port="80"/>
</service>
~~~

* firewalld 設定リロード

		# firewall-cmd --reload
	
* 定義されているサービス一覧 
		
		# firewall-cmd --get-services

* 現状のzone設定を確認する

		# firewall-cmd --list-all-zones

* publicのサービス確認
		
		# firewall-cmd --list-service --zone=public 

* サービスを public zone に追加する
		
		# firewall-cmd --add-service=http --zone=public

* サービスを public zone に 恒久的に追加する
		
		# firewall-cmd --add-service=http --zone=public --permanent

* サービスを削除する
		
		# firewall-cmd --remove-service=dhcpv6-client --zone=public


* Port単位でのアクセス許可

		# firewall-cmd --permanent --add-port=80/tcp
その他
---

* Firewall 設定のリロード

		# firewall-cmd --reload
		
* サービス一覧

		# ls /usr/lib/firewalld/services/