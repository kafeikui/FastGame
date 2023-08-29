## Get started

Install [foundry](https://github.com/foundry-rs/foundry#installation).

Build a local chain and deploy [BLS-TSS-Network](https://github.com/ARPA-Network/BLS-TSS-Network), and the `CardGame.sol`.

```
cd contracts

forge create --private-key <local_test_account_private_key> src/CardGame.sol:CardGame --constructor-args <randcast_adapter_address> --rpc-url <chain_provider>

# Deployed to <CardGame_address>

cast send <randcast_adapter_address> "createSubscription()" --rpc-url <chain_provider> --private-key <local_test_account_private_key>

# Check the <sub_id>
cast logs --from-block 1 --to-block latest 'SubscriptionCreated(uint64 indexed subId, address indexed owner)' "" <local_test_account_address> --address <randcast_adapter_address> --rpc-url <chain_provider>

...
topics: [
  	0x464722b4166576d3dcbba877b999bc35cf911f4eaf434b7eba68fa113951d0bf
  	0x0000000000000000000000000000000000000000000000000000000000000001  --- <sub_id>
  	0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
  ]
...

cast send <randcast_adapter_address> "fundSubscription(uint64)" <sub_id> --value <some_ether> --rpc-url <chain_provider> --private-key <local_test_account_private_key>

cast send <randcast_adapter_address> "addConsumer(uint64,address)" <sub_id> <CardGame_address> --rpc-url <chain_provider> --private-key <local_test_account_private_key>
```

Install the npm dependencies

```bash
npm install
```

```bash
npm run dev
```

Navigate to [localhost:5000](http://localhost:5000). Enjoy the fast card game!
