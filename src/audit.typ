#import "templates/report.typ": *

#show: report.with(
  client: "Sundae Labs",
  title: "V3",
  repo: "https://github.com/txpipe-shop/sundae-swap",
  date: "April 26, 2024",
)

#show link: underline

= Summary
#v(1em)
This report provides a comprehensive audit of SundaeSwap V3, a decentralized
exchange protocol that realizes an automated market maker (AMM) pooled
liquidity model on the Cardano Blockchain.

The investigation spanned several potential vulnerabilities, including
scenarios where attackers might exploit the validator to lock up or steal
funds.

The audit is conducted without warranties or guarantees of the quality or
security of the code.
It's important to note that this report only covers identified issues, and we
do not claim to have detected all potential vulnerabilities.
#v(1em)

== Overview
#v(1em)
The core component of SundaeSwap V3 is the liquidity pool.
Liquidity pools are script UTxOs that hold liquidity for two fixed assets.
Standard operations are supported, such as swapping and providing/removing liquidity, together with more advanced operations.

To address concurrency, users does not interact directly with LPs but place
orders.
Orders are script UTxOs that hold all the assets and information required for
the execution of the desired operation.
They can be directed to a specific pool, or open to any pool that is able to
process it.

Orders are processed in batches in "scoop" transactions by authorized entities
called "scoopers".
A scoop transaction applies a sequence of orders to a specific pool,
transforming the pool state and doing all the required payments to fulfill the
orders purpose.

SundaeSwap V3 protocol is booted by the creation of a single settings UTxO that
governs the entire protocol.
The settings UTxO determine, among other things, the list of authorized
scoopers.
Liquidity pools are created and validated with the minting of a pool NFT.

Orders are created with no validation, so it is up to the scoopers to select
well-formed orders to be processed.
There are several order types:
- Swap: to swap one token for another.
- Deposit: to provide liquidity and obtain LP tokens.
- Withdrawal: to redeem LP tokens and remove liquidity.
- Donation: to provide liquidity for free.
- Strategy: to lock funds for an operation that will be determined at processing time by a designated signer.
- Record: to create an output that can be used to do a snapshot of the pool state (than can be used later as an oracle).

#v(1em)

== Process
#v(1em)
Our audit process involved a thorough examination of SundaeSwap V3 validators.
Areas vulnerable to potential security threats were closely scrutinized,
including those where attackers could exploit the validator’s functions to
disrupt the platform and its users.
This included evaluating potential risks such as unauthorized asset addition,
hidden market creation, and disruptions to interoperability with other Plutus
scripts.
This also included the common vulnerabilities such as double satisfaction and
minting policy vulnerabilities.

The audit took place over a period of several weeks, and it involved the
evaluation of the platform’s mathematical model to verify that the implemented
equations matched those of the AMM algorithm.

Findings and feedback from the audit were communicated regularly to the
SundaeSwap team through Discord.
Diagrams illustrating the necessary transaction structure for proper
interaction with SundaeSwap V3 are attached as part of this report.
The SundaeSwap team addressed these issues in an eﬃcient and timely manner,
enhancing the overall security of the platform.

#pagebreak()

= Specification

== UTxOs

=== Settings UTxO

A single script UTxO that is created at launch and used for the entire protocol.
Creation is validated with the minting of the "Settings NFT" that is locked
into the UTxO.
A multivalidator is used to contain both the spend and the minting validators.

- Address: hash of multivalidator in #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/settings.ak#L12")[`settings.ak`]. Parameters:
  - `protocol_boot_utxo`: reference to a UTxO that must be spent at settings creation.
- Value:
  - ADA: only min ADA.
  - Settings NFT: minting policy defined in the multivalidator.
- Datum: #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/lib/types/settings.ak#L12")[`SettingsDatum`]

=== Pool UTxOs

One script UTxO for each liquidity pool.
All pools in the protocol share the same address.
Liquidity pool creation is validated with the minting of a "Pool NFT" that is
locked into the UTxO.
A multivalidator is used to contain both the spend and the minting validators.
Moreover, the minting validator is used both for the Pool NFT and for the LP
tokens.

- Address: hash of multivalidator in #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L49")[pool.ak].   Parameters:
  - `manage_stake_script_hash`: hash of staking script that validates pool management operations.
  - `settings_policy_id`: minting policy of the Settings NFT.
- Value:
  - ADA: accumulated protocol fees (including min ADA).
  - (A, B): pair of assets contained by the pool. A may be ADA.
  - Pool NFT: minting policy defined in the multivalidator.
- Datum: #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/lib/types/pool.ak#L7")[`PoolDatum`]

=== Order UTxOs

One script UTxO per order.
All orders in the protocol share the same address.
Order creation is not validated.
Order spending is validated to be done by the order creator or by a transaction that involves spending a liquidity pool.
The latter check is done by a staking validator that is referenced in the spend validator.
This way, the check is done only once for the transaction and not one time for each spent order, optimizing mem/CPU usage.

- Address: hash of spend validator in #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/order.ak#L28")[`order.ak`]. Parameters:
  - `stake_script_hash`: hash of staking script that validates for the presence of a valid liquidity pool.
- Value:
  - ADA: at least min ADA.
  - Other: assets relevant to the order + others.
- Datum: #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/lib/types/order.ak#L9")[`OrderDatum`]

=== Oracle UTxOs

A UTxO that can be created as the result of processing an order of type
"Record", if the correct parameters for the order are used.
Creation is validated with the minting of the "Oracle NFT" that is locked
into the UTxO, to check that the datum contains the correct information
regarding the pool state.
The UTxO can be spent by an owner defined in the order.
A multivalidator is used to contain both the spend and the minting validators.

- Address: hash of multivalidator in #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/oracle.ak#L24")[`oracle.ak`]. Parameters:
  - `pool_script_hash`: hash of pool multivalidator.
