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

    /*// Funzione che chiama una delle tre funzioni in base al selettore fornito
    function CallFunctionWithSelector(bytes4 selector, uint256 x, uint256 y, uint256 z) public pure returns (uint256) {
        if (selector == this.A.selector) {
            return A(x, y);
        } else if (selector == this.B.selector) {
            (bool result, uint256 intValue) = B(x);
            // Converti il booleano in un intero: true diventa 1 e false diventa 0
            return result ? intValue : 0;
        } else if (selector == this.C.selector) {
            return C(x, y, z);
        } else {
            revert("Invalid Selector");
        }
    }*/

    // Funzione che chiama una delle tre funzioni in base ai dati forniti
    function CallFunction(bytes memory data) public pure returns (uint256) {
        // Estrai il selettore dalle prime 4 byte dei dati
        bytes4 selector;
        assembly {
            selector := mload(add(data, 0x20))
        }

        // Estrai gli argomenti rimanenti dai dati
        uint256 x;
        uint256 y;
        uint256 z;

        assembly {
            x := mload(add(data, 0x24))
            y := mload(add(data, 0x44))
            z := mload(add(data, 0x64))
        }

        if (selector == this.A.selector) {
            return A(x, y);
        } else if (selector == this.B.selector) {
            (bool result, uint256 intValue) = B(x);
            // Converti il booleano in un intero: true diventa 1 e false diventa 0
            return result ? intValue : 0;
        } else if (selector == this.C.selector) {
            return C(x, y, z);
        } else {
            revert("Invalid Selector");
        }
    }

    function getSelectors() public pure returns (bytes4, bytes4, bytes4) {
        return (this.A.selector, this.B.selector, this.C.selector);
    }
}
