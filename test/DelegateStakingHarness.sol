// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import "../src/DelegateStaking.sol";

// Testing harness to access internal functions
contract DelegateStakingHarness is DelegateStaking {
    constructor(address _delegateTokenContract) DelegateStaking(_delegateTokenContract) { }

    function get_dt() public view returns (address) {
        return (_dt);
    }
    function get_salt() public view returns (uint256) {
        return (_salt);
    }
    function get_delegateIds(address _erc721, uint256 _tokenId) public view returns (uint256) {
        return (_delegateIds[_erc721][_tokenId]);
    }
    function get_delegateExpiry(uint256 _delegateId) public view returns (uint256) {
        return (_delegateExpiry[_delegateId]);
    }
    function get_revokeStatus(uint256 _delegateId) public view returns (bool) {
        return (_revokeStatus[_delegateId]);
    }

    function stake721(
        address _erc721,
        uint256 _tokenId,
        uint256 _expiry
    ) public {
        _stake721(_erc721, _tokenId, _expiry);
    }

    function revoke721(address _erc721, uint256 _tokenId) public {
        _revoke721(_erc721, _tokenId);
    }

    function unstake721(
        address _erc721,
        address _recipient,
        uint256 _tokenId
    ) public {
        _unstake721(_erc721, _recipient, _tokenId);
    }
}