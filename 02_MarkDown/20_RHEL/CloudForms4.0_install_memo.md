##CloudForms4.0 インストールメモ

root/smartvm でサーバにログイン後

appliance_console コマンドから次の3点を変更する

4) Set Hostname5) Set Timezone, Date, and Time8) Configure Database
14) Start EVM Server Processes##OpenShiftの接続方法http://keithtenzer.com/2015/12/04/detecting-security-vulnerabilities-in-docker-container-images/ログイン初期ユーザー
root/smartvm
admin/smartvm1. CFME service account の作成

	1) JSON スクリプトの作成
	
	~~~
[root@ose3-master ~]# vi cfme.json
{
 "apiVersion": "v1",
 "kind": "ServiceAccount",
 "metadata": {
 "name": "cfme"
 }
}
~~~

	2) default project の選択
	
	~~~
[root@ose3-master ~]# oc project default
~~~

	3) service accountの作成

	~~~
[root@ose3-master ~]# oc create -f cfme.json
~~~

	4) cluster-admin role の付与
	
	~~~
[root@ose3-master ~]# oadm policy add-cluster-role-to-user cluster-admin system:serviceaccount:default:cfme
~~~

2. tokenの取得

	1) cfmeの情報取得
	
	~~~
[root@ose3-master ~]# oc get sa cfme -o yaml
apiVersion: v1
imagePullSecrets:
- name: cfme-dockercfg-a31nt
kind: ServiceAccount
metadata:
  creationTimestamp: 2016-01-14T09:01:18Z
  name: cfme
  namespace: default
  resourceVersion: "3607"
  selfLink: /api/v1/namespaces/default/serviceaccounts/cfme
  uid: 5fda32c4-ba9d-11e5-8d2b-52540010c14f
secrets:
- name: cfme-token-8m8im
- name: cfme-dockercfg-a31nt
~~~

	2) token　の取得
	
	~~~
[root@ose3-master ~]# oc describe secret cfme-token-8m8im
Name:		cfme-token-8m8im
Namespace:	default
Labels:		<none>
Annotations:	kubernetes.io/service-account.name=cfme,kubernetes.io/service-account.uid=5fda32c4-ba9d-11e5-8d2b-52540010c14f
Type:	kubernetes.io/service-account-token
Data
====
ca.crt:	1066 bytes
token:	eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImNmbWUtdG9rZW4tOG04aW0iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiY2ZtZSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjVmZGEzMmM0LWJhOWQtMTFlNS04ZDJiLTUyNTQwMDEwYzE0ZiIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmNmbWUifQ.bpqc5Sm9bnHCPELqwxUTowSpaPvRjMbvRwksbRXfhbznjZ9JSJFDRvJqf5HLI5nUyIQE8M51XEgnEYcQ-Ub18IwGiVU6bJVtp7mhnKZAnddDOXBKcp4wzcEj-znZiw6Yo-ZCc7szOKLTc1XGT7HOHBzBk_yejrGy30Y4mDi4XrXQOCzC4QHn3gg3FDSIs-1n4XEKEOcO2gZXNHxXcft8zhfUgwsVDW8DzwhUJrQ5xpThjHaIjZya7FwCEwpSiKScG5apsXTFqzt5fejkH2zYOUtfKAFb1mqJUal1frMhMD07tXOIdadHLhji8ePavYbXPdDgRr4aXBiyaQy1EZ1h3A
 ~~~