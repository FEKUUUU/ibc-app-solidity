//Exploring new ways to bridge with Catalyst - ISSUE https://github.com/polymerdevs/Quest-Into-The-Polyverse-Phase-1/issues/19
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './base/CustomChanIbcApp.sol';

contract XCounter is CustomChanIbcApp {
    uint64 public counter;
    mapping (uint64 => address) public counterMap;

    constructor(IbcDispatcher _dispatcher) CustomChanIbcApp(_dispatcher) {}

    function resetCounter() internal {
        counter = 0;
    }

    function increment() internal {
        counter++;
    }

    function sendPacket(bytes32 channelId, uint64 timeoutSeconds) external {
        increment();
        bytes memory payload = abi.encode(msg.sender, address(this)); // Dodajemy adres kontraktu
        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);
        dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
    }

    function generateGiftLink(bytes32 channelId, uint64 timeoutSeconds) external view returns (string memory) {
        // Generowanie linku na podstawie danych, aby umożliwić użytkownikowi udostępnienie go przyjacielowi
        string memory link = string(abi.encodePacked("https://example.com/receive?channel=", bytes32ToString(channelId), "&timeout=", uintToString(timeoutSeconds)));
        return link;
    }

    function receiveGift(address friendAddress, bytes32 channelId, uint64 timeoutSeconds) external {
        // Przyjmowanie linku od przyjaciela i odbiór środków na waultu
        bytes memory payload = abi.encode(friendAddress, address(this)); // Dodajemy adres kontraktu
        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);
        dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
    }

    function onRecvPacket(IbcPacket memory packet) external override onlyIbcDispatcher returns (AckPacket memory) {
        counter++;
        (address _caller, address _contractAddress) = abi.decode(packet.data, (address, address));
        require(_contractAddress == address(this), "Invalid contract address");
        counterMap[packet.sequence] = _caller;
        return AckPacket(true, abi.encode(counter));
    }

    function onAcknowledgementPacket(IbcPacket calldata, AckPacket calldata ack) external override onlyIbcDispatcher {
        (uint64 _counter) = abi.decode(ack.data, (uint64));
        if (_counter != counter) {
            resetCounter();
        }
    }

    function onTimeoutPacket(IbcPacket calldata packet) external override onlyIbcDispatcher {
        // Obsługa timeoutu (opcjonalne)
    }

    // Funkcje pomocnicze
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function uintToString(uint64 v) internal pure returns (string memory) {
        uint64 maxlength = 20;
        bytes memory reversed = new bytes(maxlength);
        uint64 i = 0;
        while (v != 0) {
            uint64 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint64 j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        return string(s);
    }
}
