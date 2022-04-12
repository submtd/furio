// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Treasury {
    // Owners
    mapping(address => bool) owners;
    uint256 public ownerCount = 1;

    // What percent of owners need to approve an action?
    uint256 public votePercent = 75;

    // Actions mapping
    mapping(bytes32 => address[]) public actions;

    // Events
    event VotePassed(bytes32 hash_);
    event OwnerAdded(address owner_);
    event OwnerRemoved(address owner_);
    event Transfer(address token_, address to_, uint256 amount_);
    event VotePercentUpdated(uint256 percent_);

    // Constructor
    constructor()
    {
        owners[msg.sender] = true;
    }

    /**
     * Is an owner?
     * @param address_ Address to check.
     * @return bool
     */
    function isOwner(address address_) public view returns (bool)
    {
        return owners[address_];
    }

    /**
     * Add owner.
     * @param owner_ Address of new owner.
     */
    function addOwner(address owner_) external onlyOwner
    {
        require(!isOwner(owner_), "Owner already exists");
        bytes32 hash = keccak256(abi.encode("addOwner", owner_));
        _vote(hash);
        if(!_passes(hash)) return;
        owners[owner_] = true;
        ownerCount ++;
        emit OwnerAdded(owner_);
    }

    /**
     * Remove owner.
     * @param owner_ Address of owner to remove.
     */
    function removeOwner(address owner_) external onlyOwner
    {
        require(isOwner(owner_), "Address is not owner");
        bytes32 hash = keccak256(abi.encode("removeOwner", owner_));
        _vote(hash);
        if(!_passes(hash)) return;
        owners[owner_] = false;
        ownerCount --;
        emit OwnerRemoved(owner_);
    }

    /**
     * Transfer.
     * @param token_ Token address.
     * @param to_ Recipient address.
     * @param amount_ Amount to send.
     */
    function transfer(address token_, address to_, uint256 amount_) external onlyOwner
    {
        IERC20 _token_ = IERC20(token_);
        require(_token_.balanceOf(address(this)) >= amount_, "Insufficient funds");
        bytes32 hash = keccak256(abi.encode("transfer", token_, to_, amount_));
        _vote(hash);
        if(!_passes(hash)) return;
        _token_.transfer(to_, amount_);
        emit Transfer(token_, to_, amount_);
    }

    /**
     * Set vote percent.
     * @param percent_ New vote percent.
     */
    function setVotePercent(uint256 percent_) external onlyOwner
    {
        bytes32 hash = keccak256(abi.encode("setVotePercent", percent_));
        _vote(hash);
        if(!_passes(hash)) return;
        votePercent = percent_;
        emit VotePercentUpdated(percent_);
    }

    /**
     * Add vote
     * @param hash_ Action hash.
     */
    function _vote(bytes32 hash_) internal
    {
        bool voted = false;
        for(uint256 i = 0; i < actions[hash_].length; i ++) {
            if(msg.sender == actions[hash_][i]) {
                voted = true;
            }
        }
        require(!voted, "Already voted");
        actions[hash_].push(msg.sender);
    }

    /**
     * Passes vote?
     * @param hash_ Action hash.
     * @return bool
     */
    function _passes(bytes32 hash_) internal returns (bool)
    {
        bool _passes_ = actions[hash_].length / ownerCount * 100 >= votePercent;
        if(_passes_) delete actions[hash_];
        emit VotePassed(hash_);
        return _passes_;
    }

    // Owner modifier
    modifier onlyOwner()
    {
        require(isOwner(msg.sender), "Unauthorized");
        _;
    }
}
