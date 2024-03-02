// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "_ownable.sol";

/// @title A whitelist contract for NFT lovers
/// @author Aratta
/// @notice Read the use cases before deploying the contract
/// @dev Run test before deploying, you can find deployed contract addresses in deployed dir
contract Evervote is Ownable(msg.sender) {
    /// @notice Current count
    uint256 public count = 0;

    error TooEarly(uint256 time);

    error TooLate(uint256 time);

    /// Sender not authorized for this
    error Unauthorized();

    event PollCreated(
        address indexed sender,
        bytes32 indexed id,
        string metadata,
        uint256 expiration,
        address[] allowlist,
        address indexed manager,
        bool pause
    );

    event Log(string func, uint256 gas);

    struct pollStruct {
        bytes32 id;
        string metadata;
        string[] choice;
        uint256 expiration;
        address[] allowlist;
        address manager;
        bool pause;
    }

    pollStruct[] public poll;

    struct voteStruct {
        bytes32 pollId;
        address addr;
        uint8 choice;
    }

    voteStruct[] public vote;

    constructor() {
        /// @dev Assert that count will start from 0
        assert(count == 0);

        // address[] memory allowlist = new address[](1);
        // allowlist[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

        // string[] memory choice = new string[](3);
        // choice[0] = "Choice 1";
        // choice[0] = "Choice 2";

        // createPoll(
        //     choice,
        //     "bafybeia4khbew3r2mkflyn7nzlvfzcb3qpfeftz5ivpzfwn77ollj47gqi",
        //     1745534812,
        //     0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        //     allowlist
        // );
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager(bytes32 pollId) {
        for (uint256 i = 0; i < poll.length; i++) {
            if (poll[i].id == pollId) {
                require(poll[i].manager == msg.sender, "you are not the manager of this....");
            }
        }
        _;
    }

    /// @notice Create a new whitelist
    /// @dev If the manager field is left empty, the sender will be recognized as the manager
    /// @param metadata The IPFS CID => bafybeia4khbew3r2mkflyn7nzlvfzcb3qpfeftz5ivpzfwn77ollj47gqi
    /// @param expiration Time in timestamp format => 1745534812
    /// @return Whitelist id
    function createPoll(
        string[] memory choice,
        string memory metadata,
        uint256 expiration,
        address manager,
        address[] memory allowlist
    ) public returns (bytes32) {
        /// @notice Continue if start time is gretter that current time
        require(expiration > block.timestamp, "Start time must be greater than current time");

        /// @notice Increase counter
        ++count;

        /// @notice Add a new whitelist
        poll.push(pollStruct(bytes32(count), metadata, choice, expiration, allowlist, manager, false));

        /// @notice Emit new whitelist data
        emit PollCreated(msg.sender, bytes32(count), metadata, expiration, allowlist, manager, false);

        return bytes32(count);
    }

    //
    function getPoll(bytes32 pollId) public view returns (pollStruct memory) {
        for (uint256 i = 0; i < poll.length; i++) {
            if (poll[i].id == pollId) {
                return poll[i];
            }
        }

        revert("The whitelist that has been entered has not been declared yet");
    }

    // check if sender is the manager of the whitelist
    // returns boolean
    function updatePoll(
        bytes32 pollId,
        string memory metadata,
        bool pause
    ) public onlyManager(pollId) returns (bool) {
        for (uint256 i = 0; i < poll.length; i++) {
            if (poll[i].id == pollId) {
                poll[i].metadata = metadata;
                poll[i].pause =pause;

                // Emit that the poll updated
                return true;
            }
        }
        return false;
    }

    function pollTotal() public view returns (uint256) {
        return poll.length;
    }

    function voteTotal() public view returns (uint256) {
        return vote.length;
    }

    /// @notice Add user to a whitelist
    function castVote(bytes32 pollId, uint8 choice) public returns (bool) {
        /// @notice Revert the transaction if the whitelist ID is not valid, not open, or has expired
        for (uint256 i = 0; i < poll.length; i++) {
            if (poll[i].id == pollId) {
                if (poll[i].expiration < block.timestamp) revert TooEarly(block.timestamp);
                if (poll[i].pause) revert("This whitelist has been paused");

                /// @notice Check the sender is not exist on the whitelist
                //   for (uint256 q = 0; q < vote[i].length; q++)
                //  require(poll[i].users[q] != msg.sender, "The Sender is already on the list");

                /// @notice Add new user
                vote.push(voteStruct(pollId, msg.sender, choice));

                /// @notice Emit new user has been added
                emit Log("New user", gasleft());

                return true;
            }
        }
        return false;
    }

    /// @notice Verify if a user is on a specific whitelist
    /// @return Whitelist ID
    function verifyManager(bytes32 pollId, address _manager) public view returns (bool) {
        for (uint256 i = 0; i < poll.length; i++) {
            if (poll[i].id == pollId && poll[i].manager == _manager) {
                return true;
            }
        }
        return false;
    }
}
