plan:
	terraform plan

cost: install_infracost
	infracost breakdown --path . --show-skipped

apply:
	terraform apply -auto-approve

destroy:
	terraform destroy
	
install_infracost:
	@infracost --version || (brew install infracost &&	infracost register)