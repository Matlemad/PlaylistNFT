// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./SongNFTfactory.sol"; 

contract TestSort {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;


    struct Board{
        string name;
        Participant[] allPart;
        mapping(uint => Participant) partById;
    }

    struct Participant {
        uint id;
        uint score;
    }

    mapping(uint => Board) public allBoards;

    function addBoard(string memory _name) external {
        uint256 tokenId = _tokenIdCounter.current();
        allBoards[tokenId].name = _name;
    }

    function addParticipant(uint _boardID, uint _partId, uint _score) external {
        Board storage board = allBoards[_boardID];

        Participant memory participant;
        participant.id = _partId;
        participant.score = _score;
        board.allPart.push(participant);
        board.partById[_partId] = participant;
    }

// sorting is done when upvoting

    function voteParticipant(uint _boardID, uint _partID) external returns(bool) {
        Board storage board = allBoards[_boardID];
        Participant storage part = board.partById[_partID];
        part.score++;
        Participant[] storage arr = board.allPart;
        uint l = arr.length - 1;

        // if the score is too low, don't update
        if (arr[l].score >= part.score) return false;

        for (uint256 i = 0; i < l; i++) {
            // find where to insert the new score
            if (arr[i].score < part.score) {
                // shift leaderboard
                Participant memory currentPart = arr[i];
                for (uint256 j = i + 1; j < l + 1; j++) {
                    Participant memory nextPart = arr[j];
                    arr[j] = currentPart;
                    currentPart = nextPart;
                }
                // insert
                arr[i] = part;
                // delete last from list
                delete arr[l];
            }

        }

        return true;

    }

    function viewParticipant(uint _boardID, uint _participantID) external view returns(Participant memory) {
        Board storage board = allBoards[_boardID];
        Participant storage part = board.partById[_participantID];
        return part;

    }

    function showLeaderboard(uint _boardID) external view returns(Participant[] memory) {
        Board storage board = allBoards[_boardID];
        return board.allPart;       
        
        
        

       

    }


}
