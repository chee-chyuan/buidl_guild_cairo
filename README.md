# StarkGuild
An EthSeoul Hackathon project proudly brought to you by Carlos Ramos, Jian Kim, WenKang Chen and CheeChyuan Ang

## Introduction
StarkGuild is a public goods project that is aimed towards promoting public goods! It is a platform that allows aspiring buidlers to submit a project proposal to a matching round in return for a potential grant from the community.

## Mechanism
### Donating & Quadratic Funding
In each matching round, there will be a a `Total Match` of which this represents the total amount of funds donated from various sponsors. This sponsored amount will be shared across all projects in the pool in a Quadratic Funding manner.

During the voting period, all registered users are able to donate any amount to their project that they like and a portion of the matched amount will be allocated to the project. 

Quadratic funding ensures a 'fair' way of distributed the total sponsored amount as a single large contribution by an individual will amount to less weightage compared to many many small donations by many different individuals.

### User Registration
To reduce the risk of donars gaming the quadratic funding mechanism by creating many accounts and donating smalls amounts through the different accounts, we have also implemented a `User registration` mechanism of which each address can only be registered to a unique github account id.

### Claiming
After the voting period ends, project owners will be able to claim their donations in a streamed fashion. The total amount will be distributed gradually over time. On top of that, from time to time, project owners will be required to submit a project report through IPFS, to allow admin to verify if actual progress has been made. The admin will be able to limit how much of the final amount the project should have gotten in the case where the progress has not reached the milestone


## Technology Used
- We are building our project on Starknet and the backend is written entirely on Cairo
- For a decnetralized file storage option, we leverage IPFS that allows us to store project info, user details, progress report in a decentralized manner.

## Contracts
- `user_registration.cairo` - Handles all user related logics, such as user registration, unique github id check
- `qf_pool.cairo` - The main logic of the matching pool that contains logic such as QF calculation, Streaming amount logic. This contract will be deployed as a contract class and will be deploy over and over again for a new pool. 
- `coreV2.cairo` - Act as a bridge between user registration and the matching pool. Also contains logic where only admin is able to create a new matching pool.

## Deploy
In `migrations/migration_01_init.cairo` change 
```
const erc20_addr = 12345
const admin = 67890 
``` 

Run the following script in the root folder, remember to change the network if we want to deploy to a local devnet

```
protostar migrate migrations/migration_01_init.cairo --no-confirm --output-dir migrations/testnet --network alpha-goerli
```

It will return us the deployment output like this: 
```
10:03:58 [INFO] (Protostar → StarkNet) DECLARE
  contract             /Users/cheechyuan/Documents/repo/buidl_guild_cairo/build/qf_pool.json
  sender_address       1
  max_fee              0
  version              0
  signature            []
  nonce                0
10:04:12 [INFO] (Protostar ← StarkNet) DECLARE
  code                 TRANSACTION_RECEIVED
  class_hash           3036680536474300139651313274859036695021649017672522577430500214226033968062
  transaction_hash     0x5ff21f801e1332d2b16386fbe741bdf3bb75a854ea807658a9a1ccc559b0400
10:04:12 [INFO] (Protostar → StarkNet) DEPLOY
  contract             /Users/cheechyuan/Documents/repo/buidl_guild_cairo/build/user_registry.json
  gateway_url          https://alpha4.starknet.io/gateway
  constructor_args     None
  salt                 None
  token                None
10:04:15 [INFO] (Protostar ← StarkNet) DEPLOY
  code                 TRANSACTION_RECEIVED
  address              3574269960381368718776077292474233250564078317446818580551328627807615191625
  transaction_hash     0x2627da32535f25b07cb75cb5789168791052f16e91d4c194b57526cb8387b48
10:04:15 [INFO] (Protostar → StarkNet) DEPLOY
  contract             /Users/cheechyuan/Documents/repo/buidl_guild_cairo/build/core.json
  gateway_url          https://alpha4.starknet.io/gateway
  constructor_args     [3036680536474300139651313274859036695021649017672522577430500214226033968062, 3574269960381368718776077292474233250564078317446818580551328627807615191625, 12345, 67890]
  salt                 None
  token                None
10:04:24 [INFO] (Protostar ← StarkNet) DEPLOY
  code                 TRANSACTION_RECEIVED
  address              1598078638023496036663754067215881644959514335320902011285602717466386552797
  transaction_hash     0x505dd859cf06cdbe6c9f622b27db2b10fa099c9b9f59f37579d7500935126c0
```
