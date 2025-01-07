#!/bin/bash

if [ -z $1 ]; then
  echo "RPC host should be set";
  echo "Usage: ./load_test.sh RPC_ADDR";
fi

echo "Testing RPC ${1}"
echo "Load test with flood"

docker run --rm -it ghcr.io/paradigmxyz/flood:latest eth_getBlockByNumber NODE1_NAME=$1 --rates 10 100 500 --duration 30
docker run --rm -it ghcr.io/paradigmxyz/flood:latest eth_call NODE1_NAME=$1 --rates 10 100 500 --duration 30

echo "Searching for transactions, going back from chain head"

current_block=$(curl -sSl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $1 | jq .result -r| cut -c 3-)

current_block_dec=$(printf '%d' "$((0x$current_block))")
while :
do
  echo "Current block - $current_block_dec"
  current_block_hex=0x$(printf '%x' $current_block_dec)
  transactions=$(curl -sSl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$current_block_hex"'",true],"id":1}' $1|jq .result.transactions[0])
  if [[ $transactions == 'null' ]]; then
    echo "No transaction, going deeper"
  else
    echo $transactions
    break
  fi
  current_block_dec=$((current_block_dec-1))
done
transaction_hash=$(echo $transactions|jq .hash)
transaction_block_number=$(echo $transactions|jq .blockNumber)
echo $transaction_hash
echo $transaction_block_number
echo "Testing debug_traceTransaction method, saved to .debug_traceTransaction.json"
curl -sSl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"debug_traceTransaction","params":['$transaction_hash',{"tracer": "callTracer"}],"id":1}' $1|jq . > .debug_traceTransaction.json
sleep 5
echo "Testing debug_traceBlockByNumber, saving to .debug_traceBlockByNumber.json"
curl -sSl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"debug_traceBlockByNumber","params":['$transaction_block_number', {"tracer": "callTracer"}],"id":1}' $1|jq . > .debug_traceBlockByNumber.json