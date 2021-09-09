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
./kuberes sum example/*
# or
cat example/deployment.yaml | ./kuberes sum
```

Take into consideration that YAML documents need to be explicitly separated by `---`, so doing something 
like this will not work as expected:

```shell
cat example/* | ./kuberes sum # Documents are appended one after the other without using ---
```

### Docker

A Dockerfile is included in case you prefer not to install locally the dependencies.

```shell
docker build -t kuberes:latest .
```

Mount the folder with the Kubernetes resources into `/data` and pass the usual CLI parameters:

```shell
docker run --rm -v $PWD/example:/data:ro kuberes sum '/data/*'    
```


## Modes

The tool provides different working modes depending on the desired level of information aggregation.

The following outputs correspond to running the tool on the files of the examples folder.

### raw

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

### list

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


### sum

Top level objects with the sum of the underlying container requests and limits.

```json
[
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "limits": {
      "cpu": "700ms",
      "memory": "1280MiB"
    },
    "maxReplicas": 5,
    "minReplicas": 1,
    "name": "my-deplo",
    "requests": {
      "cpu": "300ms",
      "memory": "384MiB"
    }
  },
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "limits": {
      "cpu": "700ms",
      "memory": "1280MiB"
    },
    "maxReplicas": 3,
    "minReplicas": 3,
    "name": "my-other-deplo",
    "requests": {
      "cpu": "300ms",
      "memory": "384MiB"
    }
  },
  {
    "apiVersion": "v1",
    "kind": "Pod",
    "limits": {
      "cpu": "250ms",
      "memory": "562MiB"
    },
    "maxReplicas": 1,
    "minReplicas": 1,
    "name": "my-pod",
    "requests": {
      "cpu": "110ms",
      "memory": "281MiB"
    }
  }
]
```

### minmax

Top level objects with minRequests, minLimits, maxRequests and maxLimits, taking into consideration minReplicas 
and maxReplicas.
```json
[
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "limits": {
      "cpu": {
        "max": "3500ms",
        "min": "700ms"
      },
      "memory": {
        "max": "6400MiB",
        "min": "1280MiB"
      }
    },
    "maxReplicas": 5,
    "minReplicas": 1,
    "name": "my-deplo",
    "requests": {
      "cpu": {
        "max": "1500ms",
        "min": "300ms"
      },
      "memory": {
        "max": "1920MiB",
        "min": "384MiB"
      }
    }
  },
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "limits": {
      "cpu": {
        "max": "2100ms",
        "min": "2100ms"
      },
      "memory": {
        "max": "3840MiB",
        "min": "3840MiB"
      }
    },
    "maxReplicas": 3,
    "minReplicas": 3,
    "name": "my-other-deplo",
    "requests": {
      "cpu": {
        "max": "900ms",
        "min": "900ms"
      },
      "memory": {
        "max": "1152MiB",
        "min": "1152MiB"
      }
    }
  },
  {
    "apiVersion": "v1",
    "kind": "Pod",
    "limits": {
      "cpu": {
        "max": "250ms",
        "min": "250ms"
      },
      "memory": {
        "max": "562MiB",
        "min": "562MiB"
      }
    },
    "maxReplicas": 1,
    "minReplicas": 1,
    "name": "my-pod",
    "requests": {
      "cpu": {
        "max": "110ms",
        "min": "110ms"
      },
      "memory": {
        "max": "281MiB",
        "min": "281MiB"
      }
    }
  }
]
```

### total

Summary of the total minRequests, minLimits, maxRequests and maxLimits across all objects.


This information means that your pods:

- To just exist without activity, need `.requests.memory.min` MiB and `.requests.cpu.min` milicores available in
the cluster.
- To fully scale out to the max number of replicas, need `.requests.memory.max` MiB and `.requests.cpu.max` milicores 
available in the cluster.
- If fully scaled out, will try to phagocyte up to `.limits.memory.max` MiB and `.requests.cpu.min` milicores.

```json
[
  {
    "limits": {
      "cpu": {
        "max": "5850ms",
        "min": "3050ms"
      },
      "memory": {
        "max": "10802MiB",
        "min": "5682MiB"
      }
    },
    "requests": {
      "cpu": {
        "max": "2510ms",
        "min": "1310ms"
      },
      "memory": {
        "max": "3353MiB",
        "min": "1817MiB"
      }
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
