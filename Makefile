BAML ?= baml
.PHONY: check test pack clean
check:
	$(BAML) check --agent-skill-check off
test:
	$(BAML) test --agent-skill-check off
pack:
	$(BAML) pack PositionOf --agent-skill-check off
clean:
	rm -f forty-two-i
	rm -rf .baml baml_client baml_sdk
