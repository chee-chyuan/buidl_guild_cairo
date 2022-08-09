# StarkGuild
An EthSeoul Hackathon project proudly brought to you by Carlos Ramos, Jian Kim, WenKang Chen and CheeChyuan Ang


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