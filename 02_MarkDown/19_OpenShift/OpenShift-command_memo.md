## OpenShift コマンドメモ

* login

~~~
# oc login -u system:admin; oc project openshift-infra
~~~

* pod AutoScale

~~~
# oc autoscale dc/hello-openshift --min 1 --max 5 --cpu-percent=80
~~~

* HorizontalPodAutoscaler ステータス確認

~~~
# oc get hpa/hello-openshift -n justanother
~~~

* HorizontalPodAutoscaler 設定確認
 
~~~
# oc describe hpa/hello-openshift -n justanother
~~~

* node Label表示

~~~
# oc get nodes --show-labels
~~~

* 全てのnamespace のpodを表示

~~~
# oc get pods --all-namespaces -o wide
~~~

* 各ノードで動いているPodをリストアップ

~~~
# oadm manage-node node1.example.com --list-pods
~~~

* node の Labelを上書き

~~~
# oc label node/infranode1.example.com region=primary --overwrite
~~~

* namespace の node-selector で region を指定
* 
~~~
# oc annotate namespace openshift-infra openshift.io/node-selector='region=infra' --overwrite
~~~

##権限関連

* プロジェクトに対して権限の付与確認 (ローカル)

~~~
# oc describe policybindings :default -n portalapp-dev
~~~

* 権限付与一覧の確認

~~~
# oc describe clusterpolicy default
~~~

* プロジェクトに対して権限の付与確認 (グローバル)

~~~
# oc describe clusterpolicybindings :default -n portalapp-dev
~~~

* ユーザーのプロジェクト作成権限 削除、追加

~~~
# oadm policy remove-cluster-role-from-group \
 self-provisioner system:authenticated:oauth
# oadm policy  add-cluster-role-to-group self-provisioner system:authenticated:oauth
~~~

* 権限の確認

~~~
# oc describe clusterpolicybindings :default -n default
~~~

## OSE DNSデバッグ

~~~
[root@master00 ~]# oadm diagnostics DiagnosticPod
~~~

正常なら以下のような記述になった。以上じは赤字で Error 発生

~~~
[Note] Determining if client configuration exists for client/cluster diagnostics
Info:  Successfully read a client config file at '/root/.kube/config'

[Note] Running diagnostic: DiagnosticPod
       Description: Create a pod to run diagnostics from the application standpoint
       
WARN:  [DCli2013 from diagnostic DiagnosticPod@openshift/origin/pkg/diagnostics/client/run_diagnostics_pod.go:157]
       See the warnings below in the output from the diagnostic pod:
       [Note] Running diagnostic: PodCheckAuth
              Description: Check that service account credentials authenticate as expected
              
       Info:  Service account token successfully authenticated to master
       Info:  Service account token was authenticated by the integrated registry.
       
       [Note] Running diagnostic: PodCheckDns
              Description: Check that DNS within a pod works as expected
              
       WARN:  [DP2008 from diagnostic PodCheckDns@openshift/origin/pkg/diagnostics/pod/dns.go:86]
              Received unexpected return code 'SERVFAIL' from nameserver 8.8.8.8:
              This may indicate a problem with non-cluster DNS.
              
       [Note] Summary of diagnostics execution (version v3.2.1.15):
       [Note] Warnings seen: 1
       
[Note] Summary of diagnostics execution (version v3.2.1.15):
[Note] Warnings seen: 1
~~~

# 古いコマンドメモバックアップ

##ログイン関連
コマンド | 説明
--- | ---
oc login -u system:admin | system:admin で OpenShiftにログイン
oc config view --flatten | ログイン tocken、証明書の確認
oc whoami -c | ログイン状況の確認
oc whoami -t | tocken の確認
oc new-app -o json https://github.com/openshift/simple-openshift-sinatra-sti.git | gitのコードから app作成時の JSONを出力

## Set alias

~~~
alias ocd='/bin/oc describe'
alias ocg='/bin/oc get'
alias osl='/bin/oc login -u joe --certificate-authority=/etc/openshift/master/ca.crt  --server=https://ose3-master.example.com:8443'
~~~

##プロジェクト作成関連
コマンド | 説明
--- | ---
oc new-project wiring --display-name="Exploring Parameters" \ <br> --description='An exploration of wiring using parameters' | プロジェクト作成 
oc new-app -o json https://github.com/openshift/simple-openshift-sinatra-sti.git | アプリケーションの作成
oc delete **dc** php-upload-demo <br>oc delete **pod** php-upload-demo-1-build <br>oc delete **service** php-upload-demo <br>oc delete **route** php-upload-demo php-upload-route <br>oc delete **imagestream** php-upload-demo <br>oc delete **bc** php-upload-demo <br>oc delete **build** php-upload-demo-1 | アプリケーションの削除。<br>左記のリソースの削除が必要
oc project wiring | プロジェクトの変更


###過去のビルドやロールバックを削除する

~~~
oc get pod |\
grep -E "[0-9]-build" |\
awk {'print $1'} |\
xargs -r oc delete pod
~~~

再ビルドを実行する

~~~
oc start-build ruby-example
~~~

* アプリケーションのBuild結果を確認

~~~
 # oc logs -f build/<build_name>
~~~
 - Cf. <https://docs.openshift.com/enterprise/3.1/dev_guide/builds.html#accessing-build-logs>

* ノードの一覧、イベント、ステータスを確認

~~~
 # oc get node
 # oc get all,events,status -n default
 # oc get all,events,status -n <project> 
~~~

* openshift-master/openshift-nodeのログを出力

~~~
 # journalctl -u atomic-openshift-master >   openshift-master.log
 # journalctl -u atomic-openshift-node >   openshift-node.log
~~~
 - Cf. Troubleshooting OpenShift Enterprise 3 <https://access.redhat.com/solutions/1542293>


* 前提となる各種情報

~~~
* システム構成図
* OpenShift構築手順や結果　　※その他、参照した資料があればご提示下さい。
* Ansible Inventoryファイル (/etc/ansible/hosts)
* 構築後に手動で追加/変更した設定
~~~



