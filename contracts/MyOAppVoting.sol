// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";

contract MyOAppVoting is OApp {
    struct VoteTopic {
        string description;
        bool isActive;
        mapping(address => bool) hasVoted;
        uint256 yesVotes;
        uint256 noVotes;
    }

    mapping(uint256 => VoteTopic) public voteTopics;
    uint256 public topicsCount;

    mapping(uint32 => uint256) public lastStateChangeNonce;
    uint256 public nonce = 0;

    event VoteTopicCreated(uint256 topicId, string description);
    event Voted(uint256 topicId, address voter, bool vote);
    event VoteStopped(uint256 topicId);

    constructor(address _endpoint, address _delegate) OApp(_endpoint, _delegate) Ownable(_delegate) {}

    function createVoteTopic(string memory _description) public onlyOwner {
        VoteTopic storage newTopic = voteTopics[topicsCount];
        newTopic.description = _description;
        newTopic.isActive = true;

        emit VoteTopicCreated(topicsCount, _description);
        topicsCount++;

        syncStateAcrossChains(abi.encode(topicsCount - 1, _description, true, uint256(0), uint256(0)));
    }

    function vote(uint256 _topicId, bool _vote) public {
        require(_topicId < topicsCount, "Invalid topic ID");
        require(voteTopics[_topicId].isActive, "Voting is not active");
        require(!voteTopics[_topicId].hasVoted[msg.sender], "Already voted");

        voteTopics[_topicId].hasVoted[msg.sender] = true;
        if (_vote) {
            voteTopics[_topicId].yesVotes++;
        } else {
            voteTopics[_topicId].noVotes++;
        }

        emit Voted(_topicId, msg.sender, _vote);
        syncStateAcrossChains(abi.encode(_topicId, voteTopics[_topicId].yesVotes, voteTopics[_topicId].noVotes));
    }

    function stopVote(uint256 _topicId) public onlyOwner {
        require(_topicId < topicsCount, "Invalid topic ID");
        require(voteTopics[_topicId].isActive, "Voting is already stopped");

        voteTopics[_topicId].isActive = false;

        emit VoteStopped(_topicId);
        syncStateAcrossChains(abi.encode(_topicId, false));
    }

    function syncStateAcrossChains(bytes memory data) internal {
        nonce++;
        bytes memory payload = abi.encode(nonce, data);

        uint32[] memory dstChainIds = getDestinationChainIds();
        for (uint i = 0; i < dstChainIds.length; i++) {
            uint32 dstChainId = dstChainIds[i];
            if (dstChainId != _getChainId()) {
                _lzSend(dstChainId, payload, "", MessagingFee(0, 0), payable(address(this)));
            }
        }
    }

    function _getChainId() internal view returns (uint32) {
        return uint32(block.chainid);
    }

    function getDestinationChainIds() internal pure returns (uint32[] memory) {

        uint32[] memory destinationChainIds = new uint32[](3);
        destinationChainIds[0] = 11155111;
        destinationChainIds[1] = 11155420;
        destinationChainIds[2] = 421614;
    
    return destinationChainIds;
    }

    function _lzReceive(
    Origin calldata /*_origin*/,
    bytes32 /*_guid*/,
    bytes calldata payload,
    address /*_executor*/,
    bytes calldata /*_extraData*/
) internal override {
    (uint256 receivedNonce, bytes memory data) = abi.decode(payload, (uint256, bytes));
    if (receivedNonce <= lastStateChangeNonce[_getChainId()]) return;

    (uint256 topicId, string memory description, bool isActive, uint256 yesVotes, uint256 noVotes) = abi.decode(data, (uint256, string, bool, uint256, uint256));

    if (topicId >= topicsCount) {
        VoteTopic storage newTopic = voteTopics[topicsCount++];
        newTopic.description = description;
        newTopic.isActive = isActive;
    } else {
        VoteTopic storage topic = voteTopics[topicId];
        if (keccak256(bytes(description)) != keccak256(bytes(topic.description))) {
            topic.description = description; 
        }
        topic.isActive = isActive;
        topic.yesVotes = yesVotes;
        topic.noVotes = noVotes;
    }

    lastStateChangeNonce[_getChainId()] = receivedNonce;
}

    function getVoteCounts(uint256 _topicId) public view returns (uint256 yesVotes, uint256 noVotes) {
        require(_topicId < topicsCount, "Invalid topic ID");
        return (voteTopics[_topicId].yesVotes, voteTopics[_topicId].noVotes);
    }
}
