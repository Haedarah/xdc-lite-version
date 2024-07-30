// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";

import "../src/rewardpoint/RewardPoint.sol";
import "../src/rewardpoint/RewardPointFactory.sol";
import "../src/rewardpoint/SignatureVerifier.sol";
import "../src/interfaces/ISignerInfo.sol";

contract RewardPointTest is Test{
    RewardPoint public rewardPointContract;
    RewardPointFactory public rewardPointFactoryContract;
    ISignerInfo public signerInfo;

    //published development private keys. Not mine.
    uint256 public MONET_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address public MONET= 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; //vm.addr(MONET_PK);

    uint256 public company1_PK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    address public company1=0x70997970C51812dc3A010C7d01b50e0d17dc79C8; //makeAddr("company1");

    uint256 public company2_PK=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    address public company2=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; //makeAddr("company2");

    uint256 public user1_PK=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;
    address public user1=0x90F79bf6EB2c4f870365E785982E1f101E93b906; //makeAddr("user1");

    uint256 public user2_PK=0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a;
    address public user2=0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65; //makeAddr("user2");

    uint256 public user3_PK=0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba;
    address public user3=0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc; //makeAddr("user3");

    address public dummyBeacon=makeAddr("dummyBeacon");

    function setUp() public {
        rewardPointContract = new RewardPoint();
        rewardPointFactoryContract = new RewardPointFactory(dummyBeacon,MONET);
    }

    function test_initialize_reverts_with__0x0_owner() external {
        vm.startPrank(MONET);
        vm.expectRevert(bytes("0x0_owner"));
        rewardPointContract.initialize(address(0), address(rewardPointFactoryContract), 2, "Test", "TSTP");
        vm.stopPrank();
    }

    function test_initialize_reverts_with__0x0_signerAccount() external {
        vm.startPrank(MONET);
        vm.expectRevert(bytes("0x0_signerAccount"));
        rewardPointContract.initialize(company1, address(0), 2, "Test", "TSTP");
        vm.stopPrank();
    }

    function test_initialize_succeeds() external {
        rewardPointContract.initialize(company1, address(rewardPointFactoryContract), 2, "Test", "TSTP");

        assertEq(rewardPointContract.owner(),company1);
        assertEq(rewardPointContract.signerInfo().getSigner(),MONET);
        assertEq(rewardPointContract.decimals(),2);
        assertEq(rewardPointContract.name(),"Test");
        assertEq(rewardPointContract.symbol(),"TSTP");
    }

    function test_mint_reverts_with__UsedSignature() external{
        rewardPointContract.initialize(company1, address(rewardPointFactoryContract), 2, "Test", "TSTP");

        //preparing the signature - just like it happens in the server:
        bytes32 hashedMessage_server = keccak256(abi.encodePacked(user1, uint256(10000), uint256(0), address(rewardPointContract)));
        hashedMessage_server = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hashedMessage_server));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(MONET_PK, hashedMessage_server);
        bytes memory signature_server = abi.encodePacked(r,s,v);

        uint256 alreadyConverted=rewardPointContract.convertedPoints(user1);

        vm.startPrank(user1);
        rewardPointContract.mint(10000,signature_server);
        vm.expectRevert(abi.encodeWithSelector(SignatureVerifier.UsedSignature.selector, user1, signature_server));
        rewardPointContract.mint(10000,signature_server);
        vm.stopPrank();

        assertEq(rewardPointContract.balanceOf(user1),10000);
        assertEq(rewardPointContract.nonces(user1),1);
        assertEq(rewardPointContract.convertedPoints(user1),alreadyConverted+10000);
    }

    function test_mint_reverts_with__InvalidSignature_1() external{
        rewardPointContract.initialize(company1, address(rewardPointFactoryContract), 2, "Test", "TSTP");

        //preparing the signature - just like it happens in the server:
        bytes32 hashedMessage_server = keccak256(abi.encodePacked(user1, uint256(10000), uint256(0), address(rewardPointContract)));
        hashedMessage_server = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hashedMessage_server));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(company1_PK, hashedMessage_server);
        bytes memory signature_server = abi.encodePacked(r,s,v); //notice the change in the order of those variables, to create the invalid signature

        uint256 alreadyConverted=rewardPointContract.convertedPoints(user1);

        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(SignatureVerifier.InvalidSignature.selector, user1, signature_server));
        rewardPointContract.mint(10000,signature_server);
        vm.stopPrank();

        assertEq(rewardPointContract.balanceOf(user1),0);
        assertEq(rewardPointContract.nonces(user1),0);
        assertEq(rewardPointContract.convertedPoints(user1),alreadyConverted);
    }

    function test_mint_reverts_with__InvalidSignature_2() external{
        rewardPointContract.initialize(company1, address(rewardPointFactoryContract), 2, "Test", "TSTP");

        //preparing the signature - just like it happens in the server:
        bytes32 hashedMessage_server = keccak256(abi.encodePacked(user1, uint256(10000), uint256(0), address(rewardPointContract)));
        hashedMessage_server = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hashedMessage_server));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(MONET_PK, hashedMessage_server);
        bytes memory signature_server = abi.encodePacked(r,s,v); //notice the change in the order of those variables, to create the invalid signature

        uint256 alreadyConverted=rewardPointContract.convertedPoints(user1);

        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSelector(SignatureVerifier.InvalidSignature.selector, user2, signature_server));
        rewardPointContract.mint(10000,signature_server);
        vm.stopPrank();

        assertEq(rewardPointContract.balanceOf(user1),0);
        assertEq(rewardPointContract.nonces(user1),0);
        assertEq(rewardPointContract.convertedPoints(user1),alreadyConverted);
    }

    function test_mint_reverts_with__MintingHasStopped() external{
        rewardPointContract.initialize(company1, address(rewardPointFactoryContract), 2, "Test", "TSTP");

        vm.startPrank(company1);
        rewardPointContract.setMintingSwitch(false);
        vm.stopPrank();

        //preparing the signature - just like it happens in the server:
        bytes32 hashedMessage_server = keccak256(abi.encodePacked(user1, uint256(10000), uint256(0), address(rewardPointContract)));
        hashedMessage_server = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hashedMessage_server));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(MONET_PK, hashedMessage_server);
        bytes memory signature_server = abi.encodePacked(r,s,v); //notice the change in the order of those variables, to create the invalid signature

        uint256 alreadyConverted=rewardPointContract.convertedPoints(user1);

        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(SignatureVerifier.MintingHasStopped.selector));
        rewardPointContract.mint(10000,signature_server);
        vm.stopPrank();

        assertEq(rewardPointContract.balanceOf(user1),0);
        assertEq(rewardPointContract.nonces(user1),0);
        assertEq(rewardPointContract.convertedPoints(user1),alreadyConverted);
    }

    function test_mint_succeeds() external{
        rewardPointContract.initialize(company1, address(rewardPointFactoryContract), 2, "Test", "TSTP");

        //preparing the signature - just like it happens in the server:
        bytes32 hashedMessage_server = keccak256(abi.encodePacked(user1, uint256(10000), uint256(0), address(rewardPointContract)));
        hashedMessage_server = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hashedMessage_server));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(MONET_PK, hashedMessage_server);
        bytes memory signature_server = abi.encodePacked(r,s,v);

        uint256 alreadyConverted=rewardPointContract.convertedPoints(user1);

        vm.startPrank(user1);
        // validating - contract level:
        rewardPointContract.mint(10000,signature_server);
        vm.stopPrank();

        assertEq(rewardPointContract.balanceOf(user1),10000);
        assertEq(rewardPointContract.nonces(user1),1);
        assertEq(rewardPointContract.usedSignatures(signature_server),true);
        assertEq(rewardPointContract.convertedPoints(user1),(alreadyConverted+10000));
    }

    function test_SetMintingSwitch_reverts__nonOwner() external {
        rewardPointContract.initialize(company1, address(rewardPointFactoryContract), 2, "Test", "TSTP");

        vm.startPrank(user1);
        vm.expectRevert();
        rewardPointContract.setMintingSwitch(true);
        vm.stopPrank();
    }

    function test_SetMintingSwitch_succeeds() external {
        rewardPointContract.initialize(company1, address(rewardPointFactoryContract), 2, "Test", "TSTP");
        vm.startPrank(company1);
        rewardPointContract.setMintingSwitch(true);
        assertEq(rewardPointContract.mintingSwitch(),true);
        rewardPointContract.setMintingSwitch(false);
        assertEq(rewardPointContract.mintingSwitch(),false);
        vm.stopPrank();
    }
}
