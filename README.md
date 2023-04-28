# Assemblable NFT

This project demonstrates a basic how an assemblable NFT is implememted. Contains two contracts `AssemblableNFT.sol` and `ComponentNFT.sol`.

`AssemblableNFT.sol` is an ERC721 contract, define an main NFT to which can be attached components.

`ComponentNFT.sol` is and ERC1155 contract, define the logic of components.

Try running some of the following tasks:

```shell
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat deploy --network goerli
```
