// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../DataType.sol";

interface IMercuryDataDAO {
    function createDataSellOrder(
        uint256 _price,
        uint256 _dataUnits,
        DataType.dataType calldata _dataType
    ) external;

    function memberCount() external view returns (uint256);

    function isMember(address user) external view returns (bool);

    function distributeEarningsToMembers() external;
}
