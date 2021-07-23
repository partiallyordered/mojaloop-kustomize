- should reorganise everything so that
  1. things that are actually overlays are in an overlay directory (overlays could still contain
     other overlays)
  2. bases are still deployable, and valid k8s manifests
  3. we test bases and overlays for validity
- factor some config/patches into "components" (see Kustomize components docs)
- deploy all bases and overlays
- consider replacing Kafka with Redpanda (at least optionally) to reduce resource consumption
- try to share a single mysql instance between ALS and CL
