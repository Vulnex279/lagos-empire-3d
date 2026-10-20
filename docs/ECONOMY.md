# Economic rules and persistence

## Money and assets

Balances and quantities use integer naira and integer shares/crates. Cash and bank balances cannot become negative. Unpaid required bills are added to debt, which is explicitly supported. Maximum accepted financial counters are ₦1 trillion. Net worth is allowed to be negative because debt can exceed assets.

Net worth = cash + bank − debt + goods at wholesale cost + market value of shares + asset liquidation values. Vehicle value is 70% of purchase price scaled by condition. Property value is 80% of purchase price plus half of its recorded furnishing value. Business liquidation value is 70% of base price × 2.1^(level−1). Purchasing an asset therefore need not increase net worth.

Starting cash is ₦25,000. The sedan costs ₦45,000, SUV ₦850,000, mini-mart ₦90,000, delivery company ₦240,000 and mansion ₦2,500,000. These are compressed fictional game values, not claims about real Nigerian prices.

## Day and week

One game day is 480 seconds of active play. New games start at 08:00. Menus pause time. Home rest advances a complete day and consumes job time. No earnings are accumulated while the application is closed.

Daily events use a deterministic random generator seeded from the save seed and day. Reloading the same saved day does not reroll the market or costs.

- Rent: ₦1,200/day until mansion ownership.
- Debt interest: 2%/day, rounded upward, after required bills.
- Bank interest: 0.5% every seventh day, paid into the wallet.
- Fuel price: uniformly sampled from ₦60–₦110/unit each day.
- Demand multiplier: uniformly sampled from 0.80–1.25 each day.
- Mini-mart base gross/cost: ₦15,000/₦4,500 per day.
- Delivery-company base gross/cost: ₦36,000/₦13,000 per day.
- Business levels 1–12: gross and costs multiply by 2.1^(level−1); gross also multiplies by demand. Upgrade cost is base purchase price × 2.2^current_level.
- Each business has an 18% daily chance of an extra ₦2,000 × level scale repair bill.

The constants and registries are deliberately centralized in `catalog.gd` and the daily event block in `economy.gd` so balance changes do not require UI changes. Every day reports demand/fuel changes and any repair setbacks; the ledger records charges and income.

## Investments

All three companies are fictional. Initial prices are Palm Foods ₦800, Lagoon Energy ₦1,600, Kora Mobility ₦2,400. Their uniform daily random-return amplitudes are respectively 6%, 10%, 14%.

For each day:

`return = 0.002 + clamp((base/current − 1) × 0.03, −0.03, +0.03) + uniform(−volatility,+volatility)`

`new price = clamp(round(current × (1 + return)), 25, 10000000)`

Each purchase and sale charges a 1% fee rounded upward (minimum ₦1). No short selling or fractional shares. Buying and immediately selling loses the fees. Daily returns can be negative. This simulation provides no real investment advice.

## Jobs, trading and recovery

Jobs require pickup within six metres of Dispatch. Completion requires the correct destination within six metres, a live deadline and a vehicle for passenger work. A mission is cleared in the same save commit as its reward. Repeated completion and save/reload cannot repeat that payout. Each accepted job has a monotonically increasing identifier. The first completion adds a one-time ₦2,500 bonus; first-car quest completion adds ₦5,000.

Crates cost ₦700 at Ayo Market and sell at Suya Junction for floor(₦1,100 × demand). Capacity is 20. Goods are consumed when sold. Geographic checks are made by the gameplay coordinator, and the transaction layer checks the supplied location against the required location.

A community grant supplies ₦5,000 if liquid funds are below ₦5,000 and seven days have elapsed since the previous grant. It does not erase debt. Walking deliveries require neither fuel nor an owned vehicle. Selling assets, withdrawing savings and continuing jobs provide additional recovery routes.

## Save guarantees and boundaries

Economic operations snapshot state, mutate, validate, write and flush a temporary JSON file, retain a valid backup, then rename the temporary file into place. Failure rolls the in-memory transaction back. Success is announced after the durable write. Integer types are restored explicitly after JSON parsing. Corrupt primary saves recover from a validated backup.

Gameplay position, fuel, condition and deadlines checkpoint every 20 seconds; financial transactions save immediately. Pausing the application also attempts to save. An abrupt process kill can lose up to one checkpoint interval of movement/time. Owned-car parking transforms are not saved; loading places the selected car at Eko Motors. There is one local save slot and one recovery backup.

This is an offline save system, not cryptographic anti-tamper protection. A user who manually edits or restores entire save files can change or rewind progress. Power-loss behaviour at the exact rename boundary has not been fault-injected on Android hardware.
