bash ./test/formatter.sh && source .env && forge build --sizes && forge test --fork-url $GOERLI_RPC_URL -vvvv --fork-block-number 8203582 --gas-report --watch --ffi #--via-ir
