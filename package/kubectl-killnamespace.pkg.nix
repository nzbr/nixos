# http://stackoverflow.com/questions/52369247/ddg#53661717

{ writeShellScriptBin, bash, curl, kubectl, jq, ... }:
writeShellScriptBin "kubectl-killnamespace" ''
  #!${bash}/bin/bash -eux

  NAMESPACE=$1
  kubectl proxy &
  sleep 1s

  ${kubectl}/bin/kubectl get namespace $NAMESPACE -o json | ${jq}/bin/jq '.spec = {"finalizers":[]}' >/tmp/temp.json
  ${curl}/bin/curl -k -H "Content-Type: application/json" -X PUT --data-binary @/tmp/temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize

  kill %1
''
