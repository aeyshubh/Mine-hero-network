// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MineableToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant BLOCK_REWARD = 50 * 10**18; // 50 tokens
    uint256 public constant DIFFICULTY_ADJUSTMENT_INTERVAL = 2016; // ~2 weeks if 1 block per 10 minutes
    uint256 public constant TARGET_BLOCK_TIME = 600; // 10 minutes

    uint256 public lastDifficultyAdjustmentBlock;
    uint256 public currentDifficulty;
    uint256 public lastBlockTime;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10**18); // Initial supply
        lastDifficultyAdjustmentBlock = block.number;
        currentDifficulty = 1;
        lastBlockTime = block.timestamp;
    }

    function submitSolution(uint256 nonce) public {
        bytes32 hash = keccak256(abi.encodePacked(block.number, msg.sender, nonce));
        require(uint256(hash) < (2**256).div(currentDifficulty), "Invalid solution");

        _mint(msg.sender, BLOCK_REWARD);
        
        adjustDifficulty();
        lastBlockTime = block.timestamp;
    }

    function adjustDifficulty() private {
        if (block.number.sub(lastDifficultyAdjustmentBlock) >= DIFFICULTY_ADJUSTMENT_INTERVAL) {
            uint256 timeElapsed = block.timestamp.sub(lastBlockTime);
            uint256 expectedTime = TARGET_BLOCK_TIME.mul(DIFFICULTY_ADJUSTMENT_INTERVAL);

            if (timeElapsed < expectedTime.mul(4).div(5)) {
                currentDifficulty = currentDifficulty.add(1);
            } else if (timeElapsed > expectedTime.mul(6).div(5)) {
                currentDifficulty = currentDifficulty.sub(1);
            }

            lastDifficultyAdjustmentBlock = block.number;
        }
    }

    function getCurrentDifficulty() public view returns (uint256) {
        return currentDifficulty;
    }
}