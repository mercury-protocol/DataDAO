// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MercurySBT is ERC721, AccessControl {
    uint256 public tokenCount;
    address[] public members;
    mapping(address=>bool) public isMember;

    constructor(string memory name_, string memory symbol_, address[] memory admins) ERC721(name_, symbol_) {
        for (uint8 i = 0; i < admins.length;) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _transfer(address /* from */, address /* to */, uint256 /* tokenId */) internal virtual override {
        revert();
    }

    function mint(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenCount++;
        _mint(to, tokenCount);
        members.push(to);
    }

    function membersCount() public view returns (uint256) {
        return tokenCount;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
