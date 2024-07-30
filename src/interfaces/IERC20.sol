// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20 as OpenzeppelinIEC20} from "@openzeppelin/token/ERC20/IERC20.sol";

interface IERC20 is OpenzeppelinIEC20 {
    function decimals() external view returns (uint8);
}
