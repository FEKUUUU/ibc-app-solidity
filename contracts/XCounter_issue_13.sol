// Bridge lottery https://github.com/polymerdevs/Quest-Into-The-Polyverse-Phase-1/issues/13
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './base/CustomChanIbcApp.sol';

contract XCounter is CustomChanIbcApp {
    uint64 public counter;
    address public lastWinner;
    address public newDestinationChain;

    constructor(IbcDispatcher _dispatcher) CustomChanIbcApp(_dispatcher) {}

    function resetCounter() internal {
        counter = 0;
    }

    function increment() internal {
        counter++;
    }

    function sendPacket(bytes32 channelId, uint64 timeoutSeconds) external {
        increment();
        bytes memory payload = abi.encode(msg.sender, address(this)); // Adding the contract address
        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);
        dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
    }

    function onRecvPacket(IbcPacket memory packet) external override onlyIbcDispatcher returns (AckPacket memory) {
        counter++;
        (address _caller, address _contractAddress) = abi.decode(packet.data, (address, address));
        require(_contractAddress == address(this), "Invalid contract address");
        if (_caller == newDestinationChain) {
            // Reward the caller if they transacted towards the new destination chain
            lastWinner = _caller;
        }
        return AckPacket(true, abi.encode(counter));
    }

    function chooseNewDestinationChain(address _newDestinationChain) external {
        // Set a new destination chain
        newDestinationChain = _newDestinationChain;
    }

    function revealWinner() external returns (address) {
        // Reveal the winner of the last cycle
        return lastWinner;
    }
}

