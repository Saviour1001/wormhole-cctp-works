// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-solidity-sdk/WormholeRelayerSDK.sol";
import "wormhole-solidity-sdk/interfaces/IERC20.sol";

contract CCTPFrame is CCTPSender, CCTPReceiver {
    uint256 constant GAS_LIMIT = 250_000;
    uint256 public totalAmountBridged = 0;
    uint256 public totalAmountReceived = 0;

    event SentUSDC(
        uint16 targetChain,
        address targetCCTPFrame,
        address recipient,
        uint256 amount
    );

    event successfullyBridgedUSDC(uint256 amount);

    constructor(
        address _wormholeRelayer,
        address _wormhole,
        address _circleMessageTransmitter,
        address _circleTokenMessenger,
        address _USDC
    )
        CCTPBase(
            _wormholeRelayer,
            _wormhole,
            _circleMessageTransmitter,
            _circleTokenMessenger,
            _USDC
        )
    {
        setCCTPDomain(30, 6); // Base 
        setCCTPDomain(24, 2); // Optimism
        setCCTPDomain(23, 3); // Arbitrum
        setCCTPDomain(5,7);  // Polygon
        setCCTPDomain(6, 1); // Avalanche
    }

    function quoteCrossChainDeposit(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        // Cost of delivering token and payload to targetChain
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }

    function sendCrossChainDeposit(
        uint16 targetChain,
        address targetCCTPFrame,
        address recipient,
        uint256 amount
    ) public payable {
        uint256 cost = quoteCrossChainDeposit(targetChain);
        require(
            msg.value == cost,
            "msg.value must be quoteCrossChainDeposit(targetChain)"
        );

        IERC20(USDC).transferFrom(msg.sender, address(this), amount);

        bytes memory payload = abi.encode(recipient);
        sendUSDCWithPayloadToEvm(
            targetChain,
            targetCCTPFrame, // address (on targetChain) to send token and payload to
            payload,
            0, // receiver value
            GAS_LIMIT,
            amount
        );
        totalAmountBridged += amount;
        emit SentUSDC(targetChain, targetCCTPFrame, recipient, amount);
    }

    function receivePayloadAndUSDC(
        bytes memory payload,
        uint256 amountUSDCReceived,
        bytes32, // sourceAddress
        uint16, // sourceChain
        bytes32 // deliveryHash
    ) internal override onlyWormholeRelayer {
        address recipient = abi.decode(payload, (address));
        IERC20(USDC).transfer(recipient, amountUSDCReceived);
        totalAmountReceived += amountUSDCReceived;
        emit successfullyBridgedUSDC(amountUSDCReceived);
    }
}
