import { ethers, network } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import hre from "hardhat";

async function main() {
  const USDT = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const USDTHolder = "0x748dE14197922c4Ae258c7939C7739f3ff1db573";
  const [owner, holder1, holder2, holder3] = await ethers.getSigners();
  const Token = await ethers.getContractFactory("CVIII");
  const token = await Token.deploy("web3Bridge", "VIII");
  await token.deployed();

  const tokenaddress = token.address;

  console.log(`Reward Token deployed to ${tokenaddress}`);

  ///deploy Staking contract

  const Staking = await ethers.getContractFactory("StakERC20");
  const staking = await Staking.deploy(tokenaddress);
  await staking.deployed();
  console.log(`Staking contract deployed to ${staking.address}`);

  /// connect usdt
  const usdt = await ethers.getContractAt("IUSDT", USDT);

  const usdtAdress = usdt.address;
  console.log(`staking Token deployed to ${usdtAdress}`);

  const balance = await usdt.balanceOf(USDTHolder);
  console.log(`balnce is ${balance}`);

  const helpers = require("@nomicfoundation/hardhat-network-helpers");

  const address = USDTHolder;
  await helpers.impersonateAccount(address);
  const impersonatedSigner = await ethers.getSigner(address);

  const tokenSet = await staking.setStakeToken(usdtAdress);
  //   console.log(await tokenSet.wait());
  console.log(`staked Token  ${await staking.stakeToken()}`);

  await usdt.connect(impersonatedSigner).approve(staking.address, 5000000);

  const allowance = await usdt.allowance(USDTHolder, staking.address);
  console.log(`allowance ${allowance.wait()}`);

  const staker1 = await staking.connect(impersonatedSigner).stake(50);
  const userInfo1 = await staking.userInfo(impersonatedSigner.address);
  console.log(`holder1 infornation ${userInfo1}`);

  await ethers.provider.send("evm_mine", [1676505599]);

  await staking.connect(impersonatedSigner).updateReward();

  const userInfo = await staking.userInfo(impersonatedSigner.address);
  console.log(`holder1 infornation ${userInfo}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});