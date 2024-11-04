# ETHCoinMiningPoolV1

ETHCoinMiningPoolV1 is an implementation of a shared ETHC mining pool.

Major Features:

1. low additional gas cost on top of mining gas cost2
2. fully decentralized reward token custody
3. shared rewards based on individual contribution to win a block
4. supports `mine` and `futureMine` functionality

## Why use a mining pool

Life is busy and we can all earn a little more and a little better if we do it together.

Mining is a probability and numbers game: expected profit = (reward * probability of success) - cost

But mining ETHC is all or nothing. By pooling together we can improve the math so that our gains are proportional to our contribution of power provided by the pool.
If enough of us are doing it, then we can improve the chances that

## How does it actually work?

ETHC Mining Pool Shares are minted when you contribute power via the pool.
All ETHC that is mined (where our pool is the selected miner) is stored in the secure TokenVault.
At any time you can cash out your proportion of the ETHC via the redeem function - which burns your shares and transfers you ETHC from the vault.

You earn shares proportional to the reward for the block you are mining * your share of the probability that our pool is selected.

So, for example, if no one was mining, no one else was in the pool, and you added one power, you would win the block for the pool and you would receive 98% of the reward (see the point below on the operator fee of 2%).

Any shares you mine today will grant you shares that can be immediately cashed out for existing pool rewards - but that decreases your ability to earn from new selected blocks.

## Is this better than mining individually

The mining pool has the same fundamental value proposition as ETHC. If it is profitable to mine ETHC, it is likely the case that mining through the pool will ALSO be profitable.

The mining pool offers a more reliable payout once it gains adoption (it is not all or nothing, it is proportional to your share of the pool).
The mining pool offers you the ability to earn a little more (and make more for the pool) by offering graeter shares if you add power in underpowered blocks.
The mining pool offers incentives if you want to benefit from mining but you can only do it periodically. In an ideal world the mining pool will almost always have exposure to the blocks and should actually win the majority of blocks.

## Is this a charity service?

It is not in fact a charity. 2% of all shares minted are transferred to the operator address. In the short term this will pay for development fees + hosting fees.
In the long term a portion of this fee may be used for mining bonuses, etc.

# Developer Stuff

This project uses forge.

See the makefile or documentation below for how to format, build, test, and deploy this project using forge tools.  

## Usage

### Build

```shell
$ make build
```

### Test

```shell
$ make test
```

### Format

```shell
$ make fmt
```

### Gas Snapshots

```shell
$ make snapshot
```

### Deploy

```shell
$ forge script script/Deploy.s.sol:DeployETHCMiningPool --rpc-url <your_rpc_url> --private-key <your_private_key>
```
