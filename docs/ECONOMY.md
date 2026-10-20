# Living economy rules, accounting and persistence

This is a fictional compressed game economy, not a model of actual Nigerian asset
prices. Initial cash is exactly ₦25,000. Each new game receives a saved random seed;
the same seed and actions replay the same daily economic state. There is no network
or closed-app income. Menus pause the clock; one day lasts eight active minutes.

## Accounting and transactions

Money uses signed 64-bit integers in whole naira. Non-debt balances are nonnegative.
Per-counter capacity is ₦9,000,000,000,000,000, below JSON's exact integer boundary.
Displayed net worth saturates at that capacity. Tests exercise ₦10 trillion and
larger transfers and persistence. Percentage operations split quotient/remainder
before multiplying to prevent overflow. Basis-point rates round down, except debt
interest rounds upward and exchange fees use an upward-offset/minimum-one rule.
Lifetime counters saturate; purchases/transfers exceeding capacity roll back.

Net worth includes cash + bank − debt, wholesale cargo, quoted shares and asset
liquidation values. Vehicles liquidate at 70% of price scaled by condition.
Properties liquidate at 80% of cycle-adjusted price plus furnishing value.
Businesses liquidate at base price × (0.70 + 0.35 per upgrade). Buying/upgrading
and immediately selling loses money. Cash income and spending are logged separately.

All financial mutations commit through EconomyManager. A commit snapshots, validates,
writes/flushes a temporary file, preserves a validated backup, atomically renames,
then announces success. Failure restores the old state. Transaction serials are
saved. Mission IDs must exceed the last claimed reward; cargo and active mission
are consumed in the same commit as payout. Owned assets must exist before resale.
No collectible daily-income button exists: daily settlement advances the calendar,
charges costs and records income together. Repeating a market tick on the same day
is ignored. Resting advances actual game days and their obligations.

## Scheduled market simulation

EconomicSimulationManager updates once per day. `data/sectors.json` configures six
sectors' sensitivities. A 120-day sine cycle, phase-shifted by seed, drives expansion,
recession and recovery. Spending is bounded around 75–125%, with small seeded noise.
A bounded inflation index and a separate fuel cycle change expenses. Every ninth
day may begin a three-day rainfall, shortage, festival or infrastructure event.
These raise transport costs, constrain supply, raise spending or reduce fuel cost.
There are cooldowns, bounded severity and explanatory news. No hidden catastrophe.

Property values follow consumer spending and the business cycle (70–140% bounds).
Three named rivals use distinct quality/undercut/patient rules. Their sector pressure,
wealth and debt change daily; an undercutting logistics rival responds to ownership
of the player's delivery company. Rival pressure reduces business demand. They are
lightweight competitive agents, not fully simulated corporations or dialogue AI.

Stocks are fictional Palm Foods, Lagoon Energy and Kora Mobility. Fundamental
values follow spending; energy also follows fuel. Returns combine bounded mean
reversion, sector pressure and seeded volatility (6%, 10%, 14%). Prices are clamped
to ₦25–₦10m per share. Orders charge about 1%, falling toward 0.8% with investing
skill. No short selling or fractional shares. Same-day round trips lose fees.

## Businesses and lifestyle

Seven registry-driven categories: retail, logistics, restaurants, dealership,
rental agency, hotel and holding company. Levels 1–12 increase capacity linearly
by 60% of base per level. Revenue reflects capacity, spending sensitivity, rival
competition and supply. Expenses reflect capacity, inflation, sector fuel
sensitivity and management efficiency. Salaries are 45% of the displayed operating
cost, already included rather than double charged. Maintenance adds 15% of costs
every nineteenth day. Recessions can cause losses; upgrades cannot remove all risk.

Base mini-mart gross/cost is ₦12,000/₦8,500; delivery company ₦28,000/₦20,000.
Upgrade price scales linearly and entrepreneurship offers a bounded discount.
No exponential level multiplier remains. Weekly bank yield is 0.5% on at most
₦100m, paid into cash. High balances do not produce unbounded interest growth.

Room rent follows inflation from ₦1,200 until duplex/mansion ownership. Owned
properties incur daily maintenance of 0.05% of purchase price, reduced modestly by
property skill. The duplex and portfolio-only offices generate cycle-adjusted rent.
Mansions and vehicles impose costs without requiring luxury purchases for success.

## Credit and recovery

Debt interest is 2% daily, rounded upward, after bills. Unaffordable required bills
become debt rather than negative cash. Credit starts near ₦100,000; trust increases
access and defaults reduce it. Loans have a seven-day review date; repayments move
that date, while missed reviews damage trust. The player chooses repayment amounts.

Community grant: ₦5,000 below ₦5,000 liquid funds, once per seven days. Walking jobs
always remain available. Insolvency requires negative net worth, debt ≥₦25,000 and
30 days since prior use. The explicit confirmation surrenders vehicles, businesses,
shares, properties and bank funds, clears debt, restores the rented room and ₦5,000,
and damages credit reputation. It cannot be repeatedly claimed for profit.

## Contracts, skills and city memory

Six authored jobs preserve the introduction. Four additional seeded offers vary
with day, history, skill, trust, ownership and weather. They include passenger work,
three-crate business supply and a trusted express choice with a shorter deadline.
Pickup and delivery require physical locations; passengers require a car, supply
requires owned business plus bought cargo. Recent targets are excluded from the
procedural target list. Failures/cancellations reduce trust. Four completed jobs
unlock express work; trust affects financing. News, contacts and stats expose state.

Driving boosts generated passenger payouts; negotiation improves trade margins and
contracts; management lowers costs; investing lowers fees; entrepreneurship reduces
upgrade costs; property skill reduces upkeep. All effects are bounded. Networking
experience is recorded; its separate perk tree is deferred. Trust and goodwill are
compact bounded memory values, not an unlimited event log.

Milestones extend through ₦10 trillion. Rewards are 1% capped at ₦1m and claimed
once. Wealth is not sufficient to claim a fully authored corporate endgame: legacy,
acquisition negotiations, fleets and chains remain deferred.

## Save boundaries and evidence

Version two migrates original version-one saves without resetting assets or cash.
JSON financial quantities are restored to integer types. Primary corruption falls
back to the validated backup; abandoned temporary files do not replace primary.
Economic transactions save immediately; position/fuel/deadline checkpoints remain
20 seconds. Abrupt process kills may lose movement since the latest checkpoint.
Loaded active vehicles spawn at the dealership; exact parking transforms are not
saved. No server anti-cheat or protection against manual whole-save rewinds.

Automated tests cover 12,000 portfolio days over four seeds plus 3,000 unemployed
debt-stress days, deterministic replay, profit and
loss periods, financial invariants, migration, interrupted temporary files, failed
writes and duplicate actions. Real Android storage/process-kill tests and player
pacing studies remain outstanding.
