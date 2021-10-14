# Mojaloop Kustomize POC

An incomplete proof-of-concept of Mojaloop deployed using Kustomize.

The intended audience of this document is current Mojaloop Helm users and developers in particular,
and Helm users in general.

This proof-of-concept is presented in opposition to Helm. Therefore it will, with extreme
prejudice, present downsides of Helm in contrast with Kustomize.

## Discussion

Helm's philosophy is to "package" applications and expose configuration options. The corollary is
that it makes non-exposed configurations difficult to change. This puts users at the mercy of
upstream packagers. Here are some of the consequences:
1. Parameters the author didn't expose, because "surely nobody would ever need to configure that?"-
   the Kubernetes deployment `apiVersion: apps/v1` change not propagating through upstream charts
   quickly being a good example of this problem.
2. Parameters that didn't exist at the time the chart was created not being exposed. Kubernetes is
   _adding_ fields constantly.

You might think: well, no problem, I'm not a user. Great! But you probably _have_ users. Which
means you'll eventually support all configuration options a user might be interested in. [Here's
the end state of that paradigm](https://github.com/helm/charts/blob/master/stable/jenkins/templates/jenkins-master-deployment.yaml).
In that example, the entire yaml file has simply been moved from `jenkins-master-deployment.yaml`
to `values.yaml`. Additional costs of that file include:
1. a less readable file format that requires users to understand some rather deep templating
   languages
2. maintenance of configuration options

Kustomize has a considerably different philosophy to Helm. This is to supply a minimal working
manifest that can be composed with other manifests, added to, and patched using generic yaml/json
transformation tools included with Kustomize. Example: a [minimal working manifest](./base/centralledger/handlers/base/deployment.yaml)
and a [generic yaml transformation](./base/centralledger/handlers/transfer-fulfil/kustomization.yaml).
The transformation can modify any aspect of the manifest- it's not restricted to the configurations
exposed by the maintainers.

## Comparison

### Implementation Size

We make a shallow comparison of the implementations:
```sh
$ cat base/{centralledger,account-lookup-service,ml-api-adapter,mojaloop}/**/*.yaml | wc -l
918
```

The same exercise on https://github.com/mojaloop/helm :
```sh
$ cat {central,centralledger,ml-api-adapter,account-lookup-service}/**/*.yaml | wc -l
12646
# central/**/*.json is empty
$ cat {centralledger,ml-api-adapter,account-lookup-service}/**/*.json | wc -l
4292
```

Industry studies of bug density have demonstrated that number of bugs is directly proportional to
lines of code, independent of language. We can therefore conclude a representative Kustomize
implementation is very likely to contain fewer bugs.

### Maintenance

#### Configuration

The nature of Kustomize means that users are free to make their own modifications to the generated
manifests. Therefore, changes don't need to be incorporated upstream. This means:
- lower maintenance burden for Mojaloop developers
- more power for deployers- no need for changes to be incorporated upstream
- a faster development/deployment cycle for deployers- no need to merge changes upstream before they
    can be used

Kustomize has a better pattern for configuration updates than Helm, and supports automatic rolling
updates of pods when their dependent configuration (i.e. `ConfigMaps` and `Secrets`) changes. Helm
is merely a templating engine and does not have any intrinsic understanding of Kubernetes
resources. It therefore requires the user to implement these patterns. This increases maintenance
for chart developers when rolling updates are configured, correctly or otherwise; or for deployers
when rolling updates are not correctly configured.

#### Debugging

When reasoning about compatibility and versioning, Kustomize respects the deliberate decoupling of
yaml manifests and cluster resources. Helm bundles tools that break this decoupling, such as hooks.
When debugging a Helm-managed deployment, we must understand the Helm chart format, Helm's tooling,
and Kubernetes manifests. When debugging Kustomize manifests, we must understand Kustomize tooling
and Kubernetes manifests. In sum: Helm represents a considerably more complex compatibility matrix.

It is the author's opinion that Kustomize's emphasis on composition and mutation over templating,
and its use of plain yaml makes it far easier to comprehend, and means the learning curve is
smaller than that of Helm.

### Security

It is possible to compromise upstream dependencies and republish a compromised Helm chart to a Helm
repo. This applies to both dependencies _of_ Mojaloop, and, for users, _Mojaloop itself_.

Kustomize allows content-addressable references to upstream manifests. For example, a
`kustomization.yaml` can declare dependencies as follows:
```yaml
resources:
- github.com/partiallyordered/mojaloop-kustomize/base/mojaloop?ref=578e9eabc908a4d0a51054fd015b6f94c4192979
```
To subsequently compromise this upstream dependency requires a capability to generate a compromised
base that produces an sha256 hash collision. This is not known to be practically possible at present.

### Common Usage Patterns

| Activity | Helm | Kustomize |
| -------- | ---- | --------- |
| Basic deployment | `helm repo add <repo>`<br>`helm repo update`<br>`helm install <repo>/<chart>` | `kustomize build github.com/<org>/<repo>/<path>?ref=<ref> \| kubectl apply -f -` |
| Basic configuration | `helm install --set some.key=some-value <repo>/<chart>` | 1. create a `kustomization.yaml` containing configuration<br>2. `kustomize build . \| kubectl apply -f -` |
| Advanced configuration | 1. Create a `values.yaml` containing configuration<br>2. `helm install <repo>/<chart>` | 1. create a `kustomization.yaml` containing configuration<br>2. `kustomize build . \| kubectl apply -f -` |

## Try It

### Kustomize
It's best to use Kustomize v3.10.0 or later.
```sh
kustomize version
```

Build the manifests:
```sh
kustomize build https://github.com/partiallyordered/mojaloop-kustomize/base/mojaloop
```

Validate - optional (you'll need `kubeval`, but you should get it anyway!):
```sh
kustomize build https://github.com/partiallyordered/mojaloop-kustomize/base/mojaloop | kubeval
```

Deploy:
```sh
kustomize build https://github.com/partiallyordered/mojaloop-kustomize/base/mojaloop | kubectl apply -f -
```

Destroy:
```sh
kustomize build https://github.com/partiallyordered/mojaloop-kustomize/base/mojaloop | kubectl delete -f -
```

### Kubectl

You could also try `kubectl`. At the time of writing the author is unsure what versions of
`kubectl` will work correctly, so do this at your own risk.

Dry run:
```sh
kubectl apply --dry-run=client -k https://github.com/partiallyordered/mojaloop-kustomize/base/mojaloop
```

Deploy:
```sh
kubectl apply -k https://github.com/partiallyordered/mojaloop-kustomize/base/mojaloop
```

## TODO
- bundle the position and prepare handler, if possible, to reduce the resource requirement
