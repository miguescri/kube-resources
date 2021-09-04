# kube-resources

A simple tool built on top of [jq](https://stedolan.github.io/jq/) that summarizes the CPU and memory 
requests/limits in Kubernetes manifests. It takes into consideration `HorizontalPodAutoscaler`
objects that may affect the number of replicas.

The output is a JSON array containing an object for each workload resource (Pod, Deployment, StatefulSet...)
found in the input. The output is consistent regardless of the order of the inputs files or the keys in the 
YAML, so it can be used with `diff` to identify changes exclusively related to the definition of CPU and 
memory.

## Requirements

The `kuberes` script needs:

- [bash](https://www.gnu.org/software/bash/)
- [jq](https://stedolan.github.io/jq/)
- [yq](https://github.com/kislyuk/yq)
- Python >= 3.6
- [Pint](https://pint.readthedocs.io/en/stable/) Python package

## Usage

Choose an operation mode and pass the names of the files to parse as parameters or pipe the YAML text. 
The latter option is useful in combination with `helm template`.

```shell
./kuberes m2 example/*
# or
cat example/deployment.yaml | ./kuberes m2
```

Take into consideration that YAML documents need to be explicitly separated by `---`, so doing something 
like this will not work as expected:

```shell
cat example/* | ./kuberes m2 # Documents are appended one after the other without using ---
```

## Modes

The tool provides different working modes depending on the desired level of information aggregation.

The following outputs correspond to running the tool on the files of the examples folder.

### m0

Raw information from the YAML files. Also add minReplicas and maxReplicas values based on 
Horizontal Pod Autoscalers.

```json
[
  {
    "apiVersion": "apps/v1",
    "containers": [
      {
        "image": "httpd",
        "name": "httpd",
        "resources": {
          "limits": {
            "cpu": "500m",
            "memory": "1024Mi"
          },
          "requests": {
            "cpu": "250m",
            "memory": "256Mi"
          }
        }
      },
      {
        "image": "fluentd",
        "name": "fluentd",
        "resources": {
          "limits": {
            "cpu": "200m",
            "memory": "256Mi"
          },
          "requests": {
            "cpu": "50m",
            "memory": "128Mi"
          }
        }
      }
    ],
    "kind": "Deployment",
    "maxReplicas": 5,
    "minReplicas": 1,
    "name": "my-deplo"
  },
  {
    "apiVersion": "apps/v1",
    "containers": [
      {
        "image": "httpd",
        "name": "httpd",
        "resources": {
          "limits": {
            "cpu": "500m",
            "memory": "1024Mi"
          },
          "requests": {
            "cpu": "250m",
            "memory": "256Mi"
          }
        }
      },
      {
        "image": "fluentd",
        "name": "fluentd",
        "resources": {
          "limits": {
            "cpu": "200m",
            "memory": "256Mi"
          },
          "requests": {
            "cpu": "50m",
            "memory": "128Mi"
          }
        }
      }
    ],
    "kind": "Deployment",
    "maxReplicas": 3,
    "minReplicas": 3,
    "name": "my-other-deplo"
  },
  {
    "apiVersion": "v1",
    "containers": [
      {
        "image": "nginx",
        "name": "my-pod",
        "resources": {
          "limits": {
            "cpu": "200m",
            "memory": "512Mi"
          },
          "requests": {
            "cpu": "100m",
            "memory": "256Mi"
          }
        }
      },
      {
        "image": "fluentd",
        "name": "sidecar",
        "resources": {
          "limits": {
            "cpu": "50m",
            "memory": "50Mi"
          },
          "requests": {
            "cpu": "10m",
            "memory": "25Mi"
          }
        }
      }
    ],
    "kind": "Pod",
    "maxReplicas": 1,
    "minReplicas": 1,
    "name": "my-pod"
  }
]
```

### m1

Top level objects with lists of the underlying container requests and limits.

```json
[
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "limits": {
      "cpu": [
        "500m",
        "200m"
      ],
      "memory": [
        "1024Mi",
        "256Mi"
      ]
    },
    "maxReplicas": 5,
    "minReplicas": 1,
    "name": "my-deplo",
    "requests": {
      "cpu": [
        "250m",
        "50m"
      ],
      "memory": [
        "256Mi",
        "128Mi"
      ]
    }
  },
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "limits": {
      "cpu": [
        "500m",
        "200m"
      ],
      "memory": [
        "1024Mi",
        "256Mi"
      ]
    },
    "maxReplicas": 3,
    "minReplicas": 3,
    "name": "my-other-deplo",
    "requests": {
      "cpu": [
        "250m",
        "50m"
      ],
      "memory": [
        "256Mi",
        "128Mi"
      ]
    }
  },
  {
    "apiVersion": "v1",
    "kind": "Pod",
    "limits": {
      "cpu": [
        "200m",
        "50m"
      ],
      "memory": [
        "512Mi",
        "50Mi"
      ]
    },
    "maxReplicas": 1,
    "minReplicas": 1,
    "name": "my-pod",
    "requests": {
      "cpu": [
        "100m",
        "10m"
      ],
      "memory": [
        "256Mi",
        "25Mi"
      ]
    }
  }
]
```


### m2

Top level objects with the sum of the underlying container requests and limits.

```json
[
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "limits": {
      "cpu": "700 ms",
      "memory": "1280 MiB"
    },
    "maxReplicas": 5,
    "minReplicas": 1,
    "name": "my-deplo",
    "requests": {
      "cpu": "300 ms",
      "memory": "384 MiB"
    }
  },
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "limits": {
      "cpu": "700 ms",
      "memory": "1280 MiB"
    },
    "maxReplicas": 3,
    "minReplicas": 3,
    "name": "my-other-deplo",
    "requests": {
      "cpu": "300 ms",
      "memory": "384 MiB"
    }
  },
  {
    "apiVersion": "v1",
    "kind": "Pod",
    "limits": {
      "cpu": "250 ms",
      "memory": "562 MiB"
    },
    "maxReplicas": 1,
    "minReplicas": 1,
    "name": "my-pod",
    "requests": {
      "cpu": "110 ms",
      "memory": "281 MiB"
    }
  }
]
```

## Ordering and deterministic output

The output follows a set of rules to make it deterministic:

- Resources are sorted by name.
- If there are resources that share name, they are ordered by kind (Pod, Deployment...).
- Object keys are sorted alphabetically

However, the tool, does not take into consideration namespace. 
