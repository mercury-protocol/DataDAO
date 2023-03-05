// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MercuryDataDAO.sol";

contract MercuryDAOFactory is Ownable {
    IERC20 MCY;
    address dataManager;

    address masterMercuryDAO;

    address[] public deployedDAOs;

    constructor(
        IERC20 _MCY,
        address _dataManager,
        address _masterMercuryDAO
    ) {
        MCY =_MCY;
        dataManager = _dataManager;
        masterMercuryDAO = _masterMercuryDAO;
    }

    function createMercuryDataDAO(
        string memory name,
        string memory symbol,
        address[] memory admins
    ) external {
        MercuryDataDAO _dataDAO = MercuryDataDAO(Clones.clone(masterMercuryDAO));
        _dataDAO.initialize(name, symbol, admins, MCY, dataManager);
        deployedDAOs.push(address(_dataDAO));
    }

    function setMasterDaoContract(address _masterDao) external onlyOwner {
        masterMercuryDAO = _masterDao;
    }

    function setMercury(IERC20 _mcy, address _dataManager) external onlyOwner {
        MCY = _mcy;
        dataManager = _dataManager;
    }


    function numberOfDAOs() external view returns (uint256) {
        return deployedDAOs.length;
    }
}