#import "templates/report.typ": *

#show: report.with(
  client: "Sundae Labs",
  title: "V3",
  repo: "https://github.com/txpipe-shop/sundae-swap",
  date: "XXXXX",
)

#show link: underline

= Summary
#v(1em)
#lorem(50)
#v(1em)

== Overview
#v(1em)
#lorem(50)
#v(1em)

== Process
#v(1em)
#lorem(50)
#pagebreak()

== Transactions
#v(1em)
Below are a list of valid and invalid transactions as diagrams that can be build to interact with Sundae Swap DEX.

=== Operation "create order"

This transaction transfers funds from the user to the Order script address, whose associated validator will then be executed to unlock them. This transaction does not require a validator execution and stores a datum that contains information about the type of Order the user made.

The assets sent are different depending on the type of Order but they all contain at least the maximum protocol fee ADA, the assets relevant to the specific type of Order plus any other assets (optional).

More precisely, the assets relevant to the specific type of Order are:

- Swap: the offered asset given in exchange for the pair's other asset.
- Deposit: both assets from the pair.
- Withdrawal: LP tokens.
- Donation: both assets from the pair.
- Strategy: none.

#figure(
  image("img/create_order.png", width: 100%),
  caption: [
    Create Order diagram.
  ],
)

=== Operation "cancel order"

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
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/order.ak#L11")[order.ak:spend():Cancel]

Expected Failure Scenarios:
- Owner is *not* signing the transaction

=== Operation "create pool"

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
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L281")[pool.ak:mint():CreatePool]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L375")[pool.ak:mint():MintLP]

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

=== Operation "scoop"

This transaction processes a batch of orders against a particular pool, performed by an authorized scooper.

For each order input there is a related destination output that will contain the assets resulting from the processing of such order (plus a remainder in some cases *TODO list those cases*) and any other assets that were in the order and are not related with the pool. The only exception to this rule are Donation orders that have no reminder i.e. the liquidity ratio of the pool is preserved with the exact amounts provided in the donation.

Both the Pool and Order validators are executed. They are attached to the transaction within reference inputs.

#figure(
  image("img/scoop.png", width: 100%),
  caption: [
    Scoop diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L140")[pool.ak:spend():PoolScoop]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/order.ak#L19")[order.ak:spend():Scoop]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/stake.ak#L12")[stake.ak:stake():WithdrawFrom]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L375")[pool.ak:mint():MintLP]

Expected Failure Scenarios:

- Pool output address is not equal than Pool input address
- In the pool datum, other field/s than `circulating_lp` is/are modified
- Pool NFT is stolen from the Pool UTxO or burned
- Pool pair amounts does not match the expected quantities given the specific processed orders
- Pool output has a token that wasn't in the Pool input
- TODO failure scenarios regarding fees
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

=== Operation "withdraw fees"

Transaction description here.

#figure(
  image("img/withdraw_fees.png", width: 100%),
  caption: [
    Withdraw Fees diagram.
  ],
)

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L234")[pool.ak:spend():WithdrawFees]

Expected Failure Scenarios:

- Pool input address and Pool output address are distinct
- In Pool output Datum, any other field than the protocol fees one is updated
- The amount to withdraw specified within the redeemer does not match the amount of ADA taken from the Pool UTxO, or any of the other assets quantities of the UTxO change
- The transaction is not signed by the treasury administrator
- The treasury allowance part is not paid to the treasury address
- The amount to withdraw is greater than the available protocol fees in the Pool UTxO

=== Operation "create settings"

Explanation of transaction here

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/settings.ak#L87")[settings.ak:mint()]

Expected Failure Scenarios:

- Check 1
- Check 2
- ...

=== Operation "update settings"

Explanation of transaction here

For simplicity we include here both redeemers SettingsAdminUpdate and TreasuryAdminUpdate.

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/settings.ak#L8")[settings.ak:spend():SettingsAdminUpdate]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/settings.ak#L8")[settings.ak:spend():TreasuryAdminUpdate]

Expected Failure Scenarios:

- Check 1
- Check 2
- ...


#pagebreak()


=== Files Audited
#v(1em)

Below is a list of all files audited in this report, any files *not* listed here were *not* audited.
The final state of the files for the purposes of this report is considered to be commit `XXXX`.

#files_audited(
  items: (
    "validators/order.ak",
    "validators/pool.ak",
    "validators/pool_stake.ak",
    "validators/settings.ak",
    "validators/stake.ak",
    "lib/calculation/deposit.ak",
    "lib/calculation/donation.ak",
    "lib/calculation/process.ak",
    "lib/calculation/shared.ak",
    "lib/calculation/strategy.ak",
    "lib/calculation/swap.ak",
    "lib/calculation/withdrawal.ak",
    "lib/shared.ak",
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
    id: [SSW-001],         // first digit corresponds to severity (see below)
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
      Resolved in commit `XXXX`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/NN")[PR \#NN]).
    ],
  ), */
  (
    id: [SSW-001],
    title: [Create pool doesn't validate the pool output address],
    severity: "Critical",
    status: "Identified",
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
      Resolved in commit `XXXX`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/NN")[PR \#NN]).
    ],
  ),
  (
    id: [SSW-201],
    title: [Create pool doesn't validate if ADA is not in the pair],
    severity: "Minor",
    status: "Identified",
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
      Resolved in commit `XXXX`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/NN")[PR \#NN]).
    ],
  ),
  (
    id: [SSW-202],
    title: [Metadata output datum not checked in pool create],
    severity: "Minor",
    status: "Identified",
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
      Resolved in commit `XXXX`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/NN")[PR \#NN]).
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
    status: "Identified",
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
    resolution: [Resolved in commit `XXXX`],
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
    title: [Optimizable check for initial LP minting in create pool.],
    severity: "Info",
    status: "Identified",
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
      Resolved in commit `XXXX`
      (#link("https://github.com/SundaeSwap-finance/sundae-contracts/pull/NN")[PR \#NN]).
    ],
  ),
))
