// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {PredictionPool} from "../src/PredictionPool.sol";

contract DeployPredictionPool is Script {
    function run() external returns (PredictionPool pool) {
        vm.startBroadcast();

        pool = new PredictionPool(
            0x3600000000000000000000000000000000000000,
            msg.sender
        );

        vm.stopBroadcast();
    }
}
