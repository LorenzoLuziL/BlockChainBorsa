// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Decoder {
    function decodeStrings(bytes[] memory byteArrays, string[] memory typesArray) public pure returns (string[] memory) {
        require(byteArrays.length == typesArray.length, "Arrays length mismatch");
        
        string[] memory decodedValues = new string[](byteArrays.length);
        
        for (uint i = 0; i < typesArray.length; i++) {
            if (keccak256(bytes(typesArray[i])) == keccak256(bytes("string"))) {
                decodedValues[i] = string(byteArrays[i]);

            } else if (keccak256(bytes(typesArray[i])) == keccak256(bytes("int"))) {

                int decodedInt = abi.decode(byteArrays[i], (int));
                decodedValues[i] = intToString(decodedInt); // Converti l'intero in una stringa
            } 
                 else if(keccak256(bytes(typesArray[i])) == keccak256(bytes("bool"))) {
                    

                    decodedValues[i] = byteToBoolAndString(byteArrays[i]);

            }
        }
 
        return decodedValues;
    }
    
    function intToString(int _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 absoluteValue = uint256(_i < 0 ? -_i : _i);
        uint256 maxLength = 100; // Lunghezza massima dell'intero come stringa
        bytes memory reversed = new bytes(maxLength);
        uint256 i = 0;
        while (absoluteValue > 0) {
            uint256 remainder = absoluteValue % 10;
            absoluteValue /= 10;
            reversed[i++] = bytes1(uint8(48 + remainder)); // Converti il numero in un carattere ASCII
        }
        bytes memory s = new bytes(i); // Dimensione effettiva della stringa
        for (uint256 j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // Inverti la stringa
        }
        return string(s);
    }


      function byteToBoolAndString(bytes memory data) internal pure returns (string memory) {
        require(data.length == 1, "Invalid input length");
        
        if (data[0] == 0x00) {
            return "false";
        } else if (data[0] == 0x01) {
            return "true";
        } else {
            revert("Invalid boolean value");
        }
    }

     function getSelectors() public pure returns (bytes4) {
        return (this.decodeStrings.selector);
    }

// Call function serve per chiamare una particolare funzione in realtime, passandogli come input il codice univoco "selector"
/* passaggi per testare la funzione :

    1. una volta eseguito il deploy del contratto chiamare la funzione getSelector. (Essa resitituirà un codice univoco che si riferisce alla funzione decodeString)
    2. Copiare il selector e inserirlo nella funzione "CallFunction"
    3. Per quanto riguarda la voce ByteArrays si può inserire "0x68656c6c6f" corrisponde ad hello in esadecimale ed "0x00" corrisponde a false
    4. Inserire in typesArray "string" ed "bool" o a seconda dei valori inseriti il rispettivo tipo.
    5. Eseguire la funzione.

    La differenza tra decodeString ed CallFunction, è che la CallFunction può eseguire tutte le funzioni che vogliamo in runTime  grazie al Selector
    ovviamente in questo smart contract è presente solamente DecodeString, ma le allego altri due smart contract per farle capire meglio il meccanismo


*/

     function callFunction(bytes4 selector, bytes[] memory byteArrays, string[] memory typesArray) public pure returns (string[] memory) {
        
        if (selector == this.decodeStrings.selector) {
            return decodeStrings(byteArrays, typesArray);

        } 
         else {

            revert("Invalid selector");
        }
    }
}
