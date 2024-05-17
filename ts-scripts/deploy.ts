import { HelloUSDC__factory, CCTPFrame__factory } from "./ethers-contracts";
import {
  getWallet,
  storeDeployedAddresses,
  getChain,
  loadDeployedAddresses,
} from "./utils";

export async function deploy() {
  const deployed = loadDeployedAddresses();
  // CCTP enabled chains are ethereum, avalanche, arbitrum, optimism, base
  for (const chainId of [5]) {
    if (chainId === 30) {
      deployed.helloUSDC[chainId] =
        "0x94978ea58eBfe46301A5Fa9521819c7090f01f40";

      console.log(
        `HelloUSDC deployed to ${deployed.helloUSDC[chainId]} on chain ${chainId}`
      );

      continue;
    }

    const chain = getChain(chainId);
    const signer = getWallet(chainId);

    try {
      console.log(`Deploying HelloUSDC on chain ${chainId}`);
      const cctpFrame = await new CCTPFrame__factory(signer).deploy(
        chain.wormholeRelayer,
        chain.wormhole,
        chain.cctpMessageTransmitter,
        chain.cctpTokenMessenger,
        chain.USDC,
        {
          gasLimit: 2_000_000,
        }
      );
      await cctpFrame.deployed();

      deployed.helloUSDC[chainId] = cctpFrame.address;
      console.log(
        `HelloUSDC deployed to ${cctpFrame.address} on chain ${chainId}`
      );
    } catch (e) {
      console.log(`Unable to deploy HelloUSDC on chain ${chainId}: ${e}`);
    }
  }

  storeDeployedAddresses(deployed);
}
