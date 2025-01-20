// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract ABICoder {
    // Questa funzione accetta un uint256 e restituisce la sua codifica ABI
    function encodeUint256(uint256 value) public pure returns (bytes memory) {
        // Utilizziamo l'encode di abi per ottenere la rappresentazione ABI del valore
        return abi.encode(value);
    }
}
