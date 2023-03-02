// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { MarketTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import { MarketAPI } from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import "./base/DataDAOCore.sol";
import "./interfaces/IDataDAO.sol";

contract DataDAO is IDataDAO, DataDAOCore {
    using SafeMath for uint256;

    /// @dev Gets a cid and returns Deal details associated with the cid
    mapping(bytes => Deal) public deals;
    /// @dev Gets a cid and provider returns true or false depending upon if its the providers of the cid
    mapping(bytes => mapping(uint64 => bool)) public cidProviders;

    /// @dev Creates a new deal proposal. 
    /// @param _cidraw: cid for which the deal proposal is to be created.
    /// @param _size: size of cid
    /// @param _dealDurationInDays: deal duration in Days
    function createDealProposal(bytes memory _cidraw, uint _size, uint256 _dealDurationInDays) internal {
       
        Deal memory newDeal = Deal({
            proposedBy: msg.sender,
            cidraw: _cidraw,
            size: _size,
            storageFees: 0,
            dealStartBlockStamp: 0,
            dealDurationInDays: _dealDurationInDays,
            dealState: DealState.Proposed
        });

        deals[_cidraw] = newDeal;
    }

    /// @dev Approves or Rejects the proposal - This would enable to govern the data that is stored by the DAO 
    /// @param _cidraw: cid of the proposal
    /// @param _choice: decision of the DAO on the proposal
    function approveOrRejectDealProposal(bytes memory _cidraw, DealState _choice) internal {
        require(_choice == DealState.Passed || _choice == DealState.Rejected);
        deals[_cidraw].dealState = _choice;
    }

    /// @dev Activate the deal
    /// @param _networkDealID: Deal ID generated after the deal is created on Filecoin Network 
    function activateDeal(uint64 _networkDealID) internal returns(bytes memory) {
        MarketTypes.GetDealDataCommitmentReturn memory commitmentRet = MarketAPI.getDealDataCommitment(_networkDealID);
        uint64 providerRet = MarketAPI.getDealProvider(_networkDealID);

        authorizeDealData(commitmentRet.data, providerRet, commitmentRet.size);

        // Activate the deal
        deals[commitmentRet.data].dealState = DealState.Active;
        deals[commitmentRet.data].dealStartBlockStamp = block.timestamp;

        return commitmentRet.data;
    }

     /// @dev Checks if the provider is already storing the CID
    /// @param _cidraw: cid of the proposal
    /// @param _provider: provider credential
    function policyOK(bytes memory _cidraw, uint64 _provider) internal view returns (bool) {
        bool alreadyStoring = cidProviders[_cidraw][_provider];
        return !alreadyStoring;
    }

    /// @dev Checks if the Deal is valid 
    /// @param _cidraw: cid of the proposal
    /// @param _provider: provider credential
    /// @param _size: size of the cred
    function authorizeDealData(bytes memory _cidraw, uint64 _provider, uint _size) internal {
        // Check if the deal proposal was passsed
        require(deals[_cidraw].dealState == DealState.Passed);
        // Check if the deal dataset size match
        require(deals[_cidraw].size == _size, "data size must match expected");
        require(policyOK(_cidraw, _provider), "deal failed policy check: has provider already claimed this cid?");
        cidProviders[_cidraw][_provider] = true;
    }

    /// @dev Returns current state of the deal
    /// @param _cidraw: Id of the cred.
    function getDealState(bytes memory _cidraw) public view returns (DealState) {

        if(deals[_cidraw].dealState == DealState.Active && (block.timestamp.sub(deals[_cidraw].dealStartBlockStamp)).div(1 days) >= deals[_cidraw].dealDurationInDays) {
            return DealState.Expired;
        } else {
            return deals[_cidraw].dealState;
        }
    }
}