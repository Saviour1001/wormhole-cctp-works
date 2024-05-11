import { HelloUSDC__factory } from "./ethers-contracts";
import {
  getWallet,
  storeDeployedAddresses,
  getChain,
  loadDeployedAddresses,
} from "./utils";

export async function deploy() {
  const deployed = loadDeployedAddresses();
  // CCTP enabled chains are ethereum, avalanche, arbitrum, optimism, base
  for (const chainId of [10003, 10004]) {
    const chain = getChain(chainId);
    const signer = getWallet(chainId);

    try {
      const helloUSDC = await new HelloUSDC__factory(signer).deploy(
        chain.wormholeRelayer,
        chain.wormhole,
        chain.cctpMessageTransmitter,
        chain.cctpTokenMessenger,
        chain.USDC,
        {
          gasLimit: 2_000_000,
        }
      );
      await helloUSDC.deployed();

      deployed.helloUSDC[chainId] = helloUSDC.address;
      console.log(
        `HelloUSDC deployed to ${helloUSDC.address} on chain ${chainId}`
      );
    } catch (e) {
      console.log(`Unable to deploy HelloUSDC on chain ${chainId}: ${e}`);
    }
  }

  storeDeployedAddresses(deployed);
}
