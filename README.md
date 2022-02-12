# PlaylistNFT
Remix hack for ETHDenver feat. "The Drop" (Rocky Mountains PBS)
_______________________________________________________________

This project aims at creating token-curated dynamic playlists in the form of NFTs.

_______________________________________________________________


SongNFTfactory.sol _ ERC721 contract for artists to mint their own song-NFTs (owned by "The Drop")

TheDropERC20.sol _ fungible token for "The Drop" audience. Token holders can up-vote songNFTs in the PlaylistToken.sol contract (owned by "The Drop")

PlaylistToken.sol (unfinished) _ another ERC721 factory for minting Playlist NFTs (owned by "The Drop")
Playlist NFTs are like "empty" containers that the owner can populate with Song structs from songNFTs (we shall limit it to our own songNFTfactory.sol contract). TheDropERC20 token holders can then upvote songs in each playlist NFT by means of a Leaderboard system.
