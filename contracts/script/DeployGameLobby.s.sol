// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {GameLobby} from "../src/GameLobby.sol";
import {IAdapter} from "Randcast-User-Contract/interfaces/IAdapter.sol";

contract DeployGameLobbyScript is Script {
    uint256 internal _deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
    address internal _randcastAdapterAddress = vm.envAddress("RANDCAST_ADAPTER_ADDRESS");

    function run() external {
        GameLobby gl;

        vm.startBroadcast(_deployerPrivateKey);
        gl = new GameLobby(_randcastAdapterAddress);

        IAdapter adapter;

        uint256 plentyOfEthBalance = vm.envUint("SUB_FUND_ETH_BAL");

        adapter = IAdapter(_randcastAdapterAddress);

        uint64 subId = adapter.createSubscription();

        adapter.fundSubscription{value: plentyOfEthBalance}(subId);

        adapter.addConsumer(subId, address(gl));
    }
}
