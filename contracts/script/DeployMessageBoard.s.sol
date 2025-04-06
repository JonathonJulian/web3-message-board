// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/MessageBoard.sol";

contract DeployMessageBoard is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MessageBoard messageBoard = new MessageBoard();

        // Log the address of the deployed contract
        console.log("MessageBoard deployed to:", address(messageBoard));

        vm.stopBroadcast();
    }
}