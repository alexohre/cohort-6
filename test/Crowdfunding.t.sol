// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
// import {Crowdfunding} from "../src/Crowdfunding.sol";
import {Crowdfunding} from "../contracts/with-foundry/Crowdfunding.sol";
import {RewardToken} from "../contracts/with-foundry/RewardToken.sol";
import {RewardNft} from "../contracts/with-foundry/RewardNft.sol";

contract CrowdfundingTest is Test {
    Crowdfunding public crowdfunding;
    RewardToken public rewardtoken;
    RewardNft public rewardnft;
    address public nftAddr = 0x2e234DAe75C793f67A35089C9d99245E1C58470b;
    address public tokenAddr = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;
    // address public owner;
    uint public constant FUNDING_GOAL = 50 ether;
    uint public constant NFT_THRESHOLD = 5 ether;
    uint256 public totalFundsRaised;
    bool public isFundingComplete;
    uint256 constant REWARD_RATE = 100;

    address crowdfundingAddr = address(this);
    address owner = vm.addr(1);
    address addr2 = vm.addr(2);
    address addr3 = vm.addr(3);
    address addr5 = vm.addr(5);
    address addr4 = vm.addr(4);
    // address crowdfundingAddr;

    receive() external payable {}

    event ContributionReceived(address indexed contributor, uint256 amount);
    event NFTRewardSent(address indexed receiver, uint256 Id);
    event TokenRewardSent(address indexed receiver, uint256 Amount);
    event FundsWithdrawn(address indexed receiver, uint256 Amount);

    function calculateTokenReward(uint256 ethContribution) public view returns (uint256) {
        return (ethContribution * crowdfunding.tokenRewardRate()) / 1 ether;
    }

    function setUp() public {
        vm.startPrank(owner);

        rewardtoken = new RewardToken();
        vm.stopPrank();
        vm.startPrank(owner);
        rewardnft = new RewardNft("RewardNft", "RNFT", "ipfs://");
        vm.stopPrank();
        // vm.startPrank(owner);
        console.log("rewardtoken:", address(rewardtoken));
        console.log("rewardnft:", address(rewardnft));
        vm.startPrank(owner);
        // Transfer Reward tokens from owner to the contract
        rewardtoken.transfer(address(this), 5000);

        crowdfunding = new Crowdfunding(REWARD_RATE, address(rewardtoken), address(rewardnft));
        vm.stopPrank();

        vm.deal(addr2, 100 ether);
        vm.deal(addr3, 100 ether);
        vm.deal(addr4, 100 ether);
        // address crowdfundingAddr = address(this);

        // Set crowdfunding contract in the token contracts
        // vm.startPrank(owner);
        // // rewardtoken.setCrowdfundingContract(crowdfundingAddr);
        // // rewardnft.setCrowdfundingContract(crowdfundingAddr);
        // vm.stopPrank();
        // vm.Prank(owner);
        console.log("Owner_____:", owner);
        console.log("Address 2____:", addr2);
        console.log("Address 3:", addr3);
        console.log("Contract Address:", crowdfundingAddr);
        // Log the addresses
        console.log("Crowdfunding contract address:", address(crowdfunding));
        console.log("RewardToken contract address:", address(rewardtoken));
        console.log("RewardNFT contract address:", address(rewardnft));
        // vm.stopPrank();
    }

    // ******DEPLOYMENT******//
    // state variables at deployment
    // Should set the correct CrowdFunding contract owner
    function test_setContractOwner() public view {
        assertEq(crowdfunding.Owner(), owner);
    }
    // Should set the correct crowd Token contract owner
    function test_setTokenContractOwner() public view {
        assertEq(rewardtoken.owner(), owner);
    }

    function test_RewardTokenBalanceOfCrowdfundingOnDeployment() public view {
        uint256 contractBal1 = rewardtoken.balanceOf(crowdfundingAddr);
        assertEq(contractBal1, 5000);

        uint256 ownerRewardTokenBalance = rewardtoken.balanceOf(owner);
        assertEq(ownerRewardTokenBalance, 0);
    }
    // Should set the correct rewardNFT contract owner
    // function test_setNFTContractOwner() public view {
    //     assertEq(rewardnft.owner(), owner);
    // }

    // Should set the correct Nft contract Address
    // function test_setNFTContractAddr() public view {
    //     assertEq(crowdfunding.NFT_CONTRACT_ADDRESS(), nftAddr);
    // }

    // // Should set the correct Token contract Address
    // function test_setTokenContractAddr() public view {
    //     assertEq(crowdfunding.TOKEN_CONTRACT_ADDRESS(), tokenAddr);
    // }
    // Should set the correct funding goal
    function test_setCorrectFundingGoal() public view {
        assertEq(crowdfunding.FUNDING_GOAL(), FUNDING_GOAL);
    }
    // Should set the correct token reward rate
    function test_setTokenReward() public view {
        assertEq(crowdfunding.tokenRewardRate(), REWARD_RATE);
    }
    // Should set the correct NFT threshold
    function test_set_NFT_Threshold() public view {
        assertEq(crowdfunding.NFT_THRESHOLD(), NFT_THRESHOLD);
    }
    // Should determine that totalFundsRaised is zero initially
    function test_total_funds_raised() public view {
        assertEq(crowdfunding.totalFundsRaised(), 0);
    }
    // Should set isFundingComplete to false initially
    function test_is_funding_complete() public view {
        assertEq(crowdfunding.isFundingComplete(), false);
    }

    // Transactions
    // Allows Eth contrib.
    function test_Allows_eth_contribution() public {
        uint256 contributionAmount = 10 ether;
        uint256 initialEthBalanceAddr2 = addr2.balance;
        uint256 initialBalanceCrowdFunding = address(crowdfunding).balance;

        uint256 contractBal1 = rewardtoken.balanceOf(crowdfundingAddr);
        assertEq(contractBal1, 5000);

        uint256 ownerRewardTokenBalance = rewardtoken.balanceOf(owner);
        assertEq(ownerRewardTokenBalance, 0);

        assertEq(initialBalanceCrowdFunding, 0);
        assertEq(initialEthBalanceAddr2, 100 ether);
        // Perform the contribution
        vm.startPrank(addr2);
        console.log("Addr2_____", addr2);
        // vm.prank(addr2);
        crowdfunding.contribute{value: contributionAmount}();
        // assertEq(initialBalanceCrowdFunding, 10);
        vm.stopPrank();
        uint256 finalBalanceaddr2 = addr2.balance;
        uint256 finalBalanceCrowdFunding = address(crowdfunding).balance;

        assertEq(finalBalanceaddr2, initialEthBalanceAddr2 - contributionAmount);
        assertEq(finalBalanceCrowdFunding, initialBalanceCrowdFunding + contributionAmount);
    }

    // determine that the token reward amount is based on contrib
    function test_token_reward_amount() public {
        uint256 rewardAmount = calculateTokenReward(2 ether);

        vm.prank(addr2);
        crowdfunding.contribute{value: 2 ether}();

        uint256 addr2RewardTokenBalance = rewardtoken.balanceOf(addr2);

        assertEq(addr2RewardTokenBalance, rewardAmount);
    }

    // mint tokens based on contrib amount
    function test_mint_tokens_based_on_contribution() public {
        uint256 expectedTokens = calculateTokenReward(2 ether);

        vm.prank(addr2);
        crowdfunding.contribute{value: 2 ether}();
        assertEq(rewardtoken.balanceOf(addr2), expectedTokens);
    }

    // should not mint NFT below threshold
    function test_not_mint_nft_below_threshold() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 3 ether}();
        assertEq(rewardnft.balanceOf(addr2), 0);

        assertEq(crowdfunding.hasReceivedNFT(addr2), false);
    }

    // should mint NFT
    function test_should_mint_nft() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 10 ether}();
        assertEq(rewardnft.balanceOf(addr2), 1);
        assertEq(crowdfunding.hasReceivedNFT(addr2), true);
    }

    // should mint NFT for cummulative contributions
    function test_mint_for_cummulative() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 2 ether}();
        assertEq(rewardnft.balanceOf(addr2), 0);

        vm.prank(addr2);
        crowdfunding.contribute{value: 4 ether}();
        assertEq(rewardnft.balanceOf(addr2), 1);
    }

    // should not mint additional NFT
    function test_should_not_mint_additional_nft() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 8 ether}();
        assertEq(rewardnft.balanceOf(addr2), 1);

        vm.prank(addr2);
        crowdfunding.contribute{value: 10 ether}();
        assertEq(rewardnft.balanceOf(addr2), 1);
    }

    // should track individual contributions
    function test_track_individual_contributions() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 10 ether}();
        assertEq(crowdfunding.getContribution(addr2), 10 ether);

        vm.prank(addr3);
        crowdfunding.contribute{value: 20 ether}();
        assertEq(crowdfunding.getContribution(addr3), 20 ether);
    }

    // should track multiple contributions
    function test_track_multiple_contributions() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 10 ether}();
        assertEq(crowdfunding.getContribution(addr2), 10 ether);

        vm.prank(addr2);
        crowdfunding.contribute{value: 20 ether}();
        assertEq(crowdfunding.getContribution(addr2), 30 ether);
    }

    // should track funding progress
    function test_track_funding_progress() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 40 ether}();
        assertEq(crowdfunding.totalFundsRaised(), 40 ether);
        assertEq(crowdfunding.isFundingComplete(), false);

        vm.prank(addr2);
        crowdfunding.contribute{value: 10 ether}();
        assertEq(crowdfunding.totalFundsRaised(), 50 ether);
        assertEq(crowdfunding.isFundingComplete(), true);
    }

    // should allow owner to withdraw funds
    function test_allow_owner_to_withdraw() public {
        uint256 initialOwnerBalance = owner.balance;
        console.log("Initial Owner Balance:", initialOwnerBalance);
        assertEq(owner.balance, 0);

        vm.startPrank(addr2);
        crowdfunding.contribute{value: FUNDING_GOAL}();
        vm.stopPrank();
        assertEq(addr2.balance, 50 ether);

        assertEq(crowdfunding.totalFundsRaised(), FUNDING_GOAL);
        assertEq(crowdfunding.contributions(addr2), 50 ether);
        // vm.prank(address(crowdfunding));
        // vm.startPrank(owner);
        // console.log("Owner Address:", owner);

        // crowdfunding.withdrawFunds();
        // vm.stopPrank();
        // assertEq(owner.balance, initialOwnerBalance + FUNDING_GOAL);
    }

    // should not allow withdrawal if funding goal not reached
    function test_reject_withdrawal_if_funding_not_reached() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 20 ether}();
        assertEq(addr2.balance, 80 ether);

        vm.expectRevert("Funding goal not yet reached");

        vm.prank(address(this));
        crowdfunding.withdrawFunds();
    }

    // should not allow non-owner to withdraw funds
    function test_withdrawal_for_nonOwner() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 50 ether}();
        vm.expectRevert("Only project owner can withdraw");
        vm.prank(addr2);
        crowdfunding.withdrawFunds();
    }

    function test_correctly_track_individual_contributions() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 12 ether}();

        vm.prank(addr3);
        crowdfunding.contribute{value: 12 ether}();

        // vm.prank(addr5);
        // crowdfunding.contribute{value: 12 ether}();

        assertEq(crowdfunding.getContribution(addr2), 12 ether);
        assertEq(crowdfunding.getContribution(addr3), 12 ether);
        // assertEq(crowdfunding.getContribution(addr5), 12 ether);
    }

    function test_contribution_amount_for_repeat_contributions() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 12 ether}();

        vm.prank(addr2);
        crowdfunding.contribute{value: 12 ether}();

        assertEq(crowdfunding.getContribution(addr2), 24 ether);
    }

    // validations
    function test_should_reject_zero_contribution() public {
        vm.expectRevert("Contribution must be greater than 0");
        vm.prank(addr2);
        crowdfunding.contribute{value: 0 ether}();
    }

    function test_reject_contributions_after_funding_goal_is_reached() public {
        vm.prank(addr2);
        crowdfunding.contribute{value: 50 ether}();

        vm.expectRevert("Funding goal already reached");
        vm.prank(addr3);
        crowdfunding.contribute{value: 0.00001 ether}();
        crowdfunding.withdrawFunds();
    }

    function test_refund_excess_contribution() public {
        // First contribute most of the funding goal
        uint256 initialContribution = 45 ether;
        vm.prank(addr2);
        crowdfunding.contribute{value: initialContribution}();

        // Verify initial contribution state
        assertEq(crowdfunding.totalFundsRaised(), initialContribution);

        // Calculate remaining amount needed and prepare second contribution
        uint256 secondContribution = 10 ether;
        uint256 remainingToGoal = FUNDING_GOAL - initialContribution; // Should be 5 ether
        uint256 expectedRefund = secondContribution - remainingToGoal; // Should be 5 ether

        // Record addr3's balance before contribution
        uint256 addr3BalanceBefore = addr3.balance;

        // Make contribution that should trigger partial refund
        vm.prank(addr3);
        crowdfunding.contribute{value: secondContribution}();

        // Verify final states
        assertEq(crowdfunding.totalFundsRaised(), FUNDING_GOAL);
        assertEq(crowdfunding.isFundingComplete(), true);
        assertEq(crowdfunding.getContribution(addr3), remainingToGoal);

        // Verify addr3 received the correct refund
        // Final balance should be: initial balance - contribution + refund
        uint256 expectedBalance = addr3BalanceBefore - secondContribution + expectedRefund;
        assertEq(addr3.balance, expectedBalance);
    }

    // Events
    // Should emit FundsWithdrawn event
    function test_emit_funds_withdrawn_event() public {
        // First reach the funding goal
        vm.prank(addr2);
        crowdfunding.contribute{value: FUNDING_GOAL}();

        // Set up the event check
        vm.expectEmit(true, true, false, true, address(crowdfunding));

        // Emit the expected event with expected arguments
        emit FundsWithdrawn(address(this), FUNDING_GOAL);

        // Withdraw the funds - using address(this) as owner
        crowdfunding.withdrawFunds();
    }
    // Should emit TokenRewardSent event
    function test_emit_token_reward_sent_event() public {
        // Calculate expected tokens based on reward rate
        uint256 expectedTokens = (2 ether * REWARD_RATE) / 1 ether;

        // Set up the event check
        vm.expectEmit(true, true, false, true, address(crowdfunding));

        // Emit the expected event with expected arguments
        emit TokenRewardSent(addr2, expectedTokens);

        // Make the contribution that should trigger the token reward
        vm.prank(addr2);
        crowdfunding.contribute{value: 2 ether}();
    }
    // Should emit ContributionReceived event
    function test_emit_contribution_received_event() public {
        vm.expectEmit(true, true, false, true, address(crowdfunding));

        // Emit the expected event with the expected arguments
        emit ContributionReceived(addr2, 20 ether);

        // Perform the action that should emit the event
        vm.prank(addr2);
        crowdfunding.contribute{value: 20 ether}();
    }

    // Should emit NFTRewardSent event
    function test_emit_nft_reward_sent_event() public {
        // Set up the event check - we want to verify the NFTRewardSent event
        vm.expectEmit(true, true, true, true, address(crowdfunding));

        // Emit the expected event with expected arguments
        emit NFTRewardSent(addr2, 0); // First NFT should have ID 0

        // Make the contribution that should trigger the NFT reward
        vm.prank(addr2);
        crowdfunding.contribute{value: NFT_THRESHOLD}();
    }
}
