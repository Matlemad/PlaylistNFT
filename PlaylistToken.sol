// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./SongNFTfactory.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/** PlaylistToken is a erc721 factory that creates "playlist" NFTs, empty container-items
that keep track of a Leaderboard of songNFTs, voted by a erc20 community.

*/

contract PlaylistToken is ERC721, ERC721Burnable, ERC721URIStorage, Ownable { //the playlist can be transferred, sold
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    ERC20 repTokenAddress; // the erc20 token we shall consider for voting

    struct Playlist { // we need a Playlist struct for new playlists
        string name;
        uint256 playlistID;
        string playlistMetadata;
        address payable treasury;
        uint[] songs;
        mapping(uint256 => Song) songsMetadata;
        uint[][] leaderBoard;
        mapping(address => uint256) voters; // keep track of the voters so the vote can be discarded.
        mapping (bytes => uint) songsPositionsInLeaderBoard; // keep track of the index where a song is in the leaderboard, so it can easily be removed.
    }
    
    struct Song { // every songNFT info need to be added as a struct
        address payable creator;
        address tokenAddr;
        uint256 tokenId;
        uint score;
    }

    mapping (uint => Playlist) public playlists;
    

    modifier hasRepToken {
        require(repTokenAddress.balanceOf(msg.sender) >= 1*10**18, "you need 1 Reputation Token at least");
        _;
    }
    
    constructor(address _repToken) ERC721("PlayListToken", "PlayList") {
        repTokenAddress = ERC20(_repToken);        
    }

    function safeMint(address to, string memory _nameOfPLaylist, string memory _playlistMetadata, address payable _treasury) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();        
        playlists[tokenId].name = _nameOfPLaylist;
        playlists[tokenId].playlistID = tokenId;
        playlists[tokenId].playlistMetadata = _playlistMetadata;
        playlists[tokenId].treasury = _treasury;
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);        
    }
    
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // change each playlist's treasury, can turn out useful for incentives
    function changeTreasury(uint256 _playlistID, address payable _newTreasury) external onlyOwner {
        Playlist storage playlist = playlists[_playlistID];
        playlist.treasury = _newTreasury;
    }
    
    // create a new Song struct out of a songNFT
    function addSong(uint256 _playlistID, address payable _creator, address _NFTcontract, uint256 _tokenId) external onlyOwner {
        Playlist storage playlist = playlists[_playlistID];
        Song memory newsong;
        newsong.creator = _creator;
        newsong.tokenAddr = _NFTcontract;
        newsong.tokenId = _tokenId;
        newsong.score = 0;
        playlist.songsMetadata[_tokenId] = newsong;
        playlist.songs.push(_tokenId);
    }


    function upvoteSong (uint256 _playlistID, uint256 _songId) external hasRepToken {
        // get the song.
        Playlist storage playlist = playlists[_playlistID];
        Song storage currentSong = playlist.songsMetadata[_songId];
        
        // increment the score and update the leaderboard.
        updateRankByLeaderboard(playlist, currentSong, 1);
        
        // save the index position of the song in the leaderboard in case we have to remove it afterward.
        playlist.songsPositionsInLeaderBoard[abi.encodePacked(currentSong.score, _songId)] = playlist.leaderBoard[currentSong.score].length;
        
        // keep track of the voter so he/she can discard the vote.
        playlist.voters[msg.sender] = _songId + 1; // 0 means, it's not a voter
        
        // burn the token.
        //repTokenAddress.transfer(currentSong.creator, 10*10**17); // upvoting requests msg.sender to burn 0.1 repToken. Alternatively can transfer these erc20 to the Playlist treasury
    }

    function discardVote (uint256 _playlistID) external {
        // get the playlist.
        Playlist storage playlist = playlists[_playlistID];
        
        // sender should already have voted in this leaderboard     
        require(playlist.voters[msg.sender] > 0, "sender should be a voter");
        
        // get the song the sender has voted for.
        uint songId = playlist.voters[msg.sender] - 1;

        // reinitialize msg.sender as non-voter and continue.
        playlist.voters[msg.sender] = 0;

        // get the song.   
        Song storage currentSong = playlist.songsMetadata[songId];
        
        // decrement the score and update the leaderboard.
        updateRankByLeaderboard(playlist, currentSong, -1);
    }

    function updateRankByLeaderboard(Playlist storage playlist, Song storage song, int8 direction) internal {
        // get the index in the leaderboard where the song is located.
        uint index = playlist.songsPositionsInLeaderBoard[abi.encodePacked(song.score, song.tokenId)];
        
        // remove the song from the current leaderboard position.
        uint[] storage songs = playlist.leaderBoard[song.score];
        songs[index] = songs[songs.length - 1];
        songs.pop();
        
        // update the score
        if (direction == 1) {
            song.score = song.score + 1;
        } else {
            song.score = song.score - 1;
        }        

        // push the song in the new position.
        songs = playlist.leaderBoard[song.score];
        songs.push(song.tokenId);
    }

    function viewSong(uint256 _playlistID, uint256 _songId) external view returns(Song memory) {
        Playlist storage playlist = playlists [_playlistID];
        Song storage song = playlist.songsMetadata[_songId];
        return song;
    }
}
