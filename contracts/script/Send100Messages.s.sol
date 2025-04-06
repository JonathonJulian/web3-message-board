// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

interface IMessageBoard {
    function postMessage(string memory _content) external;
    function getMessageCount() external view returns (uint256);
}

contract Send100Messages is Script {
    // Address of the deployed MessageBoard contract
    address constant MESSAGE_BOARD_ADDRESS = 0xF948bBe597963a6E8080c0390d0309bc8800dF03;

    function run() public {
        // Start broadcasting transactions
        vm.startBroadcast();

        IMessageBoard messageBoard = IMessageBoard(MESSAGE_BOARD_ADDRESS);
        uint256 initialCount = messageBoard.getMessageCount();

        console.log("Initial message count: %d", initialCount);
        console.log("Sending 100 messages...");

        for (uint i = 1; i <= 100; i++) {
            string memory content = string(abi.encodePacked("Test message #", vm.toString(i), " from script"));
            messageBoard.postMessage(content);

            // Log every 10 messages to save output space
            if (i % 10 == 0) {
                console.log("Sent %d messages", i);
            }
        }

        vm.stopBroadcast();

        console.log("Script completed. Check the contract for all 100 messages!");
        console.log("Expected new message count: %d", initialCount + 100);
    }
}