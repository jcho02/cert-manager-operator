#!/usr/bin/env bash
# builds the operator and its OLM catalog index and pushes it to quay.io.
#
# To push to your own registry, enter your own image inputs
# i.e:
#   $ IMG=quay.io/${repo}/cert-manager-operator BUNDLE_IMG=quay.io/${repo}/cert-manager-operator-bundle INDEX_IMG=quay.io/${repo}/cert-manager-operator-index ./hack/build.sh
#
# REQUIREMENTS:
#  * a valid login session to a container registry.
#  * `docker`
#  * `yq`
#  * `jq`
#  * `opm`
#  * `skopeo`
#
# NOTE: this script will modify the following files:
#  - bundle/manifests/quay-operator.clusterserviceversion.yaml
#  - bundle/metadata/annotations.yaml
# if `git` is available it will be used to checkout changes to the above files.
# this means that if you made any changes to them and want them to be persisted,
# make sure to commit them before running this script.
set -e
function multi-arch() {
	make image-build-multi-arch IMG=$1
	make bundle IMG=$1
	make bundle-image-build-multi-arch BUNDLE_IMG=$2
	declare -r AMD64_DIGEST=$(skopeo inspect --raw  docker://${REGISTRY}/${NAMESPACE}/cert-manager-operator-bundle:${TAG} | \
               jq -r '.manifests[] | select(.platform.architecture == "amd64" and .platform.os == "linux").digest')
	declare -r POWER_DIGEST=$(skopeo inspect --raw  docker://${REGISTRY}/${NAMESPACE}/cert-manager-operator-bundle:${TAG} | \
               jq -r '.manifests[] | select(.platform.architecture == "ppc64le" and .platform.os == "linux").digest')
	make index-image-build-multi-arch BUNDLE_IMG=$2 INDEX_IMG=$3 AMD64_DIGEST=$(AMD64_DIGEST) PPC64LE_DIGEST=$(PPC64LE_DIGEST)
	make index-image-push-multi-arch INDEX_IMG=$3

}

main() {
	multi-arch $1 $2 $3
	return $?
}

main "$@"
