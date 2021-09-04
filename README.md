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

Pass the names of the files to parse as parameters or pipe the YAML text. The latter option is useful
in combination with `helm template`.

```shell
./kuberes example/*
# or
cat example/deployment.yaml | ./kuberes
```

Take into consideration that YAML documents need to be explicitly separated by `---`, so doing something 
like this will not work as expected:

```shell
cat example/* | ./kuberes  # Documents are appended one after the ohter without using ---
```

## Ordering and deterministic output

The output follows a set of rules to make it deterministic:

- Resources are sorted by name.
- If there are resources that share name, they are ordered by kind (Pod, Deployment...).
- Object keys are sorted alphabetically

However, the tool, does not take into consideration namespace. 

## Example

The `example` folder contains a couple of Kubernetes resources that lead to the following output:

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