- Value:
  - ADA: at least min ADA.
  - Oracle NFT: #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/oracle.ak#L54")[minting policy] with same hash as this oracle script.
- Datum: #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/lib/types/oracle.ak#L5")[`OracleDatum`]


== Transactions
#v(1em)

=== Settings

==== Operation "create settings"

This transaction creates a settings UTxO, which is then referenced by several pool operations that need those protocol settings as part of their validation.

The UTxO contains a datum with the protocol settings, and its value has a NFT used to identify it, which is minted in this create transaction.

#figure(
  image("img/create_settings.png", width: 100%),
  caption: [
    Create Settings diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/settings.ak#L109")[settings.ak:mint()]

Expected Failure Scenarios:

- The protocol boot UTxO is not being spent
- More than one settings tokens is being minted, or any other asset

==== Operation "update settings"

This transaction colapses two updates of different nature: ones allowed to the settings administrator and others to the treasury administrator. Each one of those can update different fields of the settings datum.

The two involved redeemers are:
- `SettingsAdminUpdate` for the settings admin
- `TreasuryAdminUpdate` for the treasury admin

#figure(
  image("img/update_settings.png", width: 100%),
  caption: [
    Update Settings diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/settings.ak#L44")[settings.ak:spend():SettingsAdminUpdate]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/settings.ak#L77")[settings.ak:spend():TreasuryAdminUpdate]

Expected Failure Scenarios:

- There's a minting or burning happening in the transaction
- The settings NFT is stolen from the settings UTxO
- The settings input and output have different addresses
- If the redeemer being executed is the `SettingsAdminUpdate`: other than the following fields are updated
  - settings_admin
  - metadata_admin
  - treasury_admin
  - authorized_scoopers
  - base_fee, simple_fee, strategy_fee, pool_creation_fee
  - extensions
  else if `TreasuryAdminUpdate` is being executed, other than the following fields are updated:
  - treasury_address
  - authorized_staking_keys
  - extensions?
- The tx is not signed by the given administrator: `SettingsAdminUpdate` signed by settings admin, or `TreasuryAdminUpdate` by the treasury admin


=== Pools

==== Operation "create pool"

This transaction creates a Pool UTxO based on the settings UTxO, which provides various protocol configurations, and funds transfered from the pool creator that act as the initial liquidity. Also, a UTxO which will hold the metadata associated with the pool is created, although the actual metadata information is uploaded in a subsequent transaction that will be performed by the metadata admin.

The minted assets are:
- pool NFT: held within the pool UTxO
- pool reference NFT: used to identify the UTxO that will hold the metadata associated to the pool
- LP tokens: paid to the pool creator. These tokens represent the amount of liquidity provided by the creator

The involved redeemers are:
- `CreatePool`
- `MintLP`

#figure(
  image("img/create_pool.png", width: 100%),
  caption: [
    Create Pool diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L282")[pool.ak:mint():CreatePool]

Expected Failure Scenarios:

- Pool output has the expected address: the pool script address
- Quantities of both tokens of the pair are not a positive integer
- Pool reference NFT is not paid to the metadata output
- Pool NFT or specified quantity of both tokens of the pair are not paid to the pool script address
- Pool value does have more assets than the relevant ones: the pool NFT, protocolFees ADA, and both tokens from the pair
- Pool datum is not valid. One of:
  - Pool identifier is not correct based on the rules defined for ensuring uniqueness
  - The assets property does not match with the tokens pair provided to the pool UTxO
  - Circulating LP property does not equal the minted quantity of LP tokens
  - Fees per ten thousand property is not a positive integer
  - Protocol fees is not a positive integer
- Metadata output does not have a void datum
- The settings UTxO doesn't have a token with the expected policy ID (parameter of the validator)

==== Operation "withdraw fees"

This transaction allows the treasury administrator to take a specific amount of ADA from the UTxO pool accumulated there in protocol fees. This withdrawn amount is then paid to the treasury address minus a portion (the allowance) that this admin can pay wherever he wants.

#figure(
  image("img/withdraw_fees.png", width: 100%),
  caption: [
    Withdraw Fees diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L610")[pool.ak:manage():WithdrawFees]

Expected Failure Scenarios:

- Pool input address and Pool output address are distinct
- In Pool output Datum, any other field than the protocol fees one is updated
- The amount to withdraw specified within the redeemer does not match the amount of ADA taken from the Pool UTxO, or any of the other assets quantities of the UTxO change
- The transaction is not signed by the treasury administrator
- The treasury part (withdraw amount minus allowance) is not paid to the treasury address
- The amount to withdraw is greater than the available protocol fees in the Pool UTxO

==== Operation "update pool fees"

This transaction allows the Pool fees manager to update the bid and/or ask fee amount,
information that's stored in the Pool Datum.

#figure(
  image("img/update_fees.png", width: 100%),
  caption: [
    Update Pool Fees diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L689")[pool.ak:manage():UpdatePoolFees]

Expected Failure Scenarios:

- Pool input address and Pool output address are distinct
- Pool input value and Pool output value are distinct
- In Pool output Datum, any other field than the bid and/or ask fees is updated
- If one of bid/ask fee field is updated, it is out of the valid percentage range: less than 0% or more than 100%
- The Pool fees manager is not signing the transaction

==== Operation "close pool"

This transaction lets the treasury administrator withdraw the remaining ADA of the pool, given that it has no liquidity left. The pool NFT must be burnt.

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L461")[pool.ak:mint():BurnPool]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L610")[pool.ak:manage():WithdrawFees] by #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/e3b7ca3eebd64963c35bdfd2b5013b3a4c93bcef/validators/pool.ak#L282")[this branch].

#figure(
  image("img/close_pool.png", width: 100%),
  caption: [
    Close Pool diagram.
  ],
)

Expected Failure Scenarios:

- Pool NFT is not burned.
- Transaction is not signed by the treasury administrator.
- Pool remaining ADA are not paid to the treasury address.
- There's LP in circulation.
- Pool has other asset than the pool NFT and ADA, or has more ADA than initial protocol fees ADA.

=== Orders

==== Operation "create order"

This transaction transfers funds from the user to the Order script address, whose associated validator will then be executed to unlock them. This transaction does not require a validator execution and stores a datum that contains information about the type of Order the user made.

The assets sent are different depending on the type of Order but they all contain at least the maximum protocol fee ADA, the assets relevant to the specific type of Order plus any other assets (optional).

More precisely, the assets relevant to the specific type of Order are:

- Swap: the offered asset given in exchange for the pair's other asset.
- Deposit: both assets from the pair.
- Withdrawal: LP tokens.
- Donation: both assets from the pair.
- Strategy: none.
- Record: record NFT.

#figure(
  image("img/create_order.png", width: 100%),
  caption: [
    Create Order diagram.
  ],
)

==== Operation "cancel order"

This transaction spends an Order UTxO with a Cancel redeemer that allows the transfer of those funds wherever the order Owner wants, which must sign the transaction.

The most common use cases are recovering the funds and doing an order update by consuming the order UTxO and producing a new one.

It is worth noting that the order Owner is a multi-sig script, which allows a straightforward signature requirement as just the presence of a specific public key signature as well as a complex Cardano native/simple script-like validation.

#figure(
  image("img/cancel_order.png", width: 100%),
  caption: [
    Cancel Order diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/order.ak#L32")[order.ak:spend():Cancel]

Expected Failure Scenarios:
- Owner is *not* signing the transaction

==== Operation "scoop"

This transaction processes a batch of orders against a particular pool, performed by an authorized scooper.

For each order input there is a related destination output that will contain the assets resulting from the processing of such order (plus a remainder in some cases) and any other assets that were in the order and are not related with the pool. The only exception to this rule are Donation orders that have no reminder i.e. the liquidity ratio of the pool is preserved with the exact amounts provided in the donation.

Both the Pool and Order validators are executed. They are attached to the transaction within reference inputs.

#figure(
  image("img/scoop.png", width: 100%),
  caption: [
    Scoop diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L85")[pool.ak:spend():PoolScoop]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/order.ak#L43")[order.ak:spend():Scoop]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/stake.ak#L21")[stake.ak:stake():WithdrawFrom]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L452")[pool.ak:mint():MintLP]
- If there are oracle orders, #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/oracle.ak#L56")[oracle.ak:mint():Mint]

Expected Failure Scenarios:

- Pool output address is not equal than Pool input address
- In the pool datum, other field/s than `circulating_lp` is/are modified
- Pool NFT is stolen from the Pool UTxO or burned
- Pool pair amounts does not match the expected quantities given the specific processed orders
- Pool output has a token that wasn't in the Pool input
- Fees are not correctly paid
- For each destination output. One of:
  - Is not paid to the destination address specified in the corresponding Order input
  - The destination output doesn't have the datum specified in the corresponding Order
  - The paid value is not consistent with the action defined in the corresponding Order
- For each Order input. One of:
  - If the Order has pool identifier, it does not match with the identifier of the Pool being consumed
  - If the Order is of the Strategy type and doesn't have a defined strategy execution, or if it has a strategy execution defined, is not signed by the expected party
  - The assets contained in the Order does not contain the needed assets to perform the requested action over the Pool
- The market is not open yet i.e. the tx validation range is not contained in the interval [market open POSIX time, +∞)
- An incorrect amount of LP tokens are minted/burned if any, or the `circulating_lp` property of the Pool datum is not updated accordingly
- There's no signature of an authorized scooper
- If there's an oracle order:
  - there's a 1-to-1 correspondence with oracle script outputs
  - each oracle script output has only one oracle token
  - oracle datum has the correct validity range and recorded pool values i.e. the token A and B reserves, and circulation LP recorded in oracle datum matches with the Pool output state.

=== Oracles

==== Operation "create oracle"

Oracle creation is embedded in scoop operation by processing a previously created Record order. So, unlike the other operations described, this one is "contained" within the scoop operation.

From the scoop operation POV: for each Record order input there's an oracle script output uniquely identified by an oracle token (NFT) minted in this same transaction. The oracle datum contains a snapshot of the state of the pool output i.e. quantities of both tokens of the pair and of circulating LP.

==== Operation "close oracle"

This transaction allows to close an oracle on behalf of its owner by enforcing the burning of the oracle
token, which is a must since people will be relying on the oracle token to authenticate the actual pool values.

#figure(
  image("img/close_oracle.png", width: 50%),
  caption: [
    Close Oracle diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/oracle.ak#L31")[oracle.ak:spend()]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/oracle.ak#L119")[oracle.ak:mint():Burn]

Expected Failure Scenarios:

- Owner doesn't sign the transaction.
- Oracle token is preset in some output i.e. is not being burned.

#pagebreak()


== Audited Files
#v(1em)

Below is a list of all files audited in this report, any files *not* listed here were *not* audited.
The final state of the files for the purposes of this report is considered to be commit #link("https://github.com/SundaeSwap-finance/sundae-contracts/commit/da66d15afa9897e6bdb531f9415ddb6c66f19ce4")[`da66d15afa9897e6bdb531f9415ddb6c66f19ce4`].

#files_audited(
  items: (
    "validators/oracle.ak",
    "validators/order.ak",
    "validators/pool.ak",
    "validators/pool_stake.ak",
    "validators/settings.ak",
    "validators/stake.ak",
    "lib/calculation/deposit.ak",
    "lib/calculation/donation.ak",
    "lib/calculation/process.ak",
    "lib/calculation/record.ak",
    "lib/calculation/shared.ak",
    "lib/calculation/strategy.ak",
    "lib/calculation/swap.ak",
    "lib/calculation/withdrawal.ak",
    "lib/shared.ak",
    "lib/types/oracle.ak",
    "lib/types/order.ak",
    "lib/types/pool.ak",
    "lib/types/settings.ak",
    "https://github.com/SundaeSwap-finance/aicone/blob/main/lib/sundae/multisig.ak",
  )
)

#pagebreak()

= Findings
#v(1em)
#findings(items: (
/*  (
    id: [SSW-XXX],         // first digit corresponds to severity (see below)
    title: [XXXXXXX],
    severity: "Critical",  // one of: Critical (0), Major (1), Minor (2), Info (3)
    status: "Resolved",    // one of: Resolved, Acknowledged, Identified
    category: "Bug",       // open, for example: Bug, Style, Redundancy, Efficiency, External, etc.
    commit: "",
    description: [
      XXXXXXX
    ],
    recommendation: [
      XXXXXXX
    ],
    resolution: [
      // we put here the commit with message "Merge pull request #NN from ..."
      Resolved in commit `XXXX`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/NN")[PR \#NN]).
    ],
  ), */
  (
    id: [SSW-001],
    title: [Create pool doesn't validate the pool output address],
    severity: "Critical",
    status: "Resolved",
    category: "Vulnerability",
    commit: "4a5f4f494665f7a110e89d5aa5425fd5cae2311a",
    description: [
      There is no check on the pool output address where pool datum and value
      are paid to. Without this check, a pool NFT can be minted and paid to any
      address, even a particular wallet. This token can be used later to scoop
      orders that are not directed to a specific pool and steal their funds.
    ],
    recommendation: [
      Check that the pool ouput is paid to the pool script hash. This is, that
      the payment part of the output address equals the own policy ID.
    ],
    resolution: [
      Resolved in commit `d43f212d2a94507bbc7964757093b615c69a8d05`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/53")[PR \#53]).
    ],
  ),
  (
    id: [SSW-002],
    title: [Pool output address is not correctly checked in scoop operation],
    severity: "Critical",
    status: "Resolved",
    category: "Vulnerability",
    commit: "00d71b1ff06eac15284c191834926be2d6fe17ed",
    description: [
      The payment part of the output address is not being checked to be correct
      under the "PoolScoop" redeemer.
      Without this check, it is possible for a scooper to pay the pool funds
      and datum to any payment key or script hash, effectively dismanlting the
      pool and stealing the funds.

      The required check was there at
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/ca212dcefc36ef03c9f60d33efdd31db02d21e9b/validators/pool.ak#L211")[some point]
      but it was lost while or after solving SSW-302.
    ],
    recommendation: [
      Check that the pool ouput is paid to the pool script hash.
      The check can be done a single time at the top-level of the validator so
      it applies to both redeemers "PoolScoop" and "WithdrawFees".
    ],
    resolution: [
      Resolved in commit `d43f212d2a94507bbc7964757093b615c69a8d05`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/53")[PR \#53]).
    ],
  ),
  (
    id: [SSW-101],
    title: [Settings datum size is limited forever by the initially locked ADA],
    severity: "Major",
    status: "Resolved",
    category: "Bug",
    commit: "4a5f4f494665f7a110e89d5aa5425fd5cae2311a",
    description: [
      Once the protocol settings UTxO is created, it is not possible to change
      the value locked into it, and in particular the min ADA required by
      Cardano for storing the UTxO in the blockchain.
      If an update in the settings requires storing a bigger datum, for
      instance by adding elements to some of the stored lists, it may be
      possible that the min ADA required is more than the locked one, making
      the update impossible.
    ],
    recommendation: [
      The spending validator for the settings UTxO should allow the possiblity
      of changing the locked value at least for adding more ADA.
    ],
    resolution: [
      Resolved in commit `c65928e0cb00a27a5ac9672d9f9ea0f81a8cc38b`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/54")[PR \#54]).
    ],
  ),
  (
    id: [SSW-102],
    title: [Order `Scoop` redeemer enforces one and only one withdrawal],
    severity: "Major",
    status: "Resolved",
    category: "Bug",
    commit: "4b9fd66acfc2752623d766c95a776263106bdbcd",
    description: [
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/4b9fd66acfc2752623d766c95a776263106bdbcd/validators/order.ak#L48")[This] `expect` clause of the Order validator enforces that in a Scoop there's one and only one withdrawal.

      An issue that may arise because of this is a failure in a scroop transaction when there's a Strategy Order where `StrategyAuthorization` is `Script`. #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/4b9fd66acfc2752623d766c95a776263106bdbcd/lib/calculation/strategy.ak#L88")[This script must be in the withdrawals], and is not equal than the withdrawal script that the Order validator is expecting.

      Another thing to take into account is that the withdrawals are in lexicographical order, so we should be careful when assuming that a certain script is in some specific index of the withdrawals as a list.
    ],
    recommendation: [
      Allow the possiblity to have more than one withdrawal script in a transaction that involves the `Scoop` redeemer of the Order validator.
    ],
    resolution: [
      Resolved in commit `b6fbf3dfa98fa7a0dda65e2d20814dfbf50db365`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/74")[PR \#74]).
    ],
  ),
  (
    id: [SSW-201],
    title: [Create pool doesn't validate if ADA is not in the pair],
    severity: "Minor",
    status: "Resolved",
    category: "Bug",
    commit: "4a5f4f494665f7a110e89d5aa5425fd5cae2311a",
    description: [
      Pool output value is checked to have at most 3 different assets (line
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/4a5f4f494665f7a110e89d5aa5425fd5cae2311a/validators/pool.ak#L415")[415]).
      However, if ADA is not in the pair of assets (A, B), the output value
      will have four assets: A, B, ADA and the pool NFT.
      Therefore, the validation fails and it is not possible to create the pool.
    ],
    recommendation: [
      A quick solution is to fix the check so it compares to 3 or 4 depending
      if ADA is in the pair or not.

      Alternatively, we propose to change the approach for validating the
      output value by building the expected output value and comparing it with
      value equality.
      We think this approach is more straightforward and less error prone as it
      ensures that there is only one possible outcome for the value.
    ],
    resolution: [
      Resolved in commit `ad7183c85af150451dc32a7c3ac091d125f65574`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/66")[PR \#66]).
    ],
  ),
  (
    id: [SSW-202],
    title: [Metadata output datum not checked in pool create],
    severity: "Minor",
    status: "Resolved",
    category: "Bug",
    commit: "4a5f4f494665f7a110e89d5aa5425fd5cae2311a",
    description: [
      In pool create, no check is done on the datum that is paid to the metadata output.
      If the payment is done with no datum and the metadata address set in the settings corresponds to a script, the UTxO will be locked forever and it will not be possible to set the metadata.
    ],
    recommendation: [
      Ensure, at least, that the metadata output has a datum.
      If the metadata address corresponds a script, this is a necessary condition for the UTxO to be spent.
    ],
    resolution: [
      Resolved in commit `b731c1f5e16cf5be0d39dabae0246eba728ea3ad`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/55")[PR \#55]).
    ],
  ),
  (
    id: [SSW-203],
    title: [Create pool doesn't validate `fees_per_10_thousand` in pool output
    datum],
    severity: "Minor",
    status: "Resolved",
    category: "Robustness",
    commit: "4a5f4f494665f7a110e89d5aa5425fd5cae2311a",
    description: [
      In pool create, no checks are done on the `fees_per_10_thousand` field in
      the pool output datum.
      This field is a pair of integers that represent percentages with two
      decimals.
      If the integers are not in the range [0, 10000] they will not represent
      valid percentage values.
    ],
    recommendation: [
      Add the missing checks to ensure that the integers are in the correct
      range.
    ],
    resolution: [
      Resolved in commit `c290154883e21373ebcc9dcf575d1311388b9429`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/56")[PR \#56]).
    ],
  ),
  (
    id: [SSW-204],
    title: [No way to modify the list of authorized staking keys in the
    protocol settings],
    severity: "Minor",
    status: "Resolved",
    category: "Bug",
    commit: "4a5f4f494665f7a110e89d5aa5425fd5cae2311a",
    description: [
      Once the protocol settings UTxO is created, it is not possible to modify
      the `authorized_staking_keys` field in the UTxO datum.
      The spending validator is checking that this field is not changed both in
      the cases of settings admin and treasury admin updates.
    ],
    recommendation: [
      Depending on business requirements, devise some way that the
      `authorized_staking_keys` field could be updated.
    ],
    resolution: [
      Resolved in commit `6104be8df1ec9dc81a9e38e84be7d15ea9d6510b`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/57")[PR \#57]).
    ],
  ),
  (
    id: [SSW-205],
    title: [Pool fees update lacks validation of fees percentages],
    severity: "Minor",
    status: "Resolved",
    category: "Robustness",
    commit: "4b9fd66acfc2752623d766c95a776263106bdbcd",
    description: [
      In the `CreatePool` redeemer there's a #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/e3b7ca3eebd64963c35bdfd2b5013b3a4c93bcef/validators/pool.ak#L499-L506")[check]
      for `bid_fees_per_10_thousand` and `ask_fees_per_10_thousand`
      for keeping them within the range [0, 10.000].

      In the `UpdatePoolFees` redeemer, those percentages
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/e3b7ca3eebd64963c35bdfd2b5013b3a4c93bcef/validators/pool.ak#L336-L337")[could be updated while this check is not performed].
      This implies that the fee manager could update them to whatever he wants,
      defeating the purpose of the check performed in `CreatePool`.
    ],
    recommendation: [
      Repeat said check in `UpdatePoolFees` redeemer.
    ],
    resolution: [
      Resolved in commit `a890bdee4f776d58ef5a022f18121bb77777acb2`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/75")[PR \#75]).
    ],
  ),
  (
    id: [SSW-206],
    title: [Pool NFT cannot be burned],
    severity: "Minor",
    status: "Resolved",
    category: "Bug",
    commit: "4b9fd66acfc2752623d766c95a776263106bdbcd",
    description: [
      The Pool minting policy has two redeemers: `CreatePool` and `MintLP`.

      - `CreatePool` checks that only one pool NFT is minted.
      - `MintLP` ensures that the pool NFT is not minted nor burned.

      Then, there's no possiblity of burning the pool NFT,
      which #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/e3b7ca3eebd64963c35bdfd2b5013b3a4c93bcef/validators/pool.ak#L288C51-L288C63")[is required]
      in the `WithdrawFees` redeeemer of the Pool validator whenever the Pool has no more liquidity.
    ],
    recommendation: [
      Add a new redeemer in the Pool minting policy that allows to burn the pool NFT
      under the expected conditions i.e. whenever the Pool has no more liquidity left.
    ],
    resolution: [
      Resolved in commit `e84cfdfe9b15ab2f85d960d6d840ac0305788d1a`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/73")[PR \#73]).
    ],
  ),
  (
    id: [SSW-301],
    title: [Redundant parameters in process_order: outputs = output + rest_outputs],
    severity: "Info",
    status: "Resolved",
    category: "Redundancy",
    commit: "bcde39aa87567eaee81ccd7fbaf045543c233daa",
    description: [
      The `process_order` function takes an `outputs` list but also its head
      `output` and tail `rest_outputs`.
      Probably for optimization, as the caller `process_orders` already
      destructured the list, to avoid repeating it.
      However, there is no need for the caller to destructure.
    ],
    recommendation: [
      Remove parameters `output` and tail `rest_outputs` from `process_orders`.
      Destructure inside `process_orders`, and remove destructuring from
      `process_orders`.
    ],
    resolution: [
      Resolved in commit `5d78f9e2ed10c7206711fc5a58ed0595dbf51c50`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/28")[PR \#28]).
    ],
  ),
  (
    id: [SSW-302],
    title: [Redundant check for pool output stake credential in pool scoop validator],
    severity: "Info",
    status: "Resolved",
    category: "Redundancy",
    commit: "bcde39aa87567eaee81ccd7fbaf045543c233daa",
    description: [
      Stake credential is checked in
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L230")[lines 230-231]
      but entire address was already checked in
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L125")[line 125].
    ],
    recommendation: [
      Remove redundant check.
    ],
    resolution: [
      Resolved in commit `7acd97e69f82e328587abac00ace3d226bddd933`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/26")[PR \#26]).
    ],
  ),
  (
    id: [SSW-303],
    title: [Optimizable power of two (`do_2_exp`)],
    severity: "Info",
    status: "Resolved",
    category: "Optimization",
    commit: "bcde39aa87567eaee81ccd7fbaf045543c233daa",
    description: [
      Function `do_2_exp` is used in the pool scoop operation to compute the
      power of 2 over the set {0, 1, ..., n-1} where n is the number of scooped
      orders. Current definition is a simple linear recursion, resulting in a
      relevant impact in mem/cpu consumption.
    ],
    recommendation: [
      Instead of current definition use the optimized `math.pow2`
      function from Aiken standard library, or the even more optimized version
      proposed by TxPipe #link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/27#issuecomment-1892738977")[here].

      Our tests with the provided benchmark
       #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/rrruko/update-benchmark/lucid/main.ts")[main.ts]
      show that the maximum number of orders can go from 32 to 36.
    ],
    resolution: [
      Resolved in commit `e92bff96934483bf4fe03762e5e2cdef9706eaae`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/27")[PR \#27]).
    ],
  ),
  (
    id: [SSW-304],
    title: [Redundant `datum` parameter in `process_order`],
    severity: "Info",
    status: "Resolved",
    category: "Redundancy",
    commit: "bcde39aa87567eaee81ccd7fbaf045543c233daa",
    description: [
      All the information used internally by `process_order` is contained in
      fields `details` and `destination` that are already parameters of
      `process_order`. Also: in do_deposit, do_withdrawal and do_donation
      directly pass details and destination.
    ],
    recommendation: [
      Remove `datum` parameter from `process_order`. In `do_deposit`,
      `do_withdrawal` and `do_donation`, directly pass `details` and
      `destination`, instead of whole datum.
    ],
    resolution: [
      Resolved in commit `c143cd30ccebfb8c83940d1fac34475d12a64d80`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/29")[PR \#29]).
    ],
  ),
  (
    id: [SSW-305],
    title: [Total fee computed recursively can be calculated in single
    expression],
    severity: "Info",
    status: "Resolved",
    category: "Optimization",
    commit: "bcde39aa87567eaee81ccd7fbaf045543c233daa",
    description: [
      Total fee is computed in `process_orders` using an accumulator parameter
      `total_fee` that is returned at the end of the recursion. Individual fee
      for each order is computed and returned by `process_order` to be
      accumulated.

      However, we observe that the result is equivalent to:

      `total_fee = amortized_base_fee * order_count + simple_fee * simple_count
      + strategy_fee * strategy_count`
    ],
    recommendation: [
      Remove `total_fee` as parameter and return value from `process_orders`.
      In `pool.ak`, directly define `total_protocol_fee` using the given
      formula.

      Also, there is no need for `process_order` to return the fee anymore.
    ],
    resolution: [
      Resolved in commit `e686590f18dce0ef50074296cdc502f2adb9fea0`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/30")[PR \#30]).
    ],
  ),
  (
    id: [SSW-306],
    title: [Optimizable check for initial LP minting in create pool],
    severity: "Info",
    status: "Resolved",
    category: "Optimization",
    commit: "4a5f4f494665f7a110e89d5aa5425fd5cae2311a",
    description: [
      In pool create, Aiken's `math.sqrt` is used to check for the correct
      initial minting of LP tokens.
      This function implements the recursive Babylonian method.
      However, the expected value for the sqrt is already known, as it is
      available in the minting field and in the datum.
      Having the expected value, it is much more efficient to check that it is
      correct by squaring it and comparing to the radicand:

      `
      /// Checks if an integer has a given integer square root x.
      /// The check has constant time complexity (O(1)).
      pub fn is_sqrt(self: Int, x: Int) -> Bool {
        x * x <= self && ( x + 1 ) * ( x + 1 ) > self
      }
      `

      See #link("https://github.com/aiken-lang/stdlib/pull/73")[this PR] for
      more information.
    ],
    recommendation: [
      First, define `initial_lq` by taking it from the minting field or from
      the datum (`circulating_lp`).
      Then, check that it is correct with `is_sqrt(coin_a_amt_sans_protocol_fees * coin_b_amt, initial_lq)`.
    ],
    resolution: [
      Resolved in commit `12a55dab0bdddd8d8eba6c1d98ef75c3b5f95747`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/58")[PR \#58]).
    ],
  ),
  (
    id: [SSW-307],
    title: [Optimizable check for LP minting in scoop],
    severity: "Info",
    status: "Resolved",
    category: "Optimization",
    commit: "fd3a48511eea723fe58d32e79993c86c26df0a94",
    description: [
      We understand that the idea in the current version of MintLP redeemer validation is to ensure that the UTxO
      that contains the pool NFT i.e. the pool UTxO must be in the inputs because in its spending validator the
      minting of LP tokens is controlled.

      The issue with this check is that it is O(n): the worst case being when the pool UTxO is in the tail of the inputs and there are +20 orders. Given that this redeemer runs during a scoop validation, it is interesting to
      optimize it as much as possible.
    ],
    recommendation: [
      Instead of checking the presence of the pool NFT in the inputs, we can check its presence in the outputs given
      that we can safely asume that the pool UTxO is the first output. This is O(1). But this is not sufficient:
      we must also check that the pool NFT is not being minted in this same transaction. These two checks ensure that
      the pool NFT is in the inputs.
    ],
    resolution: [
      Resolved in commit `db3d33e3a22a28a7c1e7abfcb798e00e68427ff6`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/59")[PR \#59]).
    ],
  ),
  (
    id: [SSW-308],
    title: [No checks on settings UTxO when it is created],
    severity: "Info",
    status: "Resolved",
    category: "Robustness",
    commit: "4a5f4f494665f7a110e89d5aa5425fd5cae2311a",
    description: [
      The settings UTxO creation is validated through the minting policy of the
      settings NFT token.
      This policy only checks for the minting itself, ensuring that the token
      name is correct and that the indicated UTxO is consumed (this way
      enforcing an NFT).
      There is no validation of where is this NFT being paid to, or anything
      related to the creation of the settings UTxO.

      However, the policy could also be checking for the creation of the
      settings UTxO, including checks for the correct address, value and datum.
      This pattern is known as the “base case” for the “inductive reasoning”
      that can guarantee the consistency of the contract state through its
      entire lifetime.

      *Reference:*
      Edsko de Vries, Finley McIlwaine.
      #link("https://well-typed.com/blog/2022/08/plutus-initial-conditions/")[_Verifying initial conditions in Plutus_].
    ],
    recommendation: [
      In the settings NFT minting policy, add checks to ensure that the
      settings UTxO is correctly created.
      This is, check the payment to the correct address, datum and value.
    ],
    resolution: [
      Resolved in commit `f007b795e9e49a38e0b3f00355d4f97ce1e27c3a`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/60")[PR \#60]).
    ],
  ),
  (
    id: [SSW-309],
    title: [Optimizable manipulation of values in `do_donation`],
    severity: "Info",
    status: "Resolved",
    category: "Optimization",
    commit: "2487900eea2ea1d87f6e8a04707dcf039becd265",
    description: [
      The processing of donation orders could be optimized in its manipulation of values.
      In particular, when computing the `remainder` variable the `value.merge` and `value.negate` functions are used (see #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/2487900eea2ea1d87f6e8a04707dcf039becd265/lib/calculation/donation.ak#L39-L44")), which are not particularly efficient.
    ],
    recommendation: [
      Instead of using `value.merge` and `value.negate` it's possible to use `value.add` (a lot more efficient) to achieve the same effect.

      For example:
      ```
      let remainder =
        input_value
          |> value.add(ada_policy_id, ada_asset_name, -actual_protocol_fee)
          |> value.add(assets.1st.1st, assets.1st.2nd, -assets.1st.3rd)
          |> value.add(assets.2nd.1st, assets.2nd.2nd, -assets.2nd.3rd)
      ```
      gives us better mem and cpu numbers in the 30 shuffled orders processing test.

      The original implementation gives

      `PASS [mem: 12571807, cpu: 4883611979] process_30_shuffled_orders_test`

      while the version with just `value.add`'s

      `PASS [mem: 10580319, cpu: 4281305949] process_30_shuffled_orders_test`

      (numbers obtained with aiken version v1.0.21-alpha+4b04517)
    ],
    resolution: [
      Resolved in commit `30f4d17cacc3fa9d8bc7a6d85ecae4eb4772e8a4`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/61")[PR \#61]).
    ],
  ),
  (
    id: [SSW-310],
    title: [Formula simplifications in `do_deposit`],
    severity: "Info",
    status: "Resolved",
    category: "Simplification",
    commit: "2487900eea2ea1d87f6e8a04707dcf039becd265",
    description: [
      To compute the final amounts to be deposited, change is calculated in two
      different ways depending on wich of the assets is the one that has a
      change.
      However, it is possible to skip the change definition and have simpler
      formulas for the final amounts.
    ],
    recommendation: [
      For the first case, where there is change in asset B, the deposited B
      amount can be directly computed as:

      `
      pool_state.quantity_b.3rd * user_gives_a / pool_state.quantity_a.3rd
      `

      To preserve the exact same rounding behavior as the original code,
      ceiling division should be used:

      `
      (pool_state.quantity_b.3rd * user_gives_a - 1) / pool_state.quantity_a.3rd + 1
      `

      For the second case, where there is change in asset A, the deposited A
      amount can be directly defined as `b_in_units_of_a`.

      *Proof:* (Rounding details are left out of the proof.)

      First, `change` definition can be simplified as follows:
      `
      change
      =  // definition of change
      quantity_b * (b_in_units_of_a - user_gives_a) / quantity_a
      =  // definition of b_in_units_of_a
      quantity_b * (user_gives_b * quantity_a / quantity_b - user_gives_a) / quantity_a
      = // distributive
      quantity_b * user_gives_b * quantity_a / quantity_b / quantity_a
      - quantity_b * user_gives_a / quantity_a
      = // cancel out quantity_a and quantity_b
      user_gives_b - quantity_b * user_gives_a / quantity_a
      `

      Then, deposited B amount is:
      `
      user_gives_b - change
      = // simplified version of change
      user_gives_b -  (user_gives_b - quantity_b * user_gives_a / quantity_a)
      = // math
      quantity_b * user_gives_a / quantity_a
      `

      On the other hand, deposited A amount is
      `
      user_gives_a - change
      = // definition of change
      user_gives_a - (user_gives_a - b_in_units_of_a)
      = // math
      b_in_units_of_a
      `
    ],
    resolution: [
      Resolved in commit `db5185ca01e3ffdb4c643a651f4b439ddd3d0ae4`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/76")[PR \#76]).
    ],
  ),
  (
    id: [SSW-311],
    title: [Asymmetry of deposit operation],
    severity: "Info",
    status: "Acknowledged",
    category: "Theoretical",
    commit: "2487900eea2ea1d87f6e8a04707dcf039becd265",
    description: [
      In abstract, the AMM model is defined over an unordered pair of assets
      {A, B}, so all operations are symmetric in term of the roles of A and B.
      In Sundae's implementation, the deposit operation is asymmetric at least
      for some corner cases, as illustrated in the tests provided in
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/tree/francolq/ssw-311")[this branch].

      This issue is related to the way that function `do_deposit` is
      implemented and the rounding issues that arise when using integer
      arithmetics.
      The implementation can be easily modified to achieve symmetry.

      Our understanding is that this finding is not exploitable beyond rounding
      errors.
      However, symmetry may be a desirable property as it puts the
      implementation much closer to the theoretical model.
    ],
    recommendation: [
      If the symmetry property is desired, modify `do_deposit` in a way that it
      is guaranteed by the code.
    ],
    resolution: [
      *Project team* decided not to resolve this finding.
      Current business model and implementation, including the formulas for the
      deposit operation, are inherited from SundaeSwap V2 protocol, and were
      extensively tested in previous audits.
      As the *audit team* we endorse the decision, as this finding is only
      informational.
    ],
  ),
  (
    id: [SSW-312],
    title: [Optimizable manipulation of output value in `has_expected_pool_value`],
    severity: "Info",
    status: "Resolved",
    category: "Optimization",
    commit: "2487900eea2ea1d87f6e8a04707dcf039becd265",
    description: [
      As stated in a code comment #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/2487900eea2ea1d87f6e8a04707dcf039becd265/validators/pool.ak#L519")[here], each `value.quantity_of`, `value.lovelace_of`, and also `has_exact_token_count` calls traverse the output value. This could be optimized by doing just one traversal of the entire value.
    ],
    recommendation: [
      Instead of using `value.quantity_of`, `value.lovelace_of`, and `has_exact_token_count`, we can traverse the output value just once by converting it into a list and then using fold or a recursive function to perform all the needed checks throughout.
    ],
    resolution: [
      Resolved in commit `bfe8e8fd9f1177b6b202c6e871a8ed6e65d217e9`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/52")[PR \#52]).
    ],
  ),
  (
    id: [SSW-313],
    title: [`UpdatePoolFees` doesn't requires the settings UTxO as reference input],
    severity: "Info",
    status: "Acknowledged",
    category: "Redundancy",
    commit: "da66d15afa9897e6bdb531f9415ddb6c66f19ce4",
    description: [
      The settings UTxO is required as reference input #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L78")[by contract] in both spend Pool redeemers `PoolScoop` and `Manage`.
      This in particular means that in both `WithdrawFees` and `UpdatePoolFees` redeemers of the
      manage stake script is required as well.
      Furthermore, is
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L608")[explicitly looked up in there].
      Even though it's needed by `WithdrawFees` logic, for `UpdatePoolFees` logic it is not.
    ],
    recommendation: [
      Move the #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L78")[find_settings_datum]
      call from the Pool spend inside the `PoolScoop` branch, and in the manage stake script move
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/validators/pool.ak#L608")[such function call]
      inside the `WithdrawFees` branch.
    ],
    resolution: [
      *Project team* decided not to resolve this finding in the scope of the
      audited version.
      As the *audit team* we endorse the decision, since the downside is just
      the little extra off-chain work of adding the settings UTxO as
      reference input when building the update pool fees transaction.
    ],
  ),
  (
    id: [SSW-314],
    title: [`PoolState` not used anymore],
    severity: "Info",
    status: "Acknowledged",
    category: "Redundancy",
    commit: "da66d15afa9897e6bdb531f9415ddb6c66f19ce4",
    description: [
      Given the merged #link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/78")[PR \#78]
      `refactor to use continuations`, the
      #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/da66d15afa9897e6bdb531f9415ddb6c66f19ce4/lib/calculation/shared.ak#L8")[`PoolState` type]
      previously used is not needed anymore by the Pool validator.
    ],
    recommendation: [
      Remove `PoolState` type definition.
    ],
    resolution: [
      *Project team* decided not to resolve this finding in the scope of the
      audited version.
      As the *audit team* we endorse the decision, as this doesn't impact the
      contracts since unused structures are not included in the compilation result.
    ],
  ),
))


= Minor issues

In this section we list some issues we found that do not qualify as findings
such as typos, coding style, naming, etc.
We used the Github issues system to report them.

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/issues/37")[typo: continuout -> continuing \#37]

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/issues/38")[settings validator: use function to get spent output \#38]

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/issues/39")[unnecessary tuple definitions \#39]

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/issues/41")[compare_asset_class: camelCase to snake_case \#41]

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/issues/44")[testing code: replace "escrow" with "order" in definitions \#44]

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/issues/45")[pool validator: unused import TransactionId \#45]

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/issues/46")[settings type definition: unused import Output \#46]


= Contributed PRs

In this section we list some code contributions we did, usually as a result of
studying and/or confirming possible findings.

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/48")[New Aiken test for process_orders with 30 shuffled donation orders \#48]

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/52")[has_expected_pool_value traverses output value just once \#52]

- #link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/64")[Optimization for count_orders \#64]
