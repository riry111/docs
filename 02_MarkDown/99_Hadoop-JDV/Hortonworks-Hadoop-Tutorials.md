# Develop with Haddop

## Apache Spark on HDP
###Interacting with Data on HDP using Scala and Apache Spark* カンマ区切りのCSVを作成しインポーする。 データは下記のURLから入手

		http://jp.hortonworks.com/hadoop-tutorial/interacting-with-data-on-hdp-using-scala-and-apache-spark/
		
*  hadoop の /tmp ディレクトリ littlelog.csv をインポート

		hadoop fs -put ./littlelog.csv /tmp/

*  Spark Shell を起動

		spark-shell

* littlelog.csv より RRD を作成

		val file = sc.textFile("hdfs://sandbox.hortonworks.com:8020/tmp/littlelog.csv")

*  上記で作成した file の一覧を出力

		file.foreach(println)
		
#### littlelog.csvの6番目の要素を取得したい

* 空行のを排除する　(「_」はワイルドカードのこと)

		val fltr = file.filter(_.length > 0)

* カンマ区切りで6番目の要素(index 5) を取得

		val keys = fltr.map(_.split(",")).map(a => a(5))


* 取得した keys を表示

		keys.collect().foreach(println)

#### 同じキーワードが何回出てきているか確認する

* key-value の形にマッピングする value は 1

		val stateCnt = keys.map(key => (key,1))

* RRDのユーティリティメソッド countByKey で出現回数をカウント

		val lastMap = stateCnt.countByKey

* 結果を確認

		lastMap.foreach(println)

* 出力結果　(key と 出現回数 が表示される)

		(ny,2)
		(ca,2)
		(fl,1)
		(id,1)##Using Hive with ORC from Apache Spark
* 本チュートリアルを実施するためには、Apache Spark 1.3.1へのバージョンアップが必要

		http://hortonworks.com/hadoop-tutorial/using-apache-spark-technical-preview-with-hdp-2-2/

* データセットのダウンロード

		wget http://hortonassets.s3.amazonaws.com/tutorial/data/yahoo_stocks.csv
		
* HDFS へファイルをコピー (確認)

		hadoop fs -put ./yahoo_stocks.csv /tmp/
		hadoop fs -ls  /tmp/

* Spark Shell 起動

		./spark-shell --master yarn-client --driver-memory 512m --executor-memory 512m
		
* ライブラリのimport (scala> プロンプトで実行)

		import org.apache.spark.sql.hive.orc._
		import org.apache.spark.sql._

### HiveContextの作成
* HiveContxt は　Spark SQL 実行エンジンのインスタンスでHiveのデータストアのこと。

		val hiveContext = new org.apache.spark.sql.hive.HiveContext(sc)

### Create ORC tables
* ORCはHadoop ワークロードにカラムを定義することができ、大量データの中から特定のデータを素早く検索することができる。

		hiveContext.sql("create table yahoo_orc_table (date STRING, open_price FLOAT, high_price FLOAT, low_price FLOAT, close_price FLOAT, volume INT, adj_price FLOAT) stored as orc")

###　Loading the file and creating a RDD
* CSVファイルをRDDに読み込む

		val yahoo_stocks = sc.textFile("hdfs://sandbox.hortonworks.com:8020/tmp/yahoo_stocks.csv")


* RDDの1行目を header という変数に入れる

		val header = yahoo_stocks.first

* headerの内容確認

		scala> header
		res1: String = Date,Open,High,Low,Close,Volume,Adj Close

* RDD データ行を data という変数に入れる

		val data = yahoo_stocks.filter(_(0) != header(0))

* data の１行目を確認

		scala> data.first
		res2: String = 2015-04-28,44.34,44.57,43.94,44.34,7188300,44.34

### Creating a schema
* スキーマYahooStockPriceを定義

		case class YahooStockPrice(date: String, open: Float, high: Float, low: Float, close: Float, volume: Integer, adjClose: Float)
		
		
### Attaching the schema to the parsed data
* Yahoo stock price オブジェクトのRDDを作成しテーブルに登録する　(to.DFは Spark 1.3.1が必要)

		val stockprice = data.map(_.split(",")).map(row => YahooStockPrice(row(0), row(1).trim.toFloat, row(2).trim.toFloat, row(3).trim.toFloat, row(4).trim.toFloat, row(5).trim.toInt, row(6).trim.toFloat)).toDF()


* stockprice データ確認 (1行目、全データ)

		stockprice.first
		stockprice.show

* stockprise スキーマの確認

	~~~
scala> stockprice.printSchema
root
 |-- date: string (nullable = true)
 |-- open: float (nullable = false)
 |-- high: float (nullable = false)
 |-- low: float (nullable = false)
 |-- close: float (nullable = false)
 |-- volume: integer (nullable = true)
 |-- adjClose: float (nullable = false)
	~~~

### Registering a temporary table
* Spark SQL にてデータアクセス可能にする

		price.registerTempTable("yahoo_stocks_temp")

### Querying against the table
* Spark SQLを利用してデータにアクセスする。このテーブルはHiveのテーブルではない。RDDをSQLで検索しているだけ

		val results = sqlContext.sql("SELECT * FROM yahoo_stocks_temp")

* SQLの結果をロードした results を表示する

		results.map(t => "Stock Entry: " + t.toString).collect().foreach(println)
		

### Saving as an ORC file
* RDDの結果を Hive ORC table に入れて永続化する

		results.saveAsOrcFile("yahoo_stocks_orc")


### Reading the ORC file
* ORCファイルを参照するために hiveContxt を作成

		val hiveContext = new org.apache.spark.sql.hive.HiveContext(sc)
		
* ORCファイル「yahoo_stocks_orc」を読み込む

		val yahoo_stocks_orc = hiveContext.orcFile("yahoo_stocks_orc")
		
* テンポラリーテーブル orcTest　を登録する

		yahoo_stocks_orc.registerTempTable("orcTest")

* クエリを実行する
 
		hiveContext.sql("SELECT * from orcTest").collect.foreach(println)
		hiveContext.sql("SELECT * from orcTest WHERE Date like '1996-04%'").collect.foreach(println)


以　上
