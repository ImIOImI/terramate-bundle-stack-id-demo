.PHONY: generate show clean
generate:
	terramate generate
	terramate generate

show: generate
	@for b in deterministic lazy; do \
	  echo "== $$b =="; \
	  echo "  producer id       : $$(grep -o 'id *= *\"[^\"]*\"' stacks/$$b/producer/stack.tm.hcl)"; \
	  echo "  consumer from_stack: $$(grep from_stack_id stacks/$$b/consumer/component_consumer__tmgen-sharing-inputs.tm.hcl | grep -o '\"[^\"]*\"')"; \
	done

clean:
	find stacks -name .terraform -type d -prune -exec rm -rf {} + 2>/dev/null || true
	find stacks -name '*.tfstate*' -delete 2>/dev/null || true
	find stacks -name .terraform.lock.hcl -delete 2>/dev/null || true
