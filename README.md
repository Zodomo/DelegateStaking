# DelegateStaking

The `DelegateStaking` contract provides ERC721 staking functionality to a inherting child contract that utilizes Delegate.xyz's delegate-market contracts to issue a liquid delegate token to the ERC721 asset staker. The liquid delegate token enables the asset staker to claim airdrops, discounted/free mints, or any other benefits entitled to holders of the ERC721 asset. This should prevent staked assets from losing all capital utility entitled to the holder during the staking period. Additionally, there is support for the staking platform to revoke the ownership rights from the staker in the event of a liquidation or other type of event, allowing the platform to utilize the asset for its own purposes once the delegation expires.

As of 11-Oct-2023, the delegate-market contracts are only on Goerli, so the test suite will work if you run fork tests against Goerli. This entire project was developed as a proof-of-concept and has not been extensively validated yet, despite total test coverage. Please use at your own risk!

## Contract Details

**SPDX-License-Identifier:** CC0-1.0
**Solidity Version:** 0.8.21
**Author:** Zodomo
**Contact Information:**  
- ENS: `Zodomo.eth`
- Farcaster: `zodomo`
- X: `@0xZodomo`
- Telegram: `@zodomo`
- GitHub: `Zodomo`
- Email: `zodomo@proton.me`

## Imports

- openzeppelin/interfaces/IERC721.sol
- delegate-market/src/libraries/DelegateTokenLib.sol
- delegate-registry/src/IDelegateRegistry.sol
- delegate-market/src/interfaces/IDelegateToken.sol

## Interfaces

- **IDelegateRegistry:** Used to obtain a struct used as a value in a DelegateToken.sol struct.
- **IDelegateToken:** DelegateToken interface handling all delegate-market integration functions.
- **IERC721:** Interaction with the ERC721 features of DelegateToken.

## Contract Inheritance

As this is an abstract contract, the inheritor needs to implement the following functions:
- **_stake721(address _erc721, uint256 _tokenId, uint256 _expiry)**
    - This function is responsible for staking the asset in the platform before routing it to delegate-market. This internally calls `_delegate721(address, uint256, uint256)` which handles the integration, and then stores the principal token with the platform in order to retain ownership if it is revoked from the staker. The token is effectively locked in DelegateToken until the `_expiry` timestamp is reached.
- **_revoke(address _erc721, uint256 _tokenId)**
    - This function removes ownership rights from the token staker, preventing their withdrawal of the asset once the delegation expiry is up. The delegate token cannot be rescinded from the staker until the delegation expiry has been reached.
- **_unstake721(address _erc721, address _recipient, uint256 _tokenId)**
    - This is called once the delegation expiry has been reached or surpassed. Upon this point, the contract will rescind the delegate token, withdraw it from DelegateToken to the staking contract, and then assess whether or not the staker's ownership rights were revoked. If they were, the function ends, but if it wasn't, the asset will be sent to the `_recipient` address.

## Errors

- **StillLocked:** The only custom error in the contract is thrown when an attempt to withdraw an asset that has an active delegation. An asset can only be withdrawn once the delegation expiry timestamp has been reached.

## Events
- **Staked(address token, uint256 tokenId):** Emitted when an ERC721 token is staked in the platform.
- **Revoked(address token, uint256 tokenId):** Emitted when the owner of a staked token has their ownership revoked.
- **Unstaked(address token, uint256 tokenId):** Emitted when a token is unstaked from the platform.

## Usage

1. Inherit this contract and ensure the proper DelegateToken address for your network is provided to the constructor.
2. Implement the functions discussed in the `Contract Inheritance` section of this README.
3. ENSURE your utilization regards `_expiry` as the timestamp of when the asset may be unstaked, and no sooner. It is okay if assets remain staked for longer, but consider the `_expiry` value to function as a timelock.

## Important Points

- Assets that are staked with a block.timestamp in the future for `_expiry` are considered locked. If the asset should not be locked, you should use `block.timestamp` for the expiry.

---

This README serves as a general overview and documentation of the `DelegateStaking` contract. For in-depth details and interactions, refer to the contract's code and associated comments or reach out to Zodomo directly.