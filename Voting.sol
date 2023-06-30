// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting {
    address public admin;
    IERC20 public token;

    struct Topic {
        string title;
        string description;
        bool isOpen;
        uint256 positiveVotes;
        uint256 negativeVotes;
    }
    mapping(uint256 => mapping(address => bool)) topicVoted;

    Topic[] public topics;

    event TopicCreated(uint256 indexed topicId, string title, string description);
    event TopicOpened(uint256 indexed topicId);
    event TopicClosed(uint256 indexed topicId);
    event Vote(uint256 indexed topicId, address indexed voter, bool vote);

    constructor(IERC20 _token) {
        admin = msg.sender;
        token = _token;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    function createTopic(string memory _title, string memory _description) public onlyAdmin {
        Topic memory newTopic = Topic(_title,_description,false,0,0);
        topicVoted[topics.length][msg.sender]=false;
        topics.push(newTopic);

        emit TopicCreated(topics.length - 1, _title, _description);
    }

    function openTopic(uint256 _topicId) public onlyAdmin {
        Topic storage topic = topics[_topicId];
        require(!topic.isOpen, "Topic is already open");
        topic.isOpen = true;

        emit TopicOpened(_topicId);
    }

    function closeTopic(uint256 _topicId) public onlyAdmin {
        Topic storage topic = topics[_topicId];
        require(topic.isOpen, "Topic is already closed");
        topic.isOpen = false;

        emit TopicClosed(_topicId);
    }

    function vote(uint256 _topicId, bool _vote) public {
        Topic storage topic = topics[_topicId];
        require(topic.isOpen, "Topic is closed");
        require(!topicVoted[_topicId][msg.sender], "Already voted");

        topicVoted[_topicId][msg.sender] = true;

        if (_vote) {
            topic.positiveVotes += 1;
        } else {
            topic.negativeVotes += 1;
        }

        emit Vote(_topicId, msg.sender, _vote);
    }

    function settleVotes(uint256 _topicId, uint256 _rewardAmount) public onlyAdmin {
        Topic storage topic = topics[_topicId];
        require(!topic.isOpen, "Topic is still open");

        uint256 totalParticipants = topic.positiveVotes + topic.negativeVotes;

        if (totalParticipants == 0) {
            return;
        }

        uint256 rewardPerParticipant = _rewardAmount / totalParticipants;

        for (uint256 i = 0; i < totalParticipants; i++) {
            if (topicVoted[_topicId][msg.sender]) {
                token.transfer(msg.sender, rewardPerParticipant);
            }
        }
    }
}