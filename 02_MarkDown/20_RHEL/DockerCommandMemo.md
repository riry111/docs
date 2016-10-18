##docker コマンドメモ

* 参考URL

		http://qiita.com/curseoff/items/a9e64ad01d673abb6866


* RHEL上にDockerインストール
	- サブスクリプション登録

		~~~
# subscription-manager repos --enable=rhel-7-server-extras-rpms
~~~

	- Dockerインストール、サービス起動設定

		~~~
# yum install docker -y
# systemctl start docker.service
# systemctl enable docker.service
~~~

	- 状況確認

		~~~
# systemctl status docker.service
# docker info
~~~


* Docker イメージのexport

		docker commit <コンテナID> <image名>
		docker save <image名>:<TAG> | gzip -c > /tmp/image.tgz

		docker commit c6a5ddf2d02b jbossdv610ws
		docker save jbossdv610ws:latest | gzip -c > /tmp/jbossdv610ws.tgz
		
* Docker Image ファイルからのimport

		# docker load -i jbossdv610ws.tgz

##dockerイメージの履歴 registry側の情報
pullしたイメージ自体に記録された履歴は docker historyで確認できることを
お伝えしました。一方、それとは別に registry へのpushした履歴がregistry側
に記録されています。REST apiで確認できます。

####RHEL6系列について出力する::

~~~
   [localhost]~$ curl -s https://registry.access.redhat.com/v1/repositories/rhel6/tags | python -mjson.tool
   {
	"6.5-11": "dbb4ad53beb6972d3639a16b4505d06d37695a8a494158d564742c24d94c1067",
	"6.5-12": "8dc6a04270dfb41460bd53968e31b14da5414501c935fb67cf25975af9066925",
	"6.5-15": "17352558d51211e3d6c3206eadf8fbf00e4846f12859c7197e72e6a8cc123678",
	"6.6-6": "f5f0b338bbd638990291e60a1c731434a0964a565b6e92880dc73ab1162c2127",
	"6.7-2": "393e5dc554d8b19e7469c33dd6d057f0bd152b874ede0f16cf2797b4d30c2768",
	"6.7-9": "258e7ab39e91c269810a7cabc431122175302b2042bcd744d006959880e44769",
	"latest": "393e5dc554d8b19e7469c33dd6d057f0bd152b874ede0f16cf2797b4d30c2768"
   }
~~~

####RHEL7系列について出力する::

~~~
   [localhost]~$ curl -s https://registry.access.redhat.com/v1/repositories/rhel7/tags | python -mjson.tool
   {
	"7.0-21": "e1f5733f050b2488a17b7630cb038bfbea8b7bdfa9bdfb99e63a33117e28d02f",
	"7.0-23": "bef54b8f8a2fdd221734f1da404d4c0a7d07ee9169b1443a338ab54236c8c91a",
	"7.0-27": "8e6704f39a3d4a0c82ec7262ad683a9d1d9a281e3c1ebbb64c045b9af39b3940",
	"7.1-11": "d0a516b529ab1adda28429cae5985cab9db93bfd8d301b3a94d22299af72914b",
	"7.1-4": "10acc31def5d6f249b548e01e8ffbaccfd61af0240c17315a7ad393d022c5ca2",
	"7.1-6": "65de4a13fc7cf28b4376e65efa31c5c3805e18da4eb01ad0c8b8801f4a10bc16",
	"7.1-9": "e3c92c6cff3543d19d0c9a24c72cd3840f8ba3ee00357f997b786e8939efef2f",
	"latest": "d0a516b529ab1adda28429cae5985cab9db93bfd8d301b3a94d22299af72914b"
   }
~~~

####RHEL6.7だけに限定して出力する::
~~~
   [localhost]~$ curl -s https://registry.access.redhat.com/v1/repositories/rhel6.7/tags | python -mjson.tool
   {
	"6.7-2": "393e5dc554d8b19e7469c33dd6d057f0bd152b874ede0f16cf2797b4d30c2768",
	"latest": "393e5dc554d8b19e7469c33dd6d057f0bd152b874ede0f16cf2797b4d30c2768"
   }
~~~


## Docker HUBのイメージの起動例
* PostgreSQL起動	~~~# docker run --name pg1 -p 5432:5432 -e POSTGRES_PASSWORD=postgres -d  postgres~~~

* MySQL起動	~~~# docker run --name my1 -p 3306:3306 -e MYSQL_ROOT_PASSWORD=mysql -d  mysql~~~

* WordPress起動 (MySQLとの連携が必要)

	~~~
# docker run --name wp1 -p 8080:80 -e WORDPRESS_DB_HOST=192.168.172.251:3306 \    -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=mysql -d wordpress~~~

## Docker HUB Push

* V1 を指定し Docker Hub にログイン

	~~~
docker login https://index.docker.io/v1/
==== Output ===
Username: mamurai
Password: 
Email: mamurai@redhat.com
WARNING: login credentials saved in /root/.docker/config.json
Login Succeeded
==== Output ===
~~~

* Docker images を commit

~~~
# docker commit eap6 docker.io/mamurai/eap64_256m-openshift
# docker commit <コンテナ名> <イメージ名>
~~~

* Docker push

~~~
# docker push docker.io/mamurai/eap64_256m-openshift
~~~