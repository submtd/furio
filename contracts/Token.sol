// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// INTERFACES
import "./IAddressBook.sol";

contract Token is AccessControl, ERC20 {
    /**
     * Token metadata.
     */
    string private _name = 'Furio Token';
    string private _symbol = '$FUR';

    /**
     * Address book contract.
     */
    IAddressBook public addressBook;

    /**
     * Roles.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * Stats.
     */
    struct Stats {
        uint256 transactions;
        uint256 minted;
    }
    mapping(address => Stats) private stats;
    uint256 public players;
    uint256 public totalTransactions;

    /**
     * Minting.
     */
    bool public mintingFinished = false;
    uint256 public targetSupply = 2**256 - 1;
    uint256 public mintedSupply;
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    /**
     * Taxes.
     */
    uint256 public taxRate = 10; // 10% tax on transfers
    event TaxPayed(address from, address vault, uint256 amount);

    /**
     * Contract constructor.
     */
    constructor(address addressBook_) ERC20(_name, _symbol) {
        addressBook = IAddressBook(addressBook_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * -------------------------------------------------------------------------
     * USER FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * Transfer tokens from one account to another
     */
    function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool) {
        uint256 taxes = amount_ * taxRate / 100;
        uint256 adjustedAmount = amount_ - taxes;
        require(super.transferFrom(from_, address(this), taxes), 'Unable to pay taxes');
        emit TaxPayed(from_, address(this), taxes);
        require(super.transferFrom(from_, to_, adjustedAmount), 'Unable to transfer');
        updateStats(from_);
        updateStats(to_);
        totalTransactions ++;
        return true;
    }

    /**
     * Transfer.
     */
    function transfer(address to_, uint256 amount_) public override returns (bool) {
        return transferFrom(msg.sender, to_, amount_);
    }

    /**
     * Return player stats.
     */
    function statsOf(address player_) public view returns (uint256, uint256, uint256) {
        return (balanceOf(player_), stats[player_].transactions, stats[player_].minted);
    }

    /**
     * -------------------------------------------------------------------------
     * PROTECTED FUNCTIONS
     * -------------------------------------------------------------------------
     */
    function mint(address to_, uint256 amount_) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");
        require(!mintingFinished, "Minting is finished");
        require(amount_ > 0 && mintedSupply + amount_ <= targetSupply, "Incorrect amount");
        super._mint(to_, amount_);
        emit Mint(to_, amount_);
        mintedSupply += amount_;
        if(mintedSupply == targetSupply) {
            mintingFinished = true;
            emit MintFinished();
        }
        updateStats(to_);
        stats[to_].minted += amount_;
        totalTransactions ++;
    }

    /**
     * -------------------------------------------------------------------------
     * INTERNAL FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * Update stats.
     */
    function updateStats(address player_) internal {
        if(stats[player_].transactions == 0) {
            players ++;
        }
        stats[player_].transactions ++;
    }
}