## docker image 作成スクリプト

dir | os | 説明
--- | --- | ---
db-pgsql | centos6 | Postgres9.3　と サンプルデータ 
rails | fedora20 | ruby-rails サンプルアプリ postgresが必要<br>コンテナ起動時に [--link pgsql01:db] を指定する
eap6.4 | rhel7 | JBoss EAP 6.4.0のインストールと db-pgsql接続のためのdatasource作成までを実施

###db-pgsql 
centos6上に Postgresql 9.3を導入。サンプルDBとして apaccustomers と jpcustomersを作成
~~~
-bash-4.2# docker build -t mamurai/pgsql ./db-pgsql
-bash-4.2# docker run -itd --name pgsql01 mamurai/pgsql
~~~

###rails
~~~
-bash-4.2# docker build -t mamurai/rails ./rails
-bash-4.2# docker run -itd -p 8000:80 --link pgsql01:db --name rails01 mamurai/rails 
~~~
railsアプリの動作確認は、ブラウザより
**http://<host Address>:8000/messages** にアクセス。

### eap6.4
**[前提条件]**

* ./software 以下に JBossEAP6.4「jboss-eap-6.4.0.zip」が必要

~~~
-bash-4.2# docker build -t mamurai/eap6.4 ./eap6.4
-bash-4.2# docker run -p 8080:8080 -p 9990:9990 -p 9999:9999 -itd --link pgsql01:db --name eap6.4 mamurai/eap6.4
~~~
Dockerfile実行時のCLIを起動してデータソースを作成することを試みたが、環境変数をDatasourceの接続URLに指定して動作させることに失敗。
テンプレートのstandalone.xml を準備し、docker run 初回起動時に　sedでキーワードとアドレス/ポート番号を変換している。詳細はDockerfile及び、コンテナ内の **/home/jboss/run.sh**を参照
