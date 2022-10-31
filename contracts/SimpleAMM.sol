// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error DepositTransferFailed();
error ReturnTransferFailed();

contract TokenA is ERC20 {
    constructor() ERC20("TokenA", "A") {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

contract TokenB is ERC20 {
    constructor() ERC20("TokenB", "B") {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

interface ITokenA {
    function mint(uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface ITokenB {
    function mint(uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// Product of tokens stored in the contract is constant
contract SimpleAMM {
    address public immutable addrTokenA;
    address public immutable addrTokenB;

    uint256 public numTokenA = 10**6; // Per assignment, start with 1m of each tokens. If not assignment, would assign this variable via constructor
    uint256 public numTokenB = 10**6;
    uint256 public constant K = 10**12; // Reference constant s/t numToken1 * numToken2 = K

    constructor(address _addrTokenA, address _addrTokenB) {
        addrTokenA = _addrTokenA;
        addrTokenB = _addrTokenB;

        ITokenA(addrTokenA).mint(numTokenA);
        ITokenB(addrTokenB).mint(numTokenB);
    }

    function depositTokenA(uint256 numTokenADeposited) external {
        // Transfer token A from user to contract
        bool success = ITokenA(addrTokenA).transferFrom(
            msg.sender,
            address(this),
            numTokenADeposited
        );
        if (!success) revert DepositTransferFailed();
        numTokenA += numTokenADeposited;

        // Return token B to user
        uint256 numTokenBToReturn = computeDeltaB(numTokenADeposited);
        success = ITokenB(addrTokenB).transferFrom(
            address(this),
            msg.sender,
            numTokenBToReturn
        );
        if (!success) revert ReturnTransferFailed();
        numTokenB -= numTokenBToReturn;
    }

    function depositTokenB(uint256 numTokenBDeposited) external {
        // Transfer token B from user to contract
        bool success = ITokenB(addrTokenB).transferFrom(
            msg.sender,
            address(this),
            numTokenBDeposited
        );
        if (!success) revert DepositTransferFailed();
        numTokenB += numTokenBDeposited;

        // Return token A to user
        uint256 numTokenAToReturn = computeDeltaB(numTokenBDeposited);
        success = ITokenA(addrTokenB).transferFrom(
            address(this),
            msg.sender,
            numTokenAToReturn
        );
        if (!success) revert ReturnTransferFailed();
        numTokenA -= numTokenAToReturn;
    }

    /// @dev (A * B) = K
    ///     => (A + dA)*(B - dB) = K
    ///     If user deposits into contract, compute dB to return to user.
    ///     dB = B - K/(A+dA)
    function computeDeltaB(uint256 deltaA) public view returns (uint256) {
        return numTokenB - K / (numTokenA + deltaA);
    }

    /// @dev (A * B) = K
    ///     => (B + dB)*(A - dA) = K
    ///     If user deposits into contract, compute dA to return to user.
    ///     dA = A - K/(B+dB)
    function computeDeltaA(uint256 deltaB) public view returns (uint256) {
        return numTokenA - K / (numTokenB + deltaB);
    }
}
