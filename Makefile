#!/usr/bin/env make -f
SHELL := /bin/bash


WAVEBOOK_RELEASE ?= alpha
WAVEBOOK_NS      ?= wavebook


.DEFAULT_GOAL := apply
default: apply ;

clean: apply_clean \
	namespace_clean context_clean ;


.PHONY: default clean \
	apply apply_clean \
	secret \
	namespace namespace_clean \
	context context_clean ;


# {{{ `kubectl apply`
apply: secret namespace
	@kubectl apply -f ./kube-system/

apply_clean: context namespace
	@kubectl delete -f ./kube-system/  ||  true
# }}}


# {{{ Kubernetes: Namespace & Context
KUBE_NS     := $(WAVEBOOK_NS)-$(WAVEBOOK_RELEASE)
KUBE_DRIVER ?= minikube

namespace:
	@kubectl get namespaces $(KUBE_NS) || \
		kubectl create namespace $(KUBE_NS)

namespace_clean:
	@kubectl delete namespaces $(KUBE_NS)

context:
	@[[ $$(kubectl config current-context) == $(KUBE_DRIVER) ]] || \
		kubectl config set-context $(KUBE_DRIVER) \
		--namespace=$(KUBE_NS) \
		--cluster=$(KUBE_DRIVER) \
		--user=$(KUBE_DRIVER)
	@kubectl config use-context $(KUBE_DRIVER)

context_clean:
	@kubectl config delete-context $(WAVEBOOK_RELEASE)
	@kubectl config use-context $(KUBE_DRIVER)
# }}}


# {{ wavebook secrets
AUTH_SECRET  ?= basic-auth
AUTH_FILE    ?= auth

secret: $(AUTH_FILE) context
	@$(NOSTDOUT) kubectl get secrets $(AUTH_SECRET) \
		|| kubectl -n=$(KUBE_NS) create secret generic $(AUTH_SECRET) \
			--from-file=$<
# }}


# {{ kops
kops-create:
	kops create cluster \
		--cloud=aws \
		--authorization=rbac \
		--dns-zone=ZZQOY5B8Q5FBB \
		--image=951350789146/k8s-1.12-debian-stretch-amd64-hvm-ebs-2019-05-14 \
		--api-ssl-certificate=arn:aws:acm:ap-east-1:951350789146:certificate/77f7f0ef-d8e1-4e47-a316-3657a2d9ff57 \
		--encrypt-etcd-storage \
		--zones=ap-east-1a,ap-east-1b,ap-east-1c \
		--master-size=m5.large \
		--node-size=m5.large \
		--node-count=2 \
		${KUBE_DRIVER}
# }}


# {{ Makefile helpers
NOSTDOUT := 1>/dev/null
NOSTDERR := 2>/dev/null
# }}

