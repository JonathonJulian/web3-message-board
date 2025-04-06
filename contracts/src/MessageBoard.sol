// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MessageBoard {
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
        uint256 likes;
    }
    
    Message[] public messages;
    mapping(uint256 => mapping(address => bool)) public messageLikes;
    
    event MessagePosted(address indexed sender, uint256 indexed messageId, string content, uint256 timestamp);
    event MessageLiked(address indexed liker, uint256 indexed messageId, uint256 newLikeCount);
    
    function postMessage(string memory _content) public {
        uint256 messageId = messages.length;
        messages.push(Message(msg.sender, _content, block.timestamp, 0));
        emit MessagePosted(msg.sender, messageId, _content, block.timestamp);
    }
    
    function getMessages() public view returns (Message[] memory) {
        return messages;
    }
    
    function likeMessage(uint256 _messageId) public {
        require(_messageId < messages.length, "Message does not exist");
        require(!messageLikes[_messageId][msg.sender], "You already liked this message");
        
        messageLikes[_messageId][msg.sender] = true;
        messages[_messageId].likes += 1;
        
        emit MessageLiked(msg.sender, _messageId, messages[_messageId].likes);
    }
    
    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }
} 