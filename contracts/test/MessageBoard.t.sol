// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {MessageBoard} from "../src/MessageBoard.sol";

contract MessageBoardTest is Test {
    MessageBoard public messageBoard;
    address public user1;
    address public user2;

    function setUp() public {
        messageBoard = new MessageBoard();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function testPostMessage() public {
        vm.prank(user1);
        messageBoard.postMessage("Hello Monad!");

        assertEq(messageBoard.getMessageCount(), 1);

        (address sender, string memory content, uint256 timestamp, uint256 likes) = messageBoard.messages(0);
        assertEq(sender, user1);
        assertEq(content, "Hello Monad!");
        assertEq(likes, 0);
    }

    function testGetMessages() public {
        vm.prank(user1);
        messageBoard.postMessage("Message 1");

        vm.prank(user2);
        messageBoard.postMessage("Message 2");

        MessageBoard.Message[] memory allMessages = messageBoard.getMessages();
        assertEq(allMessages.length, 2);
        assertEq(allMessages[0].sender, user1);
        assertEq(allMessages[0].content, "Message 1");
        assertEq(allMessages[1].sender, user2);
        assertEq(allMessages[1].content, "Message 2");
    }

    function testLikeMessage() public {
        vm.prank(user1);
        messageBoard.postMessage("Like me!");
        
        vm.prank(user2);
        messageBoard.likeMessage(0);
        
        (,,,uint256 likes) = messageBoard.messages(0);
        assertEq(likes, 1);

        // User can't like twice
        vm.prank(user2);
        vm.expectRevert("You already liked this message");
        messageBoard.likeMessage(0);
    }
} 