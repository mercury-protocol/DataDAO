// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { CommonTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import { SendAPI } from "@zondax/filecoin-solidity/contracts/v0.8/SendAPI.sol";

contract DataDAOCore {
    /// @dev Send amount $FIL to the filecoin actor at actor_id
    /// @param actorID: actor at actor_id
    /// @param amount: Amount of $FIL
    function reward(CommonTypes.FilActorId actorID, uint256 amount) internal {
        SendAPI.send(actorID, amount);
    }
}