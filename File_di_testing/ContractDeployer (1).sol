// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract ContractDeployer {
    event ContractDeployed(address indexed deployedAddress);

    function deployContract(bytes memory bytecode) public returns (address deployedAddress) {
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(deployedAddress)) {
                revert(0, 0)
            }
        }
        emit ContractDeployed(deployedAddress);
    }
}
