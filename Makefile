# Makefile

.PHONY: help

TEMP_DIR         = .tmp
PYTHON           = python3
PYTHON_VENV      = ${TEMP_DIR}/venv
BIN_DIR          = bin
## Colors
PURPLE           = \033[1;35m
RESET            = \033[0m

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  doc        to make README.md file"
	@echo "  lint       to check files using linters, from Python venv"
	@echo "  ansible    to check files using ansible-lint only, from Python venv"
	@echo "  yaml|yml   to check files using yamllint only, from Python venv"
	@echo "  clean      to remove temp directory (${TEMP_DIR})"

.PHONY: doc
doc: clean
doc:
	## Manage defaults/main.yml Markdown content
	@printf '%b\n' "${PURPLE}Remove any previous file.${RESET}"
	@rm --force -- docs/10.defaults_main.md
	@printf '%b\n' "${PURPLE}Transform the file to Markdown.${RESET}"
	@"${BIN_DIR}/yaml2md.sh" --input defaults/main.yml --dest docs/
	@printf '%b\n' "${PURPLE}Add '10.' prefix to generated Markdown file.${RESET}"
	@mv -- docs/defaults_main.md docs/10.defaults_main.md

	## Manage vars/*.yml Markdown content if exists
	@printf '%b\n' "${PURPLE}Remove any previous file.${RESET}"
	@find docs/ -name "15.vars_*.md" -delete
	@printf '%b\n' "${PURPLE}Transform the file(s) to Markdown.${RESET}"
	@"${BIN_DIR}/yaml2md.sh" --input vars/ --ignore-empty-directory --dest docs/
	@printf '%b\n' "${PURPLE}Add '15.' prefix to vars_* md file(s).${RESET}"
	@cd docs && \
		find * -maxdepth 0 -type f -name "vars_*.md" -exec mv -- {} 15.{} \;

	## Manage README.md
	@printf '%b\n' "${PURPLE}Remove any previous file.${RESET}"
	@rm --force -- README.md
	@printf '%b\n' "${PURPLE}Build README.md from docs/*.md files.${RESET}"
	@cat -- docs/*.*.md > README.md

.PHONY: lint
lint:              ## Check Ansible role using linters
lint: test-ansible-lint
lint: test-yamllint

.PHONY: ansible
ansible:           ## Check Ansible role using ansible-lint
ansible: test-ansible-lint

.PHONY: yaml

yaml:              ## Test YAML syntax using yamllint
yaml: test-yamllint

.PHONY: yml
yml:               ## Test YAML syntax using yamllint
yml: test-yamllint

.PHONY: clean
clean:
	@rm --force --recursive -- "${TEMP_DIR}"

.PHONY: test-ansible-lint
test-ansible-lint: venv
test-ansible-lint:
	@printf "%b\n" "${PURPLE}Checking Ansible content using ansible-lint...${RESET}"
	@${PYTHON_VENV}/bin/ansible-lint -v

.PHONY: test-yamllint
test-yamllint: venv
test-yamllint:
	@printf "%b\n" "${PURPLE}Checking YAML syntax using yamllint...${RESET}"
	@${PYTHON_VENV}/bin/yamllint .

.PHONY: venv
venv:
	## Manage Python VirtualEnv and required tools
	@mkdir --parents "${TEMP_DIR}"
	${PYTHON} -m venv "${PYTHON_VENV}"
	. "${PYTHON_VENV}/bin/activate" && \
	${PYTHON} -m pip install --quiet ansible-lint yamllint
