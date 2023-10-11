// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import {IERC721} from "openzeppelin/interfaces/IERC721.sol";
import {DelegateTokenStructs as Structs} from "./DelegateTokenLib.sol";
import {IDelegateRegistry} from "./IDelegateRegistry.sol";
import {IDelegateToken} from "./IDelegateToken.sol";

// Facilitate issuing delegate token to stakers so they can still claim airdrops/mints/etc
abstract contract DelegateStaking {
    error NotStaked(address token, uint256 tokenId);
    error StillLocked(address token, uint256 tokenId);

    event Staked(address token, uint256 tokenId);
    event Revoked(address token, uint256 tokenId);
    event Unstaked(address token, uint256 tokenId);
    event NewRevokeRecipient(address recipient);

    // Deployment address of DelegateToken.sol
    address internal immutable _dt;
    // Recipient of revoked assets, address(this) if none set
    address internal _revokeRecipient;
    // Incrementing value to ensure nobody uses the same salt value, irrespective of sender
    uint256 internal _salt;
    // Delegate ID derivation (contract address => tokenId => delegateId)
    mapping(address => mapping(uint256 => uint256)) internal _delegateIds;

    constructor(address _delegateTokenContract, address _revokeReceiver) {
        _dt = _delegateTokenContract;
        if (_revokeReceiver == address(0)) {
            _revokeReceiver = address(this);
        }
        _revokeRecipient = _revokeReceiver;
    }

    // Set recipient of revoked assets
    function _setRevokeRecipient(address _recipient) internal {
        _revokeRecipient = _recipient;
        emit NewRevokeRecipient(_recipient);
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
        // Process DelegateToken integration handling and store delegateId
        _delegateIds[_erc721][_tokenId] = _delegate721(_erc721, _tokenId, _expiry);
        emit Staked(_erc721, _tokenId);
    }

    // Rescind delegate token, withdraw from DelegateToken, purge storage
    function _remove721(address _erc721, uint256 _tokenId) private {
        // Cache delegateId for gas savings
        uint256 delegateId = _delegateIds[_erc721][_tokenId];
        // Rescind delegate token
        IDelegateToken(_dt).rescind(delegateId);
        // Withdraw ERC721 token from DelegateToken
        IDelegateToken(_dt).withdraw(delegateId);
        // Purge storage
        delete _delegateIds[_erc721][_tokenId];
    }

    // Revoke/Liquidate ownership of asset and withdraw to address(this) or recipient if set
    function _revoke721(address _erc721, uint256 _tokenId) internal {
        // Rescind delegate token and withdraw
        _remove721(_erc721, _tokenId);
        // Transfer token only if recipient isn't address(this)
        address recipient = _revokeRecipient;
        if (recipient == address(this)) { return; }
        IERC721(_erc721).transferFrom(address(this), _revokeRecipient, _tokenId);
        emit Revoked(_erc721, _tokenId);
    }

    // Check if staked token is unlockable and return the timestamp it expired if it is
    function _check721(address _erc721, uint256 _tokenId) internal view returns (uint256 timestamp) {
        // Cache DelegateInfo struct
        Structs.DelegateInfo memory dInfo = IDelegateToken(_dt).getDelegateTokenInfo(_delegateIds[_erc721][_tokenId]);
        // Revert if expiry hasn't been passed
        if (dInfo.expiry > block.timestamp) { revert StillLocked(dInfo.tokenContract, dInfo.tokenId); }
        return (dInfo.expiry);
    }

    // Unstake ERC721 if delegation expiry has been reached
    function _unstake721(
        address _erc721,
        address _recipient,
        uint256 _tokenId
    ) internal {
        // Verify if token can be unlocked
        _check721(_erc721, _tokenId);
        // Rescind delegate token and withdraw
        _remove721(_erc721, _tokenId);
        // Execute token transfer
        IERC721(_erc721).transferFrom(address(this), _recipient, _tokenId);
        emit Unstaked(_erc721, _tokenId);
    }

    // Implement ERC721 receiver interface to support safe transfers
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return DelegateStaking.onERC721Received.selector;
    }
}