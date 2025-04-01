# BVM

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## A lean Ethereum node with interchangeable consensus.

We took the [Go-Ethereum](https://github.com/ethereum/go-ethereum)
implementation (Geth) and extracted the EVM and Trie components to create a lean
and modular version with interchangeable consensus.

The EVM is a virtual machine specifically designed to run untrusted code on a
network of computers. Every transaction applied to the EVM modifies the State
which is persisted in a Merkle Patricia tree. This data structure allows to
simply check if a given transaction was actually applied to the VM and can
reduce the entire State to a single hash (merkle root) rather analogous to a
fingerprint.

The EVM is meant to be used in conjunction with a system that broadcasts
transactions across network participants and ensures that everyone executes the
same transactions in the same order. Ethereum uses a Blockchain and a Proof of
Work consensus algorithm. BVM makes it easy to use any consensus system,
including [Babble](https://github.com/mosaicnetworks/babble) .

## ARCHITECTURE

```
                +-------------------------------------------+
+----------+    |  +-------------+         +-------------+  |       
|          |    |  | Service     |         | State       |  |
|  Client  <-----> |             | <------ |             |  |
|          |    |  | -API        |         | -BVM        |  |
+----------+    |  |             |         | -Trie       |  |
                |  |             |         | -Database   |  |
                |  +-------------+         +-------------+  |
                |         |                       ^         |     
                |         v                       |         |
                |  +-------------------------------------+  |
                |  | Engine                              |  |
                |  |                                     |  |
                |  |       +----------------------+      |  |
                |  |       | Consensus            |      |  |
                |  |       +----------------------+      |  |
                |  |                                     |  |
                |  +-------------------------------------+  |
                |                                           |
                +-------------------------------------------+

```

## Usage

BVM is a Go library, which is meant to be used in conjunction with a 
consensus system like Babble, Tendermint, Raft, etc.

This repo contains **Solo**, a bare-bones implementation of the consensus 
interface, which is used for testing or launching a standalone node. It relays
transactions directly from Service to State.

## Configuration

The Ethereum genesis file defines Ethereum accounts and is stripped of all the 
Ethereum POW stuff. This file is useful to predefine a set of accounts that own 
all the initial Ether at the inception of the network.

Example Ethereum genesis.json defining two account:
```json
{
   "alloc": {
        "629007eb99ff5c3539ada8a5800847eacfc25727": {
            "balance": "1337000000000000000000"
        },
        "e32e14de8b81d8d3aedacb1868619c74a68feab0": {
            "balance": "1337000000000000000000"
        }
   }
}
```
## API

The Service exposes an HTTP API.  

### Get Account

Retrieve information about any account.  

```bash
host:~$ curl http://[api_addr]/account/0x629007eb99ff5c3539ada8a5800847eacfc25727 -s | json_pp
{
    "address": "0xa10aae5609643848fF1Bceb76172652261dB1d6c",
    "balance": 1234567890000000000000,
    "nonce": 0,
    "bytecode": ""
}
```

### Call

Call a smart-contract READONLY function. These calls will NOT modify the EVM
state, and the data does NOT need to be signed.

```bash
curl http://localhost:8080/call \
    -d '{"constant":true,"to":"0xabbaabbaabbaabbaabbaabbaabbaabbaabbaabba","value":0,"data":"0x8f82b8c4","gas":1000000,"gasPrice":0,"chainId":1}' \
    -H "Content-Type: application/json" \
    -X POST -s | json_pp
    {
      "data": "0x0000000000000000000000000000000000000000000000000000000000000001"
    }
```

### Submit Transaction

Send a SIGNED, NON-READONLY transaction. The client is left to compose a
transaction, sign it and RLP encode it. The resulting bytes, represented as a
Hex string, are passed to this method to be forwarded to the EVM. This is a
SYNCHRONOUS operation; it waits for the transaction to go through consensus and
returns the transaction receipt.

example:
```bash
host:~$ curl -X POST http://[api_addr]/rawtx -d '0xf86904808398968094f7cd2ba6892341e568e9d825c4bdc2bd53b7524189031b9d1340ad2500008026a04eb7420aa52a1955d26ffb16d3a8cb8d969ae0eb6d75bb5076599c42a788e08da0178b3ddb264cdcc624121f55a95ae45de119bc44a0a85b721d8958b7ebe0553a' -s | json_pp
{
   "root": "0xda4529d2bc5e8b438edee4463637eb91d5490edb50d15e786e8d5276f2a2c8f4",
   "transactionHash": "0x3f5682786828d26946e12a08a858b6dd805d1ea8f7d39d93f1d4d5393b23f710",
   "from": "0x888980abf63d4133482e50bf8233f307e3c2b941",
   "to": "0xf7cd2ba6892341e568e9d825c4bdc2bd53b75241",
   "gasUsed": 21000,
   "cumulativeGasUsed": 21000,
   "contractAddress": "0x0000000000000000000000000000000000000000",
   "logs": [],
   "logsBloom": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
   "status": 1
   }
```

### Get Transaction Receipt

Get a transaction receipt. When a transaction is applied to the EVM, a receipt
is saved to record if/how the transaction affected the state. This contains
such information as the address of a newly created contract, how much gas was
use, and the EVM Logs produced by the execution of the transaction.

example:
```bash
host:~$ curl http://[api_addr]/tx/0xeeeed34877502baa305442e3a72df094cfbb0b928a7c53447745ff35d50020bf -s | json_pp
{
   "to" : "0xe32e14de8b81d8d3aedacb1868619c74a68feab0",
   "root" : "0xc8f90911c9280651a0cd84116826d31773e902e48cb9a15b7bb1e7a6abc850c5",
   "gasUsed" : "0x5208",
   "from" : "0x629007eb99ff5c3539ada8a5800847eacfc25727",
   "transactionHash" : "0xeeeed34877502baa305442e3a72df094cfbb0b928a7c53447745ff35d50020bf",
   "logs" : [],
   "cumulativeGasUsed" : "0x5208",
   "contractAddress" : null,
   "logsBloom" : "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
}

```

## Info

The `/info` endpoint exposes a map of information provided by the consensus
system.

example (with Babble consensus):
```bash
host:-$ curl http://[api_addr]/info | json_pp
{
   "rounds_per_second" : "0.00",
   "type" : "babble",
   "consensus_transactions" : "10",
   "num_peers" : "4",
   "consensus_events" : "10",
   "sync_rate" : "1.00",
   "transaction_pool" : "0",
   "state" : "Babbling",
   "events_per_second" : "0.00",
   "undetermined_events" : "22",
   "id" : "1785923847",
   "last_consensus_round" : "1",
   "last_block_index" : "0",
   "round_events" : "0"
}

```

## CLIENT

Please refer to [BVM CLI](https://github.com/BOTCoinNetwork/BVM-cli)
for Javascript utilities and a CLI to interact with the API.

## DEV

DEPENDENCIES

We use glide to manage dependencies:

```bash
[...]/BVM$ curl https://glide.sh/get | sh
[...]/BVM$ glide install
```
This will download all dependencies and put them in the **vendor** folder; it
could take a few minutes.
