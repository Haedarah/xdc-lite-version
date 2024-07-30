// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";

import "../src/rewardpoint/RewardPointFactory.sol";
import "../src/rewardpoint/RewardPointBeacon.sol";

contract RewardPointFactoryTest is Test{
    RewardPoint public implementation;
    RewardPointFactory public rewardPointFactoryContract;
    RewardPointBeacon public rewardPointBeaconContract;

    uint256 public MONET_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address public MONET= 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    uint256 public company1_PK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    address public company1=0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    uint256 public company2_PK=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    address public company2=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function setUp() public {
        vm.startPrank(MONET);
        implementation = new RewardPoint();
        //initializing the implementation contract with dummy values
        implementation.initialize(MONET, MONET, 0, "init", "init");
        rewardPointBeaconContract = new  RewardPointBeacon(address(implementation),MONET);
        rewardPointFactoryContract = new RewardPointFactory(address(rewardPointBeaconContract),MONET);
        vm.stopPrank();
    }

    function test_signer_and_owner() view external{
        assertEq(rewardPointFactoryContract.getSigner(), MONET);
        assertEq(rewardPointFactoryContract.owner(), MONET);
    }

    function test_create_reverts_with__OwnableUnauthorizedAccount() external    {
        vm.startPrank(company1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, company1));
        rewardPointFactoryContract.create(company1,2,"Test","TSTP");
        vm.stopPrank();
    }

    function test_create_succeeds() external{
        vm.startPrank(MONET);
        //adding point contract for company1
        rewardPointFactoryContract.create(company1,2,"Test","TSTP");
        assertEq(rewardPointFactoryContract.getRewardPointsOf(company1).length,1);
        assertEq(rewardPointFactoryContract.getRewardPoints().length,1);
        assertEq(RewardPoint(rewardPointFactoryContract.getRewardPointsOf(company1)[0]).decimals(),2);

        //adding aonther point contract for company1
        rewardPointFactoryContract.create(company1,4,"Test2","TSTP2");
        assertEq(rewardPointFactoryContract.getRewardPointsOf(company1).length,2);
        assertEq(rewardPointFactoryContract.getRewardPoints().length,2);
        assertEq(RewardPoint(rewardPointFactoryContract.getRewardPointsOf(company1)[1]).decimals(),4);

        //adding point contract for company2
        rewardPointFactoryContract.create(company2,2,"Check","CHKP");
        assertEq(rewardPointFactoryContract.getRewardPointsOf(company1).length,2);
        assertEq(rewardPointFactoryContract.getRewardPointsOf(company2).length,1);
        assertEq(rewardPointFactoryContract.getRewardPoints().length,3);
        assertEq(RewardPoint(rewardPointFactoryContract.getRewardPointsOf(company2)[0]).decimals(),2);
        vm.stopPrank();
    }

    function test_setSigner_reverts_with__OwnableUnauthorizedAccount() external    {
        vm.startPrank(company1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, company1));
        rewardPointFactoryContract.setSigner(company1);
        assertEq(rewardPointFactoryContract.getSigner(), MONET);
        vm.stopPrank();
    }

    function test_setSigner_succeeds() external    {
        vm.startPrank(MONET);
        rewardPointFactoryContract.setSigner(company1);
        assertEq(rewardPointFactoryContract.getSigner(), company1);
        rewardPointFactoryContract.setSigner(MONET);
        assertEq(rewardPointFactoryContract.getSigner(), MONET);
        vm.stopPrank();
    }
}
