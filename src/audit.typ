#import "templates/report.typ": *

#show: report.with(
  client: "Sundae Labs",
  title: "V3",
  repo: "https://github.com/txpipe-shop/sundae-swap",
  date: "XXXXX",
)

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

Explanation of transaction here

No validation code executed in this transaction.

=== Operation "cancel order"

Explanation of transaction here

Code:
https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/order.ak#L11

Expected Failure Scenarios:

=== Operation "create pool"

Explanation of transaction here

Code:
- Mint/CreatePool:
https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L281

Expected Failure Scenarios:

- Check 1
- Check 2
- ...

=== Operation "scoop"

Explanation of transaction here

Code:
- Pool/PoolScoop redeemer:
https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L140
- Order/Scoop redeemer:
https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/order.ak#L19
- Stake validator:
https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/stake.ak#L12
- LP mint:
https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L375

Expected Failure Scenarios:

- Check 1
- Check 2
- ...

=== Operation "withdraw fees"

Code:
https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/pool.ak#L234


=== Operation "create settings"

Explanation of transaction here

Code:
https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/settings.ak#L87

Expected Failure Scenarios:

- Check 1
- Check 2
- ...

=== Operation "update settings"

Explanation of transaction here

For simplicity we include here both redeemers SettingsAdminUpdate and TreasuryAdminUpdate.

Code:
https://github.com/SundaeSwap-finance/sundae-contracts/blob/bcde39aa87567eaee81ccd7fbaf045543c233daa/validators/settings.ak#L8

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
