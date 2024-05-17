// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CCTPFrame} from "../src/CCTPFrame.sol";

import "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";
import "wormhole-solidity-sdk/interfaces/IERC20.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract CCTPFrameTest is WormholeRelayerBasicTest {
    CCTPFrame public cctpSource;
    CCTPFrame public cctpTarget;

    IERC20 public USDCSource;
    IERC20 public USDCTarget;

    constructor() {
        setMainnetForkChains(30,24);
    }

    function setUpSource() public override {
        USDCSource = IERC20(address(sourceChainInfo.USDC));
        mintUSDC(sourceChain, address(this), 5000e18);
        cctpSource = new CCTPFrame(
            address(relayerSource),
            address(wormholeSource),
            address(sourceChainInfo.circleMessageTransmitter),
            address(sourceChainInfo.circleTokenMessenger),
            address(USDCSource)
        );
    }

    function setUpTarget() public override {
        USDCTarget = IERC20(address(targetChainInfo.USDC));
        mintUSDC(sourceChain, address(this), 5000e18);
        cctpTarget = new CCTPFrame(
            address(relayerTarget),
            address(wormholeTarget),
            address(targetChainInfo.circleMessageTransmitter),
            address(targetChainInfo.circleTokenMessenger),
            address(USDCTarget)
        );
    }

    function setUpGeneral() public override {
        vm.selectFork(sourceFork);
        cctpSource.setRegisteredSender(
            targetChain,
            toWormholeFormat(address(cctpTarget))
        );

        vm.selectFork(targetFork);
        cctpTarget.setRegisteredSender(
            sourceChain,
            toWormholeFormat(address(cctpSource))
        );
    }

    function testRemoteDeposit() public {
        uint256 amount = 100e6;
        USDCSource.approve(address(cctpSource), amount);

        vm.selectFork(targetFork);
        address recipient = 0x1234567890123456789012345678901234567890;

        vm.selectFork(sourceFork);
        uint256 cost = cctpSource.quoteCrossChainDeposit(targetChain);

        vm.recordLogs();
        cctpSource.sendCrossChainDeposit{value: cost}(
            targetChain,
            address(cctpTarget),
            recipient,
            amount
        );
        performDelivery();

        vm.selectFork(targetFork);
        assertEq(USDCTarget.balanceOf(recipient), amount);
    }
}
