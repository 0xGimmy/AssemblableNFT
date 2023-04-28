import { ethers, deployments } from "hardhat";
const { BigNumber } = ethers;

describe("Assemblable NFT", function () {

  it("Simple flow", async function () {
    // Accounts
    const [,,,user0, user1] = await ethers.getSigners();
    
    // Deployment
    await deployments.fixture(["AssemblableNFT"]);
    const ablyDeployments = await deployments.get("AssemblableNFT");
    const assemblableNFT = await ethers.getContractAt("AssemblableNFT", ablyDeployments.address);
    
    // Settings
    const tokenPrice = ethers.utils.parseEther("0.02");
  
    // Test start
    console.log("\nTest start\n");

    // User0 mint token0
    console.log("user0 mint token0");
    const tx0 = await assemblableNFT.connect(user0).mint({value: tokenPrice});
    await tx0.wait();
    console.log(" - tokenURI(0):", await assemblableNFT.tokenURI(0), "\n");

    // User1 mint token1
    console.log("user1 mint token1");
    const tx1 = await assemblableNFT.connect(user1).mint({value: tokenPrice});
    await tx1.wait();
    console.log(" - tokenURI(1):", await assemblableNFT.tokenURI(1), "\n");

    // User1 transfer token1 to User0
    console.log("user1 transfer token1 to user0")
    const tx3 = await assemblableNFT.connect(user1).transferFrom(user1.address, user0.address, 1);
    await tx3.wait();
    console.log(" - balance(user0):", (await assemblableNFT.balanceOf(user0.address)).toNumber(), "\n");

    // Get assembly code of token0 and chose first two components to form a component code
    const assemblyCode0 = await assemblableNFT.assemblyCodeOf(0);
    const componentCode = ethers.utils.hexZeroPad(BigNumber.from(assemblyCode0).and("0x00FF00FF").toHexString(), 4);

    // Disassemble token0 using component code
    console.log("user0 disassemble token0 with code", componentCode);
    const tx2 = await assemblableNFT.connect(user0).disassemble(0, componentCode);
    await tx2.wait();
    console.log(" - tokenURI(0):", await assemblableNFT.tokenURI(0), "\n");
    
    // Assemble token1 using components disassembled from token0
    console.log("user0 assemble token1 with code", componentCode);
    const tx4 = await assemblableNFT.connect(user0).assemble(1, componentCode);
    await tx4.wait();
    console.log(" - tokenURI(1):", await assemblableNFT.tokenURI(1), "\n");
  });
});
