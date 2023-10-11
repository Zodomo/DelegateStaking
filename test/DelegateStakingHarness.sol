// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import "../src/DelegateStaking.sol";

// Testing harness to access internal functions
contract DelegateStakingHarness is DelegateStaking {
    constructor(address _delegateTokenContract, address _revokeReceiver)
        DelegateStaking(_delegateTokenContract, _revokeReceiver) { }
}