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

The assets sent are different depending on the type of Order but they all contain 2 ADA (considered as min ADA) and the maximum protocol fee that the user is willing to pay for the processing of the order.

More precisely, the assets apart from ADA for each kind of order are:

- Swap: the offered asset given in exchange for the pair's other asset.
- Deposit: both assets from the pair.
- Withdrawal: LP tokens.
- Donation: both assets from the pair.
- Strategy: no other assets.

#figure(
  image("img/create_order_swap.png", width: 100%),
  caption: [
    Create Swap Order diagram.
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
  (
    id: [SSW-001],
    title: [XXXXXXX],
    severity: "Critical",
    status: "Resolved",
    category: "Bug",
    commit: "",
    description: [XXXXXXX],
    recommendation: [XXXXXXX],
    resolution: [Resolved in commit `XXXX`],
  ),
))
