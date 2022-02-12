// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./SongNFTfactory.sol"; 
import "./TheDropERC20.sol";

/** PlaylistToken is a erc721 factory that creates "playlist" NFTs, empty container-items
that keep track of a Leaderboard of songNFTs, voted by a erc20 community.

*/

contract PlaylistToken is ERC721, ERC721Burnable, ERC721URIStorage, Ownable { //the playlist can be transferred, sold
    
    
    ERC20 repTokenAddress; // the erc20 token we shall consider for voting

    struct Playlist { // we need a Playlist struct for new playlists
        uint256 playlistID;
        string playlistMetadata;
        uint playlistSize;
        address payable treasury;
        mapping(uint256 => Song) songLeaderboard;
    }

    Playlist[] public allPlaylists;


    struct Song { // every songNFT info need to be added as a struct
        address payable creator;
        address tokenAddr;
        uint256 tokenId;
        uint256 score;
    }

    Song[] public allsongs;

    modifier hasRepToken {
        require(repTokenAddress.balanceOf(msg.sender) >= 1*10**18, "you need 1 Reputation Token at least");
        _;
    }
    
    constructor(address _repToken, string memory _nameOfPLaylist, string memory _playlistMetadata, string memory _ticker, address payable _treasury, uint _playlistSize ) ERC721(_nameOfPLaylist, _ticker) {
        Playlist storage playlist;
        repTokenAddress = ERC20(_repToken);
        playlist.playlistID ++;
        playlist.playlistMetadata = _playlistMetadata;
        playlist.treasury = _treasury;
        playlist.playlistSize = _playlistSize;
        _safeMint(msg.sender, playlist.playlistID);
        _setTokenURI(playlist.playlistID, _playlistMetadata);
        allPlaylists.push(playlist);
    }

    // Owner can burn the Playlist NFT
    function _burnPlaylist(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // Shows the playlist URI, e.g. the cover image 
    function playlistTokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // change each playlist's treasury, can turn out useful for incentives
    function changeTreasury(uint256 _playlistID, address payable _newTreasury) external onlyOwner {
        Playlist memory playlist = allPlaylists[_playlistID];
        playlist.treasury = _newTreasury;
    }
    
    // create a new Song struct out of a songNFT
    function addSong(uint256 _playlistID, address payable _creator, address _NFTcontract, uint256 _tokenId) external onlyOwner {
        Playlist memory playlist = allPlaylists[_playlistID];
        Song memory newsong;
        newsong.creator = _creator;
        newsong.tokenAddr = _NFTcontract;
        newsong.tokenId = _tokenId;
        newsong.score = 0;
        allsongs.push(newsong);
        playlist.songLeaderboard[newsong.score][newsong];

    }

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

}