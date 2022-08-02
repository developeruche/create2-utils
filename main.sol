// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Factory {
    /// @dev this function would deploy the specified contract and return the address
    function deploy(
        address _owner,
        uint _foo,
        bytes32 _salt
    ) public payable returns (address) {
        return address(new TestContract{salt: _salt}(_owner, _foo));
    }
}


contract FactoryAssembly {
    event Deployed(address addr, uint salt);

    /// @dev obtain the byte code for the smart contract to be deployed
    function getBytecode(address _owner, uint _foo) public pure returns (bytes memory) {
        bytes memory bytecode = type(TestContract).creationCode;

        return abi.encodePacked(bytecode, abi.encode(_owner, _foo));
    }

    /// @dev obtaining the address the contract would deployed to
    function getAddress(bytes memory bytecode, uint _salt)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    /// @dev deploying the contract, new contract address would be emitted if successful
    function deploy(bytes memory bytecode, uint _salt) public payable {
        address addr;

        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                _salt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);
    }
}

contract TestContract {
    address public owner;
    uint public foo;

    constructor(address _owner, uint _foo) payable {
        owner = _owner;
        foo = _foo;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}