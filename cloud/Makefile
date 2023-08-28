.PHONY: validate
validate:
	terraform validate

.PHONY: plan
plan:
	terraform plan -var-file=config.tfvars

.PHONY: apply
apply:
	terraform apply -var-file=config.tfvars


.PHONY: destroy
destroy:
	terraform destroy -var-file=config.tfvars

.PHONY: format
format:
	terraform fmt
