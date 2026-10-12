FVM ?= fvm
FLUTTER := $(FVM) flutter
DART := $(FVM) dart

APP_DIR ?= app
CLI_DIR ?= cli

# Override for another static-hosting provider:
#   make app-deploy APP_DEPLOY_CMD='./scripts/deploy.sh'
APP_DEPLOY_CMD ?= firebase deploy --only hosting

# Flags of the cli CLI (see cli/README.md); they override .env values:
#   make cli-qr-generate QR_ARGS='--access-key ... --secret-key ... --bucket ... --region ... --base-url ... --output card.svg'
# Without QR_ARGS, values are read from the root .env (see .env.example).
QR_ARGS ?=

# Heart decoration (used by cli-qr-generate-heart; cli-qr-generate always
# renders a plain QR code without a heart):
#   make cli-qr-generate-heart HEART_SCALE=0.8 HEART_PADDING=1.2
#   make cli-qr-generate-heart HEART_MODE=cut   # clip instead of frame
#   make cli-qr-generate-heart HEART_VSHIFT=0.2 # code higher inside the heart
HEART_MODE ?=
HEART_SCALE ?=
HEART_PADDING ?=
HEART_VSHIFT ?=
HEART_ARGS := $(if $(HEART_MODE),--heart-mode $(HEART_MODE),) $(if $(HEART_SCALE),--heart-scale $(HEART_SCALE),) $(if $(HEART_PADDING),--heart-padding $(HEART_PADDING),) $(if $(HEART_VSHIFT),--heart-vshift $(HEART_VSHIFT),)

# Export .env values to recipes (git-ignored; never commit real secrets).
-include .env
export

.PHONY: app-start app-deploy format cli-qr-generate cli-qr-generate-heart .check-qr-config

app-start: ## Run the guest app
	cd $(APP_DIR) && $(FLUTTER) run --web-port=53618

app-deploy: ## Build and deploy the guest app
	cd $(APP_DIR) && $(FLUTTER) clean && $(FLUTTER) pub get
	cd $(APP_DIR) && $(FLUTTER) build web --release
	$(APP_DEPLOY_CMD)

format: ## Code formatting
	find app/lib app/test cli/bin cli/lib cli/test -name "*.dart" \
		! -name "*.g.dart" \
		! -name "*.freezed.dart" \
		! -path "lib/l10n/*" \
		! -path "lib/util/assets/*" \
		| xargs fvm dart format


.check-qr-config:
	@if [ -z "$(QR_ARGS)" ] && [ ! -f .env ]; then \
		echo "Missing configuration."; \
		echo "Create .env from .env.example, or pass flags directly:"; \
		echo "  make cli-qr-generate QR_ARGS='--access-key ... --secret-key ... --bucket ... --region ... --base-url ... --output card.svg'"; \
		exit 2; \
	fi

cli-qr-generate: .check-qr-config ## QR card without heart (plain); QR_ARGS flags override .env values
	cd $(CLI_DIR) && $(DART) run bin/cli.dart qr-generate --heart-mode none $(QR_ARGS)

cli-qr-generate-heart: .check-qr-config ## QR card with heart decoration; tune via HEART_SCALE/HEART_PADDING/...
	cd $(CLI_DIR) && $(DART) run bin/cli.dart qr-generate $(QR_ARGS) $(HEART_ARGS)
