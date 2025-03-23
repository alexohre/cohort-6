// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {CrowdfundingV2} from "../contracts/chainlink-integration/CrowdFundingV2.sol";
import {RewardToken} from "../contracts/with-foundry/RewardToken.sol";
import {RewardNft} from "../contracts/with-foundry/RewardNft.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
// import {AggregatorV3Interface} from "../lib/chainlink-local/lib/chainlink-brownie-contracts/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";

contract CrowdfundingTest is Test {
    // Crowdfunding contract state variables
    CrowdfundingV2 public crowdfundingV2;
    RewardToken public rewardtoken;
    RewardNft public rewardnft;
    uint256 public constant FUNDING_GOAL_IN_USD = 50000;
    uint256 public constant NFT_THRESHOLD_IN_USD = 5000;
    uint256 public totalFundsRaised;
    bool public isFundingComplete;
    uint256 constant REWARD_RATE = 100;
    uint256 sepoliaFork;

    // Addresses for testing
    address crowdfundingV2Addr = address(this);
    address owner = vm.addr(1);
    address addr2 = vm.addr(2);
    address addr3 = vm.addr(3);
    address addr4 = vm.addr(4);
    address addr5 = vm.addr(5);
    AggregatorV3Interface priceFeed;

    event ContributionReceived(address indexed contributor, uint256 amount);
    event NFTRewardSent(address indexed receiver, uint256 Id);
    event TokenRewardSent(address indexed receiver, uint256 Amount);
    event FundsWithdrawn(address indexed receiver, uint256 Amount);

    address public constant ETH_USD_ADDR = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    function setUp() public {
        // Create the Sepolia fork
        sepoliaFork = vm.createFork("https://eth-sepolia.g.alchemy.com/v2/KX1L8OUxzzPpA2BK0oa2rRSbunp8M2aN");
        vm.selectFork(sepoliaFork);

        // Set the fork to a specific block before any other operations
        vm.rollFork(7887153);

        // deploy contracts with the owner address
        vm.startPrank(owner);

        rewardtoken = new RewardToken();
        rewardnft = new RewardNft("RewardNft", "RNFT", "ipfs://");

        // Transfer Reward tokens from owner to the contract
        crowdfundingV2 = new CrowdfundingV2(REWARD_RATE, address(rewardtoken), address(rewardnft));

        rewardtoken.transfer(address(crowdfundingV2), 5000);
        vm.stopPrank();

        vm.deal(addr2, 100 ether);
        vm.deal(addr3, 100 ether);
        vm.deal(addr4, 100 ether);
        vm.deal(addr5, 100 ether);
    }

    // ******DEPLOYMENT******//
    // Test state variables at deployment
    // Should set the correct CrowdFunding contract owner
    function test_setContractOwner() public view {
        assertEq(crowdfundingV2.Owner(), owner);
    }

    // Should set the correct crowd Token contract owner
    function test_setTokenContractOwner() public view {
        assertEq(rewardtoken.owner(), owner);
    }

    // should transfer the correct amount of reward tokens to the crowdfunding contract
    function test_RewardTokenBalanceOfCrowdfundingOnDeployment() public view {
        uint256 contractBal1 = rewardtoken.balanceOf(crowdfundingV2Addr);
        assertEq(contractBal1, 5000);

        uint256 ownerRewardTokenBalance = rewardtoken.balanceOf(owner);
        assertEq(ownerRewardTokenBalance, 0);
    }

    // Should set the correct rewardNFT contract owner
    function test_setNFTContractOwner() public view {
        assertEq(rewardnft.owner(), owner);
    }

    // Should set the correct funding goal
    function test_setCorrectFundingGoal() public view {
        assertEq(crowdfundingV2.FUNDING_GOAL_IN_USD(), FUNDING_GOAL_IN_USD);
    }

    // Should set the correct token reward rate
    function test_setTokenReward() public view {
        assertEq(crowdfundingV2.tokenRewardRate(), REWARD_RATE);
    }

    // Should set the correct NFT threshold
    function test_set_NFT_THRESHOLD_IN_USD() public view {
        assertEq(crowdfundingV2.NFT_THRESHOLD_IN_USD(), NFT_THRESHOLD_IN_USD);
    }

    // Should determine that totalFundsRaised is zero initially
    function test_total_funds_raised() public view {
        assertEq(crowdfundingV2.totalFundsRaised(), 0);
    }

    // Should set isFundingComplete to false initially
    function test_is_funding_complete() public view {
        assertEq(crowdfundingV2.isFundingComplete(), false);
    }

    function test_getLatestPrice() public view {
        int256 ethUSDPrice = crowdfundingV2.getLatestPrice();
        console.log("eth price = ", ethUSDPrice);
    }

    // ********* TRANSACTIONS *********//
    // Allows Eth contribution from user
    function test_allow_eth_contributionv2() public {
        uint256 contributionAmount = 10 ether;
        uint256 addr2InitialEthBal = addr2.balance; // address 2 initial balance
        uint256 initialEthBalanceCrowdFunding = address(crowdfundingV2).balance; // initial balance of crowdfunding contract

        uint256 contractRewardTokenBal = rewardtoken.balanceOf(address(crowdfundingV2));
        assertEq(contractRewardTokenBal, 5000);

        uint256 ownerRewardTokenBalance = rewardtoken.balanceOf(owner);
        assertEq(ownerRewardTokenBalance, 0);

        assertEq(initialEthBalanceCrowdFunding, 0);
        assertEq(addr2InitialEthBal, 100 ether);

        // Get USD value before contribution
        uint256 contributionInUsd = crowdfundingV2.getConversionRate(contributionAmount);
        console.log("Contribution in USD: ", contributionInUsd);

        // Perform the contribution
        vm.prank(addr2);
        crowdfundingV2.contribute{value: contributionAmount}();

        uint256 addr2EthBalAfterContr = addr2.balance; // address 2 balance after contribution
        uint256 crowdfundingBalAfterContr = address(crowdfundingV2).balance; // crowdfunding balance after contribution

        // Check ETH balances
        assertEq(addr2EthBalAfterContr, addr2InitialEthBal - contributionAmount);
        assertEq(crowdfundingBalAfterContr, initialEthBalanceCrowdFunding + contributionAmount);

        // Check USD total
        uint256 totalRaised = crowdfundingV2.totalFundsRaised();
        uint256 totalRaisedInUsd = crowdfundingV2.getConversionRate(totalRaised);
        console.log("Total raised in USD: ", totalRaisedInUsd);

        // Check contribution mapping
        uint256 addr2Contribution = crowdfundingV2.contributions(addr2);
        assertEq(addr2Contribution, contributionAmount);
    }

    // Allows Eth contribution from multiple users
    function test_allow_multiple_eth_contributionv2() public {
        uint256 addr2InitialEthBal = addr2.balance; // address 2 initial balance
        uint256 addr3InitialEthBal = addr3.balance; // address 3 initial balance
        uint256 initialEthBalanceCrowdFunding = address(crowdfundingV2).balance; // initial balance of crowdfunding contract

        uint256 contractRewardTokenBal = rewardtoken.balanceOf(address(crowdfundingV2));
        assertEq(contractRewardTokenBal, 5000);

        uint256 ownerRewardTokenBalance = rewardtoken.balanceOf(owner);
        assertEq(ownerRewardTokenBalance, 0);

        assertEq(initialEthBalanceCrowdFunding, 0);
        assertEq(addr2InitialEthBal, 100 ether);
        assertEq(addr3InitialEthBal, 100 ether);

        // Perform first contribution
        vm.prank(addr2);
        crowdfundingV2.contribute{value: 10 ether}();
        assertEq(crowdfundingV2.getContribution(addr2), 10 ether);

        // Perform second contribution
        vm.prank(addr3);
        crowdfundingV2.contribute{value: 8 ether}();
        assertEq(crowdfundingV2.getContribution(addr3), 8 ether);
    }

    // should refund excess contribution to the contributor
    function test_refund_excess_contributionv2() public {
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

        // Ascertain that addr3's balance is unchanged
        uint256 addr3BalanceBefore = addr3.balance;
        assertEq(addr3BalanceBefore, 100 ether);

        // Make contribution that should trigger refund
        vm.prank(addr3);
        crowdfunding.contribute{value: secondContribution}();

        // Verify final states
        assertEq(crowdfunding.totalFundsRaised(), FUNDING_GOAL);
        assertEq(crowdfunding.isFundingComplete(), true);
        assertEq(crowdfunding.getContribution(addr3), remainingToGoal);
        uint256 crowdfundinBal2 = address(crowdfunding).balance;

        assertEq(crowdfundinBal2, FUNDING_GOAL);

        // Verify addr3 received the correct refund
        // Final balance should be: initial balance - contribution + refund
        uint256 expectedBalance = addr3BalanceBefore - secondContribution + expectedRefund;
        assertEq(addr3.balance, expectedBalance);
    }
}
