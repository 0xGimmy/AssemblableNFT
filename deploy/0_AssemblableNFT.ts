import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deploy, read } = hre.deployments;
    const { deployer, payee1, payee2 } = await hre.getNamedAccounts();

    const initSettings = {
        name: "AssemblyCat",
        symbol: "AsC",
        payees: [payee1, payee2],
        shares: [1, 3],
        itemsURI: "ipfs://DirectoryOfAllComponents/{id}.json",
        baseURI: "ipfs://DirectoryOfAllAssembly/",
        maxSupply: 10000,
        tokenPrice: hre.ethers.utils.parseEther("0.02"),
        featureSpace: "0x0A0A0A0A", // features: 10 10 10 10
    };

    // the following will only deploy "GenericMetaTxProcessor" if the contract was never deployed or if the code changed since last deployment
    const assemblableNFT = await deploy("AssemblableNFT", {
        from: deployer,
        args: [initSettings],
        // gasPrice: 100000000000,
    });

    if (assemblableNFT.receipt?.status) {
        console.log("AssemblableNFT deployed to:", assemblableNFT.address);
        console.log("ComponentNFT deployed to:", await read("AssemblableNFT", "componentContract"));
    }
    else {
        console.log("Deploy Error!");
    }
};
export default func;
func.tags = ['AssemblableNFT'];