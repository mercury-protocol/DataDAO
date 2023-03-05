// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {CommonTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import "./MercurySBT.sol";
import "./DataDAO.sol";
import "./DataType.sol";
import "./interfaces/IMercuryDataDAO.sol";
import "./interfaces/IDataManager.sol";
import "./interfaces/IMercuryMarketplace.sol";

contract MercuryDataDAO is
    IMercuryDataDAO,
    DataDAO,
    AccessControl,
    Initializable
{
    using SafeMath for uint256;

    address public membershipSBT;
    IERC20 public MCY;
    address public dataManager;
    address public marketplace;

    uint64[] public activeDealIds;

    mapping(bytes => uint256) public dealStorageFees;

    mapping(bytes => CommonTypes.FilActorId) public dealClient;

    string[] public activeCids;

    function initialize(
        string memory name,
        string memory symbol,
        address[] memory admins,
        IERC20 _MCY,
        address _dataManager,
        address _marketplace
    ) external initializer {
        for (uint8 i = 0; i < admins.length; ) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);

            unchecked {
                ++i;
            }
        }
        MercurySBT _membershipSBT = new MercurySBT(name, symbol, admins);
        membershipSBT = address(_membershipSBT);
        MCY = _MCY;
        dataManager = _dataManager;
        marketplace = _marketplace;
    }

    modifier onlyMember() {
        require(
            MercurySBT(membershipSBT).balanceOf(msg.sender) > 0,
            "Only DAO member can call"
        );
        _;
    }

    function addMember(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MercurySBT(membershipSBT).mint(user);
        emit MemberAdded(user);
    }

    function createDataSetDealProposal(
        bytes memory _cidraw,
        uint256 _size,
        uint256 _dealDurationInDays,
        uint256 _dealStorageFees
    ) public payable onlyMember {
        require(msg.value == _dealStorageFees, "Incorrect amount sent");
        createDealProposal(_cidraw, _size, _dealDurationInDays);
        dealStorageFees[_cidraw] = _dealStorageFees;
    }

    /// @dev Activates the deal
    /// @param _networkDealID: Deal ID generated after the deal is created on Filecoin Network
    /// @param _cid: The CID of the data uploaded to Filecoin
    function activateDataSetDealBySP(uint64 _networkDealID, string calldata _cid)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        //activateDeal(_networkDealID);
        activeDealIds.push(_networkDealID);
        activeCids.push(_cid);
    }

    /// @dev Approves or Rejects the proposal - This would enable to govern the data that is stored by the DAO
    /// @param _cidraw: Id of the cred.
    /// @param _choice: decision of the DAO on the proposal
    function approveOrRejectDataSet(bytes memory _cidraw, DealState _choice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        approveOrRejectDealProposal(_cidraw, _choice);
    }

    /// @dev Once the deal is expired the SP can withdraw the rewards
    /// @param _cidraw: Id of the cred.
    function withdrawReward(bytes memory _cidraw) public {
        require(getDealState(_cidraw) == DealState.Expired);
        reward(dealClient[_cidraw], dealStorageFees[_cidraw]);
    }

    function getActiveDealsLength() external view returns (uint256) {
        return activeDealIds.length;
    }

    function getDealDetails(uint64 _dealID)
        external
        returns (MarketTypes.GetDealDataCommitmentReturn memory)
    {
        MarketTypes.GetDealDataCommitmentReturn memory commitmentRet = MarketAPI
            .getDealDataCommitment(_dealID);
        return commitmentRet;
    }

    function memberCount() public view returns (uint256) {
        return MercurySBT(membershipSBT).membersCount();
    }

    function isMember(address user) public view returns (bool) {
        return MercurySBT(membershipSBT).isMember(user);
    }

    function createDataSellOrder(
        uint256 _price,
        uint256 _dataUnits,
        DataType.dataType calldata _dataType
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32 hash;
        IDataManager(dataManager).createOrder(
            _price,
            _dataUnits,
            _dataType,
            false,
            hash
        );
    }

    function updateSellOrder(
        bytes32 _id,
        uint256 _price,
        uint256 _dataUnits,
        DataType.dataType calldata _dataType
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IDataManager(dataManager).updateOrder(
            _id,
            _price,
            _dataUnits,
            _dataType
        );
    }

    function acceptBuyOrder(
        bytes32 _id,
        uint256 _units,
        bytes32 _dataHash
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IMarketplace(marketplace).acceptBuyOrder(_id, _units, _dataHash);
    }

    function cancelOrder(bytes32 _id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IDataManager(dataManager).cancelOrder(_id);
    }

    function setOrderActive(bytes32 _id, bool _isActive)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IDataManager(dataManager).setOrderActive(_id, _isActive);
    }

    function distributeEarningsToMembers()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 daoBalance = MCY.balanceOf(address(this));
        uint256 _memberCount = memberCount();
        uint256 payoutPerMember = daoBalance.div(_memberCount);

        for (uint256 i = 0; i < _memberCount; i++) {
            address _member = MercurySBT(membershipSBT).members(i);
            MCY.transfer(_member, payoutPerMember);
        }
    }
}
