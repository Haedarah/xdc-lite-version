// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {UpgradeableBeacon} from "@openzeppelin/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title RewardPointBeacon
 * @notice inherits UpgradeableBeacon. This is the beacon contract for RewardPointProxy
 *
 */
contract RewardPointBeacon is UpgradeableBeacon {
    /**
     * @param _implementation Address of depolyed Payroll contract
     */
    constructor(address _implementation, address _initialOwner) UpgradeableBeacon(_implementation, _initialOwner) {}
}
