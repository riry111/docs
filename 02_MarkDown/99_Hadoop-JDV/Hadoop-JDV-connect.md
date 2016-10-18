### Evolving your data into strategic asset using HDP and Red Hat JBoss Data Virtualization

本手順では、HortonworksのSandboxを利用しHaddoop実行環境を入手。hiveのテーブルを作成し、JDBC経由でテーブルにアクセスする手順を示す。

* 参照URL

		http://hortonworks.com/hadoop-tutorial/evolving-data-stratagic-asset-using-hdp-red-hat-jboss-data-virtualization/

**STEP1** hortonworks-sandbox のインストール

**STEP2** Hadoop用データ tweetsbi.csv のロード

* CSVをHDFSへ取り込む

	- HCatalogツールを使いFileからテーブルを作成する　http://192.168.172.175:8000/hcatalog/　を開き Tables > Create a new table from a file を選択
	-  テーブル名を入力、デリミネータをカンマに変更しテーブル作成

### MySQLにSalesデータをインポート
**Step1:** mysql adminユーザ作成


~~~
mysql
mysql> use mysql
Database changed
mysql> GRANT ALL ON *.* to admin@'192.168.172.%' IDENTIFIED BY 'admin';

mysql> select user,host,password from mysql.user;
~~~

**STEP2:** サンプルデータをダウンロードしサーバ上にコピー

* 取得元URL
	
~~~
https://github.com/DataVirtualizationByExample/HortonworksUseCase1/tree/master/SupportingFiles
~~~
	
**STEP3:**データロード

	mysql < sales-create-table-and-data.sql 

**STEP4:** MySQLデータ取得テスト

	mysql -u admin -p'admin' hadoopworld
	select * from sales;

### HiveへDBクライアントから接続
**重要**
チュートリアルに付属していた「hive-jdbc-0.11.0.jar」を利用して、SQLクライアントからHive-HDPに接続する際、Class Not Foundエーラが発生。下記URLより別のドライバーのソースをダウンロード後、mvn package を実行してbuild target 以下の「hive-jdbc-uber-2.2.4.2.jar」を利用すれば接続可能

	https://github.com/timveil/hive-jdbc-uber-jar

### JDV Virtual Database のインストール

**Step 1:** https://github.com/kpeeples/simplified-dv-template.git を Clone
**Step 2:** JDV をダウンロード
**Step 5:** JDVを起動後、MySQLとHive-HDPのデータソースを作成

* JDBCドライバーの登録　(以下の例では、/User/mamurai/work/driver 以下にドライバーが格納済)

~~~
module add --name=com.mysql.jdbc.Driver --resources=/Users/mamurai/work/driver/mysql-connector-java-5.1.34-bin.jar --dependencies=javax.api,javax.transaction.api/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql, driver-module-name=com.mysql.jdbc.Driver, driver-class-name=com.mysql.jdbc.Driver)module add --name=org.apache.hive.jdbc.HiveDriver --resources=/Users/mamurai/work/driver/hive-jdbc-uber-2.2.4.2.jar --dependencies=javax.api,javax.transaction.api/subsystem=datasources/jdbc-driver=hive-jdbc:add(driver-name=hive-jdbc, driver-module-name=org.apache.hive.jdbc.HiveDriver, driver-class-name=org.apache.hive.jdbc.HiveDriver)~~~

* データソース作成
~~~data-source add --name=MySQLSalesModel --connection-url=jdbc:mysql://192.168.172.175:3306/hadoopworld --jndi-name=java:/MySQLSalesModel --driver-name=mysql --user-name=admin --password=admin data-source enable --name=MySQLSalesModeldata-source add --name=HiveConnection --connection-url=jdbc:hive2://192.168.172.175:10000/default --jndi-name=java:/HiveConnection --driver-name=hive-jdbc --user-name=hive --password="" data-source enable --name=HiveConnection
~~~


###JBDSからHiveへの接続注意点
	
* JBDSからHiveのモデルをimport することはできるが、Preview Data 実施時に、データソースのパスワードなしで登録できないため、エラーが発生する。
* Import時に嘘のパスワードを登録後、EAP管理車画面 or CLI から Preview DataSource用のパスワードを削除する 
* Hiveの物理モデルのTranslator は [jdbc-simple]  hiveの場合、エラーが発生する以　上