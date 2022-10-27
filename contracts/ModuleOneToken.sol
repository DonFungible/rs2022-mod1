// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Requirements
//  1. ERC20 that allows an admin to ban specified addresses from sending and receiving tokens
//  2. A special address is able to transfer tokens between addresses at will
//  3. Price: 10k tokens = 1 eth. Supply: 22e6 tokens
//  4. Bonding curve

error NotGod();
error AddressBannedFromSending();
error AddressBannedFromReceiving();

contract ModuleOneToken is ERC20, Ownable {
    uint256 public unlockTime;
    address public godAddress;
    mapping(address => bool) isAddressBanned;

    event Withdrawal(uint256 amount, uint256 when);

    constructor() ERC20("MODULE1", "MOD1") {}

    modifier onlyGod() {
        if (msg.sender != godAddress) revert NotGod();
        _;
    }

    // ERC20 with sanctions. Create an ERC20 token that allows an admin to ban specified
    // addresses from sending and receiving tokens.
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (msg.sender != godAddress) {
            if (isAddressBanned[from]) revert AddressBannedFromSending();
            if (isAddressBanned[to]) revert AddressBannedFromReceiving();
        }

        super._transfer(from, to, amount);
    }

    function setBannedAddress(address _address, bool _isBanned)
        external
        onlyOwner
    {
        isAddressBanned[_address] = _isBanned;
    }

    function setGodAddress(address _address) external onlyOwner {
        godAddress = _address;
    }

    function godTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external onlyGod {
        // Look into transferFrom
        this.approve(_from, _amount);
        this.transferFrom(_from, _to, _amount);
    }

    function withdraw() public {
        require(block.timestamp >= unlockTime, "You can't withdraw yet");

        emit Withdrawal(address(this).balance, block.timestamp);
    }
}
