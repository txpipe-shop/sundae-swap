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

Explanation of transaction here

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/order.ak#L11")[order.ak:spend():Cancel]

Expected Failure Scenarios:

=== Operation "create pool"

Explanation of transaction here

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L281")[pool.ak:mint():CreatePool]

Expected Failure Scenarios:

- Check 1
- Check 2
- ...

=== Operation "scoop"

Explanation of transaction here

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L140")[pool.ak:spend():PoolScoop]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/order.ak#L19")[order.ak:spend():Scoop]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/stake.ak#L12")[stake.ak:stake():WithdrawFrom]
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L375")[pool.ak:mint():MintLP]

Expected Failure Scenarios:

- Check 1
- Check 2
- ...

=== Operation "withdraw fees"

Code:
- #link("https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L234")[pool.ak:spend():WithdrawFees]

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
    "XXXX",
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
    description: [XXXXXXX],
    recommendation: [XXXXXXX],
    resolution: [Resolved in commit `XXXX`],
  ), */
  (
    id: [SSW-301],
    title: [Redundant parameters in process_order: outputs = output + rest_outputs],
    severity: "Info",
    status: "Identified",
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
    resolution: [Resolved in commit `XXXX`],
  ),
))
