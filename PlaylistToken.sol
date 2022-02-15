// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./SongNFTfactory.sol"; 
import "./TheDropERC20.sol";

/** PlaylistToken is a erc721 factory that creates "playlist" NFTs, empty container-items
that keep track of a Leaderboard of songNFTs, voted by a erc20 community.

*/

contract PlaylistToken is ERC721, ERC721Burnable, ERC721URIStorage, Ownable { //the playlist can be transferred, sold
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    // ERC20 repTokenAddress; // the erc20 token we shall consider for voting

    struct Playlist { // we need a Playlist struct for new playlists
        string name;
        uint256 playlistID;
        string playlistMetadata;
        address payable treasury;
        Song[] songs;
        mapping(uint256 => Song) songLeaderboard;
    }

    struct Song { // every songNFT info need to be added as a struct
        address payable creator;
        address tokenAddr;
        uint256 tokenId;
        uint256 score;
    }

    mapping (uint => Playlist) playlists;

    modifier hasRepToken {
        // require(repTokenAddress.balanceOf(msg.sender) >= 1*10**18, "you need 1 Reputation Token at least");
        require(false);
        _;
    }
    
    constructor(address _repToken) ERC721("PlayListToken", "PlayList") {
        // repTokenAddress = ERC20(_repToken);        
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
        playlist.songs.push(newsong);
    }

/*
    function upvoteSong (uint256 _playlistID, uint256 _songId) external hasRepToken returns(bool) {
        Playlist memory playlist = allPlaylists[_playlistID];
        Song memory currentSong = allsongs[_songId];
        currentSong.score++;
        repTokenAddress._burn(msg.sender, 10*10**17); // upvoting requests msg.sender to burn 0.1 repToken. Alternatively can transfer these erc20 to the Playlist treasury

        //if the score is too low, do not update
        if(playlist.songLeaderboard[playlist.playlistSize - 1].score >= currentSong.score) return false;
        
        //loop through the playlist
        for (uint256 i = 0; i < playlist.playlistSize; i++) {
        // find where to insert the new score
            if (playlist.songLeaderboard[i].score < currentSong.score) {
            // shift leaderboard
            Song memory thisSong = playlist.songLeaderboard[i];
            for (uint256 j = i + 1; j < playlist.playlistSize + 1; j++) {
                    Song memory nextSong = playlist.songLeaderboard[j];
                    playlist.songLeaderboard[j] = thisSong;
                    thisSong = nextSong;
                }
            // insert
                playlist.songLeaderboard[i] = currentSong;
                // delete last from list
                delete playlist.songLeaderboard[playlist.playlistSize];
                return true;
            }
        }
    }
*/
}
