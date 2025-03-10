// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {console} from "forge-std/Test.sol";

import "./RewardToken.sol";
import "./RewardNft.sol";

contract Crowdfunding {
    address public Owner;
    uint public constant FUNDING_GOAL = 50 ether;
    uint public constant NFT_THRESHOLD = 5 ether;
    uint256 public totalFundsRaised;
    bool public isFundingComplete;
    // address public constant NFT_CONTRACT_ADDRESS =
    //     0x2e234DAe75C793f67A35089C9d99245E1C58470b;
    // address public constant TOKEN_CONTRACT_ADDRESS =
    //     0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;

    RewardToken public rewardToken;
    RewardNft public rewardNFT;
    uint256 public tokenRewardRate;

    // Contribution tracking
    mapping(address => uint256) public contributions;
    mapping(address => bool) public hasReceivedNFT;

    // Events
    event ContributionReceived(address indexed contributor, uint256 amount);
    event TokenRewardSent(address indexed contributor, uint256 amount);
    event NFTRewardSent(address indexed contributor, uint256 tokenId);
    event FundsWithdrawn(address indexed projectOwner, uint256 amount);

    constructor(
        uint256 _tokenRewardRate,
        address _rewardToken,
        address _rewardNft
    ) {
        Owner = msg.sender;
        rewardToken = RewardToken(_rewardToken);
        rewardNFT = RewardNft(_rewardNft);
        tokenRewardRate = _tokenRewardRate;
    }

    function contribute() external payable {
        // console.log("Ether Value contribution___%s", msg.value);
        require(msg.value > 0, "Contribution must be greater than 0");
        require(!isFundingComplete, "Funding goal already reached");

        // Calculate contribution amount and process any refunds
        uint256 contributionAmount = _calculateContributionAndRefund(msg.value);
        // console.log("contributed Amount____%s", contributionAmount);
        // Update contribution record
        contributions[msg.sender] += contributionAmount;
        totalFundsRaised += contributionAmount;
        // console.log("total funds raised____%s", totalFundsRaised);

        // Check if funding goal is reached
        if (totalFundsRaised >= FUNDING_GOAL) {
            isFundingComplete = true;
            // console.log("isComplete____%s", isFundingComplete);
        }

        // Calculate token reward
        uint256 tokenReward = calculateReward(msg.value);

        console.log("token reward____%s", tokenReward);

        if (tokenReward > 0) {
            console.log("the contract caller____%s", msg.sender);
            sendRewardToken(tokenReward, msg.sender);
            console.log("token reward____%s", tokenReward);
            emit TokenRewardSent(msg.sender, tokenReward);
        }

        // Check for NFT eligibility
        if (
            contributions[msg.sender] >= NFT_THRESHOLD &&
            !hasReceivedNFT[msg.sender]
        ) {
            uint256 tokenId = rewardNFT.mintNFT(msg.sender);
            hasReceivedNFT[msg.sender] = true;
            emit NFTRewardSent(msg.sender, tokenId);
        }

        emit ContributionReceived(msg.sender, msg.value);
    }

    function calculateReward(uint256 _value) private returns (uint256) {
        uint256 tokenReward = (_value * tokenRewardRate) / 1 ether;

        return tokenReward;
    }

    function sendRewardToken(uint256 _amount, address _recipient) private {
        uint256 rewardAmount = calculateReward(_amount);
        rewardToken.transferFrom(address(this), _recipient, rewardAmount);
    }

    function _calculateContributionAndRefund(
        uint256 _contributionAmount
    ) private returns (uint256) {
        // Calculate the remaining amount needed to complete the funding goal
        uint256 remainingAmount = FUNDING_GOAL - totalFundsRaised;
        uint256 contributionAmount = _contributionAmount;

        // If contribution exceeds remaining goal, adjust contribution and refund excess
        if (_contributionAmount > remainingAmount) {
            contributionAmount = remainingAmount;
            uint256 refundAmount = _contributionAmount - remainingAmount;
            payable(msg.sender).transfer(refundAmount);
        }

        return contributionAmount;
    }

    function withdrawFunds() external {
        require(msg.sender == Owner, "Only project owner can withdraw");
        require(isFundingComplete, "Funding goal not yet reached");
        require(address(this).balance > 0, "No funds to withdraw");

        uint256 amount = address(this).balance;
        payable(Owner).transfer(amount);

        emit FundsWithdrawn(Owner, amount);
    }

    function getContribution(
        address contributor
    ) external view returns (uint256) {
        return contributions[contributor];
    }
}
