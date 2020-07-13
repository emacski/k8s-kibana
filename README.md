# DEPRECATED

This project is **obsolete** and no longer maintained. Refer to https://kubernetes.io/docs/home/ for kubernetes logging configuration.

## Kubernetes Kibana

Alternative kibana docker image designed as a drop-in replacement for the kibana-image in the fluentd-elasticsearch cluster-level logging addon.

**Components**

| Component | Version |
| --------- | ------- |
| kibana | 6.4.2 |

**Configuration**

Uses [ReDACT](https://github.com/emacski/redact) for simple kibana configuration.

| Environment Variable | Description |
| -------------------- | ----------- |
| `kibana_base_url` | The base url to serve kibana from, useful if proxying kibana (Default: `/`) |
| `kibana_elasticsearch_url` | The url of the Elasticsearch instance kibana uses for all queries (Default: `http://localhost:9200`) |

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
          - name: "kibana_elasticsearch_url"
            value: "http://elasticsearch-logging:9200"
          - name: "kibana_base_url"
            value: "/api/v1/proxy/namespaces/kube-system/services/kibana-logging"
        ports:
        - containerPort: 5601
          name: ui
          protocol: TCP
```

**Example Service**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kibana-logging
  namespace: kube-system
  labels:
    kubernetes.io/name: "Kibana Logging"
    kubernetes.io/cluster-service: "true"
    k8s-app: kibana-logging
spec:
  ports:
  - port: 5601
    protocol: TCP
    targetPort: ui
  selector:
    k8s-app: kibana-logging
```
