// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "openzeppelin/interfaces/IERC721.sol";
import {DelegateTokenStructs as Structs} from "delegate-market/src/libraries/DelegateTokenLib.sol";
import {IDelegateRegistry} from "delegate-registry/src/IDelegateRegistry.sol";
import {IDelegateToken} from "delegate-market/src/interfaces/IDelegateToken.sol";

abstract contract DelegateStaking {
    error NotStaked();
    error DelegationFailure();

    // Deployment address of DelegateToken.sol
    address private immutable _dt;
    // Incrementing value to ensure nobody uses the same salt value, irrespective of sender
    uint256 private _salt;

    constructor(address _delegateTokenContract) {
        _dt = _delegateTokenContract;
    }

    // Internal handling for staking ERC721 asset in Delegate Market
    function _delegate721(
        address _erc721,
        uint256 _tokenId,
        uint256 _expiry
    ) private returns (uint256 delegateId) {
        // Ensure asset is already held by contract
        if (IERC721(_erc721).ownerOf(_tokenId) != address(this)) {
            revert NotStaked();
        }
        // Set approval for DelegateToken contract to use ERC721 asset if necessary
        if (!IERC721(_erc721).isApprovedForAll(address(this), _dt)) {
            IERC721(_erc721).setApprovalForAll(_dt, true);
        }

        // Instantiate struct and pack with all relevant data
        Structs.DelegateInfo memory dInfo;
        dInfo.principalHolder = address(this);
        dInfo.tokenType = IDelegateRegistry.DelegationType.ERC721;
        dInfo.delegateHolder = msg.sender;
        dInfo.amount = 0;
        dInfo.tokenContract = _erc721;
        dInfo.tokenId = _tokenId;
        dInfo.rights = "";
        dInfo.expiry = _expiry;

        // Stake ERC721 asset in DelegateToken.sol for delegate token in return
        delegateId = IDelegateToken(_dt).create(dInfo, ++_salt);

        // Confirm delegation was successful
        if (IERC721(_dt).ownerOf(delegateId) != msg.sender) {
            revert DelegationFailure();
        }
        if (IERC721(_erc721).ownerOf(_tokenId) != _dt) {
            revert DelegationFailure();
        }
    }
}
