.PHONY: build
build:
	forge build

.PHONY: test
test:
	forge test

.PHONY: fmt
fmt:
	forge fmt src
	forge fmt test
	forge fmt script

.PHONY: deploy
deploy:
	forge script script/Deploy.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)  --broadcast

.PHONY: verify-contract
verify-contract:
	forge verify-contract --verifier etherscan --compiler-version 0.8.27 --num-of-optimizations 999999 --guess-constructor-args
