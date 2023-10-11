// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import {IERC721} from "openzeppelin/interfaces/IERC721.sol";
import {DelegateTokenStructs as Structs} from "./DelegateTokenLib.sol";
import {IDelegateRegistry} from "./IDelegateRegistry.sol";
import {IDelegateToken} from "./IDelegateToken.sol";

contract DelegateStaking {
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
        // Set approval for DelegateToken contract to use ERC721 asset if necessary
        if (!IERC721(_erc721).isApprovedForAll(address(this), _dt)) {
            IERC721(_erc721).setApprovalForAll(_dt, true);
        }

        /*
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
        */

        // Stake ERC721 asset in DelegateToken.sol for delegate token in return
        //delegateId = IDelegateToken(_dt).create(dInfo, ++_salt);
        delegateId = IDelegateToken(_dt).create(
            Structs.DelegateInfo(
                address(this),
                IDelegateRegistry.DelegationType.ERC721,
                msg.sender,
                0,
                _erc721,
                _tokenId,
                "",
                _expiry
            ),
            ++_salt
        );

        // Confirm delegate token was distributed to sender
        if (IERC721(_dt).ownerOf(delegateId) != msg.sender) {
            revert DelegationFailure();
        }
        // Confirm staked ERC721 token is held by DelegateToken contract
        if (IERC721(_erc721).ownerOf(_tokenId) != _dt) {
            revert DelegationFailure();
        }
    }

    // Stake ERC721 asset and retrieve delegate tokens
    function _stake721(
        address _erc721,
        uint256 _tokenId,
        uint256 _expiry
    ) internal {
        // Transfer ERC721 token to this contract
        IERC721(_erc721).transferFrom(IERC721(_erc721).ownerOf(_tokenId), address(this), _tokenId);
        // Ensure asset is now held by the contract
        if (IERC721(_erc721).ownerOf(_tokenId) != address(this)) {
            revert NotStaked();
        }
        // Process DelegateToken integration handling
        _delegate721(_erc721, _tokenId, _expiry);
    }
}