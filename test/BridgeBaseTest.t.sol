// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {InvariantTest} from "forge-std/InvariantTest.sol";
import "../contracts/BridgeCommittee.sol";
import "../contracts/BridgeVault.sol";
import "../contracts/SuiBridge.sol";

contract BridgeBaseTest is InvariantTest, Test {
    address committeeMemberA;
    address committeeMemberB;
    address committeeMemberC;
    address committeeMemberD;
    address committeeMemberE;

    uint256 committeeMemberPkA;
    uint256 committeeMemberPkB;
    uint256 committeeMemberPkC;
    uint256 committeeMemberPkD;
    uint256 committeeMemberPkE;

    address bridgerA;
    address bridgerB;

    address deployer;

    // TODO: double check these addresses (they're from co-pilot)
    address wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address wBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address USDCWhale = 0x51eDF02152EBfb338e03E30d65C15fBf06cc9ECC;

    BridgeCommittee public committee;
    SuiBridge public bridge;
    BridgeVault public vault;

    function setUpBridgeTest() public {
        vm.createSelectFork(
            string.concat(
                "https://mainnet.infura.io/v3/",
                vm.envString("INFURA_API_KEY")
            )
        );
        (committeeMemberA, committeeMemberPkA) = makeAddrAndKey("a");
        (committeeMemberB, committeeMemberPkB) = makeAddrAndKey("b");
        (committeeMemberC, committeeMemberPkC) = makeAddrAndKey("c");
        (committeeMemberD, committeeMemberPkD) = makeAddrAndKey("d");
        (committeeMemberE, committeeMemberPkE) = makeAddrAndKey("e");
        bridgerA = makeAddr("bridgerA");
        bridgerB = makeAddr("bridgerB");
        vm.deal(committeeMemberA, 1 ether);
        vm.deal(committeeMemberB, 1 ether);
        vm.deal(committeeMemberC, 1 ether);
        vm.deal(committeeMemberD, 1 ether);
        vm.deal(committeeMemberE, 1 ether);
        vm.deal(bridgerA, 1 ether);
        vm.deal(bridgerB, 1 ether);
        deployer = address(1);
        vm.startPrank(deployer);
        address[] memory _committee = new address[](5);
        uint16[] memory _stake = new uint16[](5);
        _committee[0] = committeeMemberA;
        _committee[1] = committeeMemberB;
        _committee[2] = committeeMemberC;
        _committee[3] = committeeMemberD;
        _committee[4] = committeeMemberE;
        _stake[0] = 1000;
        _stake[1] = 1000;
        _stake[2] = 1000;
        _stake[3] = 2002;
        _stake[4] = 4998;
        committee = new BridgeCommittee();
        committee.initialize(_committee, _stake);
        vault = new BridgeVault();
        address[] memory _supportedTokens = new address[](4);
        _supportedTokens[0] = wBTC;
        _supportedTokens[1] = wETH;
        _supportedTokens[2] = USDC;
        _supportedTokens[3] = USDT;
        bridge = new SuiBridge();
        uint8 _chainId = 1;
        bridge.initialize(
            _supportedTokens,
            address(committee),
            address(vault),
            wETH,
            _chainId
        );
        vault.transferOwnership(address(bridge));

        targetContract(address(committee));
        targetContract(address(vault));
        targetContract(address(bridge));
    }

    function test() public {}

    // Helper function to get the signature components from an address
    function getSignature(
        bytes32 digest,
        uint256 privateKey
    ) public pure returns (bytes memory) {
        // r and s are the outputs of the ECDSA signature
        // r,s and v are packed into the signature. It should be 65 bytes: 32 + 32 + 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // pack v, r, s into 65bytes signature
        return abi.encodePacked(r, s, v);
    }

    function encodeMessage(
        Messages.Message memory message
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                "SUI_NATIVE_BRIDGE",
                message.messageType,
                message.version,
                message.nonce,
                message.chainID,
                message.payload
            );
    }
}
