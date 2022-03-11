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
    
    DropRepToken public repTokenAddress; // the erc20 token we shall consider for voting
    ERC721 songNFTAddress; // the songNFT collection we restrict the playlist to 

    struct Playlist { // we need a Playlist struct for new playlists
        string name;
        uint256 playlistID;
        string playlistMetadata;
        Song[] songs;
        mapping(address => uint256) voters; // keep track of the voters so the vote can be discarded.
        uint256 topScore;
    }

    struct Song {
        address tokenAddress;
        uint tokenId;
        uint score;
    }    

    mapping (uint => Playlist) public playlists;    

    modifier hasRepToken {
        require(repTokenAddress.balanceOf(msg.sender) >= 1*10**17, "you need 1 Reputation Token at least");
        _;
    }
    
    constructor(address _songNFTAddr) ERC721("PlayListToken", "PlayList") {
        repTokenAddress = new DropRepToken(address(this)); 
        songNFTAddress = ERC721(_songNFTAddr);       
    }

    function safeMint(address to, string memory _nameOfPLaylist, string memory _playlistMetadata) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();        
        playlists[tokenId].name = _nameOfPLaylist;
        playlists[tokenId].playlistID = tokenId;
        playlists[tokenId].playlistMetadata = _playlistMetadata;
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);        
    }

    function mint(address to, uint256 amount) public onlyOwner {
        repTokenAddress.mint(to, amount);
    }
    
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    // create a new Song struct out of a songNFT
    function addSong(uint256 _playlistID, ERC721 _NFTcontract, uint256 _tokenId) external onlyOwner {
        require(songNFTAddress == _NFTcontract, "Invalid NFT contract address"); // make sure the songNFT belongs to the collection we declared
        Playlist storage playlist = playlists[_playlistID];
        Song memory newsong;
        newsong.tokenAddress = address(_NFTcontract);
        newsong.tokenId = _tokenId;
        newsong.score = 0;
        playlist.songs.push(newsong);
    }

    function upvoteSong (uint256 _playlistID, uint256 index) external /*hasRepToken*/ {
        Playlist storage playlist = playlists[_playlistID];
        Song storage currentSong = playlist.songs[index];

        currentSong.score++;
              
        // keep track of the voter so he/she can discard the vote.
        playlist.voters[msg.sender] = index + 1; // 0 means, it's not a voter
        
        // upvoting requests msg.sender to burn 0.1 repToken. Alternatively can transfer these erc20 to the Playlist treasury
        address owner = ERC721(currentSong.tokenAddress).ownerOf(currentSong.tokenId);
        repTokenAddress.transferFrom(msg.sender, owner, 1*10**17); 

        if (currentSong.score > playlist.topScore) { // update TopScore if it is the highest
            playlist.topScore = currentSong.score;
        }
    }

    /* function discardVote (uint256 _playlistID) external {
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
        currentSong.score--;
        playlist.songScore[currentSong.tokenId] -= 1;
    } */

    function getPlaylistSongs(uint _playlistID) public view returns(Song[] memory) {
        Playlist storage playlist = playlists[_playlistID];
        return playlist.songs;
    }
}
