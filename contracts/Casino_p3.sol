//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//NOTE: Implement Protocol #3

contract Casino {
    struct ProposedBet {
        address sideA;
        uint256 value;
        uint256 placedAt;
        bool accepted;
    } // struct ProposedBet

    struct AcceptedBet {
        address sideB;
        uint256 acceptedAt;
        uint256 commitmentB;
    } // struct AcceptedBet

    //NOTE: new struct
    struct RevealBet {
        uint256 revealAAt;
        uint256 revealBAt;
        uint256 randomA;
        uint256 randomB;
        bool revealedA;
        bool revealedB;
    } // struct RevealBet

    // Proposed bets, keyed by the commitment value
    mapping(uint256 => ProposedBet) public proposedBet;

    // Accepted bets, also keyed by commitment value
    mapping(uint256 => AcceptedBet) public acceptedBet;

    //NOTE: new mapping
    // Reveal bets, also keyed by commitment value
    mapping(uint256 => RevealBet) public revealBet;

    event BetProposed(uint256 indexed _commitment, uint256 value);

    event BetAccepted(uint256 indexed _commitment, address indexed _sideA);

    event BetSettled(
        uint256 indexed _commitment,
        address winner,
        address loser,
        uint256 value
    );

    // Called by sideA to start the process
    function proposeBet(uint256 _commitmentA) external payable {
        require(
            proposedBet[_commitmentA].value == 0,
            "there is already a bet on that commitment"
        );
        require(msg.value > 0, "you need to actually bet something");

        proposedBet[_commitmentA].sideA = msg.sender;
        proposedBet[_commitmentA].value = msg.value;
        proposedBet[_commitmentA].placedAt = block.timestamp;
        // accepted is false by default

        emit BetProposed(_commitmentA, msg.value);
    } // function proposeBet

    // Called by sideB to continue
    function acceptBet(uint256 _commitmentA, uint256 _commitmentB)
        external
        payable
    {
        require(
            !proposedBet[_commitmentA].accepted,
            "Bet has already been accepted"
        );
        require(
            proposedBet[_commitmentA].sideA != address(0),
            "Nobody made that bet"
        );
        require(
            msg.value == proposedBet[_commitmentA].value,
            "Need to bet the same amount as sideA"
        );

        acceptedBet[_commitmentA].sideB = msg.sender;
        acceptedBet[_commitmentA].acceptedAt = block.timestamp;
        acceptedBet[_commitmentA].commitmentB = _commitmentB;
        proposedBet[_commitmentA].accepted = true;

        emit BetAccepted(_commitmentA, proposedBet[_commitmentA].sideA);
    } // function acceptBet

    // Called by sideA to reveal their random value and conclude the bet
    //NOTE: passing the commitment as parameter to identify the Bet
    function reveal(uint256 _commitment, uint256 _random) external {
        //NOTE: check who (A or B) is calling the function and store _random and timestamp
        if (msg.sender == proposedBet[_commitment].sideA) {
            revealBet[_commitment].revealAAt = block.timestamp;
            revealBet[_commitment].randomA = _random;
            revealBet[_commitment].revealedA = true;
        } else if (msg.sender == acceptedBet[_commitment].sideB) {
            revealBet[_commitment].revealBAt = block.timestamp;
            revealBet[_commitment].randomB = _random;
            revealBet[_commitment].revealedB = true;
        }
        //FIXME: Where is verification that hash(random)=hash ??!!
        //NOTE: ask if both parts already submitted their _random
        if (
            revealBet[_commitment].revealedA && revealBet[_commitment].revealedB
        ) {
            address payable _sideA = payable(proposedBet[_commitment].sideA);
            address payable _sideB = payable(acceptedBet[_commitment].sideB);
            //NOTE: randomA XOR randomB
            uint256 _agreedRandom = revealBet[_commitment].randomA ^
                revealBet[_commitment].randomB;
            uint256 _value = proposedBet[_commitment].value;

            require(
                proposedBet[_commitment].sideA == msg.sender ||
                    acceptedBet[_commitment].sideB == msg.sender,
                "Not a bet you placed or wrong value"
            );
            require(
                proposedBet[_commitment].accepted,
                "Bet has not been accepted yet"
            );

            // Pay and emit an event
            if (_agreedRandom % 2 == 0) {
                // sideA wins
                _sideA.transfer(2 * _value);
                emit BetSettled(_commitment, _sideA, _sideB, _value);
            } else {
                // sideB wins
                _sideB.transfer(2 * _value);
                emit BetSettled(_commitment, _sideB, _sideA, _value);
            }

            // Cleanup
            delete proposedBet[_commitment];
            delete acceptedBet[_commitment];
            delete revealBet[_commitment]; // added for Protocol #3
        }

        // uint256 commitment = uint256(keccak256(abi.encodePacked(_random)));
    } // function reveal
} // contract Casino
