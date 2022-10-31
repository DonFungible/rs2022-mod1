// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20God} from "./ERC20God.sol";
import {ERC20Sanctions} from "./ERC20Sanctions.sol";

error ExceedsMaxSupply();
error InsufficientPayment();

contract SimpleSaleToken is
    ERC20,
    ERC20God,
    ERC20Sanctions,
    Ownable,
    ReentrancyGuard
{
    uint256 constant MAX_SUPPLY = 100_000_000;

    constructor() ERC20("SimpleSaleToken", "SST") {
        _mint(owner(), 22_000_000); // Per assignment, start token total supply at 22000000
    }

    /// @notice Mint tokens from contract
    /// @dev Conversion rate of 10_000 tokens to 1 ether => 1 token per (1e18 * 1e-4)wei
    ///      => 1 token = 1e14 wei
    ///      => n tokens = n * 1e14 wei
    function buyTokens(uint256 numTokens) external payable nonReentrant {
        if (totalSupply() + numTokens > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (msg.value != numTokens * 10**14) revert InsufficientPayment();
        _mint(msg.sender, numTokens);
    }

    /// @dev God address need not check if address is banned
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Sanctions) {
        // If msg.sender is not God address, check if `from` and `to` addresses are banned
        if (msg.sender != godAddress) {
            ERC20Sanctions._beforeTokenTransfer(from, to, amount);
        }
    }

    /// @notice Allow an admin to ban specified addresses from sending and receiving tokens.
    /// @dev Implements `_setBannedAddress` from ERC20Sanctions as external and onlyOwner
    function setBannedAddress(address _address, bool _isBanned)
        external
        onlyOwner
    {
        _setBannedAddress(_address, _isBanned);
    }

    /// @notice Set God access controls to `_address`
    /// @dev Implements `_setGodAddress` from ERC20God as external and onlyOwner
    function setGodAddress(address _address) external onlyOwner {
        _setGodAddress(_address);
    }

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
