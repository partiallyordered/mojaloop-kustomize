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

It is the author's contention that the Kustomize implementation is
- more configurable
- more understandable
- less than 1/10th the size
- less maintenance

## Try It
You'll need Kustomize v3.10.0 or later (pretty new).

Build the manifests:
```sh
kustomize build base/mojaloop
```

Validate (you'll need `kubeval`, but you should get it anyway!):
```sh
kustomize build base/mojaloop | kubeval
```

Deploy:
```sh
kustomize build base/mojaloop | kubectl apply -f -
```

Destroy:
```sh
kustomize build base/mojaloop | kubectl delete -f -
```
