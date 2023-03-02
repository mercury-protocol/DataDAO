// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
@title DataType
@author Lajos Deme, Mercury Labs
@notice Represents a data type object. With an id and a string describing the data type.
 */
library DataType {
    struct dataType {
        uint256 id;
        string name;
    }
}