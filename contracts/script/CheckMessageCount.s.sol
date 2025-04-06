// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

interface IMessageBoard {
    function postMessage(string memory _content) external;
    function getMessages() external view returns (Message[] memory);
    function getMessageCount() external view returns (uint256);

    struct Message {
        address sender;
        string content;
        uint256 timestamp;
        uint256 likes;
    }
}

contract CheckMessageCount is Script {
    // Address of the deployed MessageBoard contract
    address constant MESSAGE_BOARD_ADDRESS = 0xF948bBe597963a6E8080c0390d0309bc8800dF03;

    function run() public view {
        IMessageBoard messageBoard = IMessageBoard(MESSAGE_BOARD_ADDRESS);
        uint256 count = messageBoard.getMessageCount();

        console.log("Current message count: %d", count);

        // Get and display a few sample messages
        if (count > 0) {
            IMessageBoard.Message[] memory messages = messageBoard.getMessages();

            console.log("\nSample messages:");
            // Display first message
            console.log("First message (#0):");
            console.log("  Sender: %s", messages[0].sender);
            console.log("  Content: %s", messages[0].content);
            console.log("  Timestamp: %d", messages[0].timestamp);
            console.log("  Likes: %d", messages[0].likes);

            // Display last message if there are more than 1
            if (count > 1) {
                console.log("\nLast message (#%d):", count - 1);
                console.log("  Sender: %s", messages[count - 1].sender);
                console.log("  Content: %s", messages[count - 1].content);
                console.log("  Timestamp: %d", messages[count - 1].timestamp);
                console.log("  Likes: %d", messages[count - 1].likes);
            }

            // Display a middle message if there are more than 2
            if (count > 2) {
                uint256 midIndex = count / 2;
                console.log("\nMiddle message (#%d):", midIndex);
                console.log("  Sender: %s", messages[midIndex].sender);
                console.log("  Content: %s", messages[midIndex].content);
                console.log("  Timestamp: %d", messages[midIndex].timestamp);
                console.log("  Likes: %d", messages[midIndex].likes);
            }
        }
    }
}