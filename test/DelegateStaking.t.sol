// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import {console2, Test} from "forge-std/Test.sol";
import {MockERC721} from "solady/../test/utils/mocks/MockERC721.sol";
import {IERC721} from "openzeppelin/interfaces/IERC721.sol";
import {IDelegateToken} from "../src/IDelegateToken.sol";
import {IDelegateRegistry} from "../src/IDelegateRegistry.sol";
import {DelegateTokenStructs as Structs} from "../src/DelegateTokenLib.sol";

import "./DelegateStakingHarness.sol";

contract DelegateStakingTest is Test {
    event Staked(address token, uint256 tokenId);
    event Revoked(address token, uint256 tokenId);
    event Unstaked(address token, uint256 tokenId);

    DelegateStakingHarness test;
    MockERC721 nft;
    address public delegateToken = 0xB20B20440A143177c7f1daf92967756e778DF68D; // Goerli
    address recipient = makeAddr("NEW_RECIPIENT");

    function setUp() public {
        test = new DelegateStakingHarness(delegateToken);
        nft = new MockERC721();
        nft.mint(address(this), 1);
        nft.mint(address(this), 2);
        nft.setApprovalForAll(address(test), true);
    }

    function _stake721() internal {
        vm.expectEmit(true, true, true, true);
        emit Staked(address(nft), 1);
        test.stake721(address(nft), 1, block.timestamp + 60);
        assertEq(test.get_salt(), 1);
    }
    function testStake721() public {
        _stake721();
        uint256 delegateId = test.get_delegateIds(address(nft), 1);
        Structs.DelegateInfo memory dInfo = IDelegateToken(test.get_dt()).getDelegateTokenInfo(delegateId);
        assertEq(dInfo.principalHolder, address(test));
        assertEq(uint8(dInfo.tokenType), uint8(IDelegateRegistry.DelegationType.ERC721));
        assertEq(dInfo.delegateHolder, address(this));
        assertEq(dInfo.amount, 0);
        assertEq(dInfo.tokenContract, address(nft));
        assertEq(dInfo.tokenId, 1);
        assertEq(dInfo.rights, "");
        assertEq(dInfo.expiry, block.timestamp + 60);
        assertEq(test.get_delegateExpiry(delegateId), block.timestamp + 60);
    }
    function testStake721Twice() public {
        _stake721();
        vm.expectEmit(true, true, true, true);
        emit Staked(address(nft), 2);
        test.stake721(address(nft), 2, block.timestamp + 60);
        assertEq(test.get_salt(), 2);
        uint256 delegateId = test.get_delegateIds(address(nft), 2);
        Structs.DelegateInfo memory dInfo = IDelegateToken(test.get_dt()).getDelegateTokenInfo(delegateId);
        assertEq(dInfo.principalHolder, address(test));
        assertEq(uint8(dInfo.tokenType), uint8(IDelegateRegistry.DelegationType.ERC721));
        assertEq(dInfo.delegateHolder, address(this));
        assertEq(dInfo.amount, 0);
        assertEq(dInfo.tokenContract, address(nft));
        assertEq(dInfo.tokenId, 2);
        assertEq(dInfo.rights, "");
        assertEq(dInfo.expiry, block.timestamp + 60);
        assertEq(test.get_delegateExpiry(delegateId), block.timestamp + 60);
    }
    
    function _revoke721() internal {
        vm.expectEmit(true, true, true, true);
        emit Revoked(address(nft), 1);
        test.revoke721(address(nft), 1);
    }
    function testRevoke721() public {
        _stake721();
        uint256 delegateId = test.get_delegateIds(address(nft), 1);
        _revoke721();
        Structs.DelegateInfo memory dInfo = IDelegateToken(test.get_dt()).getDelegateTokenInfo(delegateId);
        assertEq(dInfo.principalHolder, address(test));
        assertEq(uint8(dInfo.tokenType), uint8(IDelegateRegistry.DelegationType.ERC721));
        assertEq(dInfo.delegateHolder, address(this));
        assertEq(dInfo.amount, 0);
        assertEq(dInfo.tokenContract, address(nft));
        assertEq(dInfo.tokenId, 1);
        assertEq(dInfo.rights, "");
        assertEq(dInfo.expiry, block.timestamp + 60);
        assertEq(test.get_revokeStatus(delegateId), true);
        assertEq(test.get_delegateExpiry(delegateId), block.timestamp + 60);
    }

    function _unstake721() internal {
        vm.warp(block.timestamp + 61);
        vm.expectEmit(true, true, true, true);
        emit Unstaked(address(nft), 1);
        test.unstake721(address(nft), recipient, 1);
    }
    function testUnstake721() public {
        _stake721();
        _unstake721();
        assertEq(nft.ownerOf(1), recipient);
        assertEq(test.get_delegateExpiry(test.get_delegateIds(address(nft), 1)), 0);
    }
    function testUnstake721StillLocked() public {
        _stake721();
        vm.expectRevert(abi.encodeWithSelector(DelegateStaking.StillLocked.selector, address(nft), 1));
        test.unstake721(address(nft), recipient, 1);
    }
    function testUnstake721Revoked() public {
        _stake721();
        _revoke721();
        _unstake721();
        assertEq(nft.ownerOf(1), address(test));
        assertEq(test.get_delegateExpiry(test.get_delegateIds(address(nft), 1)), 0);
    }
}
