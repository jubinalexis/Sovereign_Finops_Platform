.PHONY: infra-up infra-down check-nodes

infra-up:
	cd infra/terraform && terraform init && terraform apply -auto-approve

infra-down:
	cd infra/terraform && terraform destroy -auto-approve

check-nodes:
	kubectl get nodes
