// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
/**
 * @title CCIPReceiverUpgradeable
 * @dev 可升级版本的 CCIPReceiver
 */
abstract contract CCIPReceiverUpgradeable is Initializable {
    // CCIP 路由器地址（需根据网络配置，如以太坊主网为 0x2718281c...）
    // https://docs.chain.link/ccip/directory/testnet
    address public ccipRouter;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __CCIPReceiver_init(address router) internal onlyInitializing {
        ccipRouter = router;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(CCIPReceiver).interfaceId;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;
}