import { ethers } from 'ethers';
import { MineableToken__factory } from './typechain'; // Assuming you're using TypeChain for type safety

class Miner {
    private contract: ethers.Contract;
    private wallet: ethers.Wallet;

    constructor(contractAddress: string, privateKey: string, provider: ethers.providers.Provider) {
        this.wallet = new ethers.Wallet(privateKey, provider);
        this.contract = MineableToken__factory.connect(contractAddress, this.wallet);
    }

    async mine() {
        const difficulty = await this.contract.getCurrentDifficulty();
        const blockNumber = await this.wallet.provider.getBlockNumber();
        let nonce = 0;

        while (true) {
            const hash = ethers.utils.keccak256(
                ethers.utils.solidityPack(
                    ['uint256', 'address', 'uint256'],
                    [blockNumber, this.wallet.address, nonce]
                )
            );

            if (ethers.BigNumber.from(hash).lt(ethers.constants.MaxUint256.div(difficulty))) {
                console.log(`Valid solution found! Nonce: ${nonce}`);
                try {
                    const tx = await this.contract.submitSolution(nonce);
                    await tx.wait();
                    console.log(`Solution submitted in transaction: ${tx.hash}`);
                    break;
                } catch (error) {
                    console.error('Error submitting solution:', error);
                }
            }

            nonce++;
            if (nonce % 1000 === 0) {
                console.log(`Tried ${nonce} nonces...`);
            }
        }
    }
}

// Usage
const CONTRACT_ADDRESS = '0x...'; // Your deployed contract address
const PRIVATE_KEY = '0x...'; // Your Ethereum private key
const provider = new ethers.providers.JsonRpcProvider('https://rpc-hero-network-y7kvalrvw2.t.conduit.xyz');

const miner = new Miner(CONTRACT_ADDRESS, PRIVATE_KEY, provider);
miner.mine();