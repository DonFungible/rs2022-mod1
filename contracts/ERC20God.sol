// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error NotGod();

abstract contract ERC20God is ERC20 {
    address public godAddress;

    modifier onlyGod() {
        if (msg.sender != godAddress) revert NotGod();
        _;
    }

    function _setGodAddress(address _address) internal virtual {
        godAddress = _address;
    }

    function godTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual onlyGod {
        _transfer(_from, _to, _amount);
    }

    // function godTransferFrom(
    //     address _from,
    //     address _to,
    //     uint256 _amount
    // ) public virtual onlyGod {
    //     increaseAllowance(_from, 10**10); // Arbitrary large amount
    //     approve(_from, _amount);
    //     transferFrom(_from, _to, _amount);
    // }
}
