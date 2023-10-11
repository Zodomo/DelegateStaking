// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import {console2} from "forge-std/Test.sol";
import "solmate/test/utils/DSTestPlus.sol";
import "./DelegateStakingHarness.sol";

contract DelegateStakingTest is DSTestPlus {
    DelegateStaking public test;
    address public delegateToken;
    address public revokeRecipient;

    function setUp() public {
        test = new DelegateStakingHarness(delegateToken, revokeRecipient);
    }

    function testSetRevokeRecipient() public {
        
    }
}
