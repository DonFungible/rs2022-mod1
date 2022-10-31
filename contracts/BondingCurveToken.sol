// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20God} from "./ERC20God.sol";
import {ERC20Sanctions} from "./ERC20Sanctions.sol";

error ExceedsMaxSupply();
error ExceedsMinSupply();
error InsufficientPayment();
error NoFundsToWithdraw();
error TransferFailed();

contract BondingCurveToken is
    ERC20,
    ERC20God,
    ERC20Sanctions,
    Ownable,
    ReentrancyGuard
{
    uint256 constant MAX_SUPPLY = 100_000_000;
    // uint256 constant CURVE_SLOPE = 10_000 / 22; // Linear bonding curve: 10k tokens per 1 ether @ 22m supply // ! unable to divide 10000 by 22 therefore use inverse
    uint256 constant CURVE_SLOPE_INV = 22_000_000 / 10_000; // Linear bonding curve: 10k tokens per 1 ether @ 22m supply
    uint256 constant LOSS_PERC = 10; // Loss percentage when selling tokens back to contract

    uint256 public ownerWithdrawable; // Amount that the contract owner can withdraw

    constructor() ERC20("BondingCurveToken", "BCT") {
        _mint(owner(), 22_000_000); // Per assignment, start token total supply at 22000000
    }

    /// @dev Compute value to buy or sell `numTokens` tokens using a linear bonding curve
    ///      by computing the area under the curve:
    ///         area = 0.5 * x * y (where y = CURVE_SLOPE * x)
    ///         area1 = 0.5 * CURVE_SLOPE * totalSupply() * totalSupply();
    ///         area2 = 0.5 * (CURVE_SLOPE * (totalSupply() + numTokens) * (totalSupply() + numTokens);
    ///         (where CURVE_SLOPE = 1 / CURVE_SLOPE_INV)
    ///         value = CURVE_SLOPE * (numTokens * totalSupply() + 0.5 * numTokens^2);
    function computeValue(uint256 numTokens) public view returns (uint256) {
        return ((1 / CURVE_SLOPE_INV) *
            (numTokens * totalSupply() + (numTokens * numTokens) / 2));
    }

    /// @notice Mint tokens from contract
    /// @dev Buy value is computed using linear bonding curve
    function buyTokens(uint256 numTokens) external payable nonReentrant {
        if (totalSupply() + numTokens > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (msg.value != computeValue(numTokens)) revert InsufficientPayment();
        _mint(msg.sender, numTokens);
    }

    /// @notice Sell token back to contract at a 10% loss
    /// @dev Sale value is computed using linear bonding curve.
    ///      Tokens sold are burned to reduce totalSupply.
    ///      Owner is able to withdraw the 10% loss fee.
    function sellTokens(uint256 numTokens) external nonReentrant {
        if (totalSupply() - numTokens < 0) revert ExceedsMinSupply();
        uint256 sellValue = computeValue(numTokens);
        uint256 sellerClaimable = sellValue * (1 - LOSS_PERC / 100);
        ownerWithdrawable += (sellValue * LOSS_PERC) / 100;
        _burn(msg.sender, numTokens);
        _release(msg.sender, sellerClaimable);
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

    /// @notice Allows owner to withdraw `ownerWithdrawable`
    function ownerWithdraw() external onlyOwner {
        if (ownerWithdrawable == 0) revert NoFundsToWithdraw();
        _release(payable(owner()), ownerWithdrawable);
    }

    /// @notice Transfer `_amount` out of contract to `_address`
    function _release(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        if (!success) revert TransferFailed();
    }
}
