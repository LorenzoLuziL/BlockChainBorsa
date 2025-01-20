// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FunctionContract {
    // Funzione A che somma due interi
    function A(uint256 x, uint256 y) public pure returns (uint256) {
        return x + y;
    }

    // Funzione B che ritorna true se il numero è maggiore di 50 e restituisce 1, altrimenti ritorna false e restituisce 0
    function B(uint256 x) public pure returns (bool, uint256) {
        if (x > 50) {
            return (true, 1);
        } else {
            return (false, 0);
        }
    }

    // Funzione C che ritorna il minore tra tre numeri
    function C(uint256 x, uint256 y, uint256 z) public pure returns (uint256) {
        return min(x, y, z);
    }

    // Funzione ausiliaria per calcolare il minimo tra tre numeri
    function min(uint256 a, uint256 b, uint256 c) private pure returns (uint256) {
        if (a < b && a < c) {
            return a;
        } else if (b < c) {
            return b;
        } else {
            return c;
        }
    }

    // Stringa da provare :0000000000000000000000000000000000000000000000000000000000000082 sarebbe 130
    // 000000000000000000000000000000000000000000000000000000000000000d sarebbe 13

    // Funzione che chiama una delle tre funzioni in base ai dati forniti
    function CallFunction(bytes memory data) public view returns (uint256) {
        
        (bool success, bytes memory result) = address(this).staticcall(data);
        require(success, "Call failed");

        return abi.decode(result, (uint256));
    }

    function getSelectors() public pure returns (bytes4, bytes4, bytes4) {
        return (this.A.selector, this.B.selector, this.C.selector);
    }
}
