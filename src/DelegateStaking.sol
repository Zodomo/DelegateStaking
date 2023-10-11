// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import {IERC721} from "openzeppelin/interfaces/IERC721.sol";
import {DelegateTokenStructs as Structs} from "./DelegateTokenLib.sol";
import {IDelegateRegistry} from "./IDelegateRegistry.sol";
import {IDelegateToken} from "./IDelegateToken.sol";

contract DelegateStaking {
    error NotStaked(address token, uint256 tokenId);
    error StillLocked(address token, uint256 tokenId);
    error DelegationFailure(address token, uint256 tokenId);

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

        // Stake ERC721 asset in DelegateToken.sol for delegate token in return
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
            revert DelegationFailure(_erc721, _tokenId);
        }
        // Confirm staked ERC721 token is held by DelegateToken contract
        if (IERC721(_erc721).ownerOf(_tokenId) != _dt) {
            revert DelegationFailure(_erc721, _tokenId);
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
            revert NotStaked(_erc721, _tokenId);
        }
        // Process DelegateToken integration handling
        _delegate721(_erc721, _tokenId, _expiry);
    }

    // Check if staked token is unlockable
    function _check721(uint256 _delegateId) internal view returns (uint256 timestamp) {
        Structs.DelegateInfo memory dInfo = IDelegateToken(_dt).getDelegateTokenInfo(_delegateId);
        if (dInfo.expiry > block.timestamp) { revert StillLocked(dInfo.tokenContract, dInfo.tokenId); }
        return (dInfo.expiry);
    }

    function _unstake721(
        address _erc721,
        address _recipient,
        uint256 _tokenId
    ) internal {

    }
}