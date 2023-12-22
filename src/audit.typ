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

=== Operation XXX
#v(1em)
<Explanation of transaction here>

==== Expected Failure Scenarios
#v(1em)

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
