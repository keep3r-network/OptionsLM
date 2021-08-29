# History

Liquidity Mining / Rewards / Incentives, whatever you want to call them, are innately part of crypto. Even proof of work (mining) is providing something for rewards (in proof of work, providing security [or rather electricity] for crypto)
The first (to my knowledge) to provide rewards for liquidity was synthetix.io, this started with the sETH/ETH pool, which eventually moved to the sUSD curve.fi pool. If you provided liquidity to these pools, you were rewarded with SNX (the native Synthetix token).
The somewhat legendary StakingRewards contract, was originally developed in partnership with Anton from 1inch.exchange. This contract became the base for what is liquidity mining as we know it today.

# Problem Statement

As liquidity mining grew, some, non deal-breaking, flaws became apparent. I believe the following two to be the most destressing;

* Liquidity locusts (or loyalty), also referred to as “stickiness”
* Token loyalty, or opportunistic dumping

Liquidity quickly disappears when incentives cease, and aggressive liquidity programs can often have a detriment on the token price, which, while I believe the latter to not necessarily be a bad thing (since it entirely depends on the tokenomics / purpose), from public perception, it is clear, when price goes down, a project is a scam.

# Problem Example

I believe, at its core, the problem is the “something for nothing” problem. If you receive something for nothing, you will simply bank your profits. Let’s take curve.fi as a practical example, if you provide liquidity in the form of DAI/USDC/USDT to the 3pool, you receive CRV rewards. For the sake of this example, lets assume the liquidity provider is a liquidity locust, so they are only interested in receiving CRV and immediately selling it for more DAI/USDC/USDT.

The reason for this, is that they received “something” for practically “nothing”. Provide liquidity, get rewarded, that simple.

# Quick Intro to Options

Going to try to keep this simple, there are two options, a PUT (the right to sell), and a CALL (the right to buy). In this case, you can think of a PUT as a market sell, and a CALL as a market buy. So continuing with using CRV, for purpose of simplicity, lets say CRV is trading at $2. A CALL option with a strike priceof $2, would allow me to buy CRV at $2, a PUT option with a strike priceof $2, would allow me to sell CRV at $2.

For the rest of this article, we will only focus on CALL, the right to buy. So an option has 3 basic properties;

* What are you buying? (In our example CRV)
* What is the strike price? (aka, how much are you paying for it? In our example $2 ~ or 2 DAI)
* When is the expiry? (normally some future date, in our example, expiry was current timestamp/now)

# Liquidity Mining as Options

Keeping with our curve.fi example, if you provide liquidity and you claim CRV as rewards, this can be seen as exercising a CRV CALL option with strike price $0, and expiry now. When you start thinking about it in terms of CALL options, all of a sudden it gives the project a lot more power, per example, now a project could offer it as;

* strike price = spot - 50%
* expiry = current date + 1 month

At its most basic level, we could simply say, expiry = now and strike price = spot - 50%, what would this mean? Let’s say the liquidity miner, mined 1000 CRV, instead of simply receiving the CRV CALL option at strike price $0 and expiry now (1000 tokens for free), now instead they would receive the right to purchase 1000 CRV at $1000. Even if they are a liquidity locust, they would still be incentivized to do this, since they still make $1000 profit (trading value 1000 CRV @ $2 =$2000 - $1000 purchase).

The “profits” ($1000 in above example), can now be distributed to veCRV holders, or go to the foundation, treasury DAO, etc. These funds could even be used to market make and provide additional liquidity.

Now, lets take it one step further, and add a future expiry, lets say 1 month, now for argument sake, everyone that was receiving liquidity was claiming and dumping, so 1 month alter the price is $1, but the CALL option price was also $1, so at this point, there is no reason for the “dumper” to claim the option anymore, since they wouldn’t make additional profit. So this further means that it set an additional price floor for the received tokens. As these tokens will simply not be claimed (can even be sent back to the DAO)

# Conclusion

Making a few simple modifications to the existing StakingRewards contract allows us to add the above functionality, while keeping the same UX and user experience.

Prototype code available here

By switching to Options Liquidity Mining instead of traditional Liquidity Mining it means;

* Decreased liquidity locusts
* Decrease selling pressure
* Natural price floor (twap - discount % over epoch)
* Additional fee revenue for DAO/token holders
