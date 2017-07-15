[![Build Status](https://travis-ci.org/emacski/k8s-kibana.svg?branch=master)](https://travis-ci.org/emacski/k8s-kibana)

Kubernetes Kibana
-----------------

Alternative kibana docker image designed as a drop-in replacement for the
kibana-image in the fluentd-elasticsearch cluster-level logging addon.

**Components**

| Component | Version |
| --------- | ------- |
| kibana | 5.5.0 |

**Configuration**

| Environment Variable | Description |
| -------------------- | ----------- |
| `KIBANA_BASE_URL` | The base url to service kibana from, useful if proxying kibana (Default: `/` or `/api/v1/proxy/namespaces/kube-system/services/kibana-logging` for `-proxy` images) |
| `KIBANA_ELASTICSEARCH_URL` | The url of the Elasticsearch instance kibana uses for all queries (Default: `http://localhost:9200`) |
| `KIBANA_EXTENDED_CONFIG` | Used to add custom additional configuration directives (Default: empty) |

**Images**

Two images are produced to help speed up provisioning of the Kibana containers.

The first and default image has Kibana configured to be accessed at the root
url (example: http://kibana.myorg.com/). This is useful when using NodePorts
or load balancers for cluster services.

The second image (the suffix `-proxy` is appended to the image tag) pre-builds
the Kibana assets to be accessed at a proxy path assumed to be `/api/v1/proxy/namespaces/kube-system/services/kibana-logging`.
This is suitable for use with `kubectl proxy` (example: http://localhost:8001/api/v1/proxy/namespaces/kube-system/services/kibana-logging).
Note that the actual path is determined by the Kibana Kubernetes service definition.
The example service definition below produces the above proxy path.

Either of these images can use the `KIBANA_BASE_URL` env variable to override the
proxy path, but this will require Kibana to rebuild assets for each new container
instance at runtime.

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
        image: emacski/k8s-kibana:latest-proxy
        resources:
          # keep request = limit to keep this container in guaranteed class
          limits:
            cpu: 100m
          requests:
            cpu: 100m
        env:
          - name: "KIBANA_ELASTICSEARCH_URL"
            value: "http://elasticsearch-logging:9200"
          # when using a "-proxy" image, the following is not required
          - name: "KIBANA_BASE_URL"
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
