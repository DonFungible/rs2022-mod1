// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error AddressBannedFromSending();
error AddressBannedFromReceiving();

abstract contract ERC20Sanctions is ERC20 {
    mapping(address => bool) isAddressBanned;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (isAddressBanned[from]) revert AddressBannedFromSending();
        if (isAddressBanned[to]) revert AddressBannedFromReceiving();
    }

    function _setBannedAddress(address _address, bool _isBanned)
        internal
        virtual
    {
        isAddressBanned[_address] = _isBanned;
    }
}
