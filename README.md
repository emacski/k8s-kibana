[![Build Status](https://travis-ci.org/emacski/k8s-kibana.svg?branch=master)](https://travis-ci.org/emacski/k8s-kibana)

Kubernetes Kibana
-----------------

Alternative kibana docker image designed as a drop-in replacement for the
kibana-image in the fluentd-elasticsearch cluster-level logging addon.

**Components**

| Component | Version |
| --------- | ------- |
| kibana | 5.4.1 |

**Configuration**

| Environment Variable | Description |
| -------------------- | ----------- |
| `KIBANA_BASE_URL` | The base url to service kibana from, useful if proxying kibana (Default: `/`) |
| `KIBANA_ELASTICSEARCH_URL` | The url of the Elasticsearch instance kibana uses for all queries (Default: `http://localhost:9200`) |
| `KIBANA_EXTENDED_CONFIG` | Used to add custom additional configuration directives (Default: empty) |

**Example ReplicaSet Deployment**
```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: kibana-logging
  namespace: kube-system
  labels:
    k8s-app: kibana-logging
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: kibana-logging
  template:
    metadata:
      labels:
        k8s-app: kibana-logging
    spec:
      containers:
      - name: kibana-logging
        image: emacski/k8s-kibana:latest
        resources:
          # keep request = limit to keep this container in guaranteed class
          limits:
            cpu: 100m
          requests:
            cpu: 100m
        env:
          - name: "KIBANA_ELASTICSEARCH_URL"
            value: "http://elasticsearch-logging:9200"
          - name: "KIBANA_BASE_URL"
            value: "/api/v1/proxy/namespaces/kube-system/services/kibana-logging"
        ports:
        - containerPort: 5601
          name: ui
          protocol: TCP
```
