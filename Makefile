.PHONY: generate demo clean
generate:            ## two passes: 2nd materializes the outputs-sharing _tmgen-sharing.tf
	terramate generate
	terramate generate

demo: generate       ## apply producer, then let the consumer read its output via sharing
	cd stacks/producer && tofu init >/dev/null && tofu apply -auto-approve >/dev/null
	cd stacks/consumer && tofu init >/dev/null
	terramate run -C stacks/consumer --enable-sharing -- tofu apply -auto-approve >/dev/null
	@printf '\nconsumer received: '
	@cd stacks/consumer && tofu output -raw received && echo

clean:
	find stacks -name .terraform -type d -prune -exec rm -rf {} + 2>/dev/null || true
	find stacks -name '*.tfstate*' -delete 2>/dev/null || true
	find stacks -name .terraform.lock.hcl -delete 2>/dev/null || true
