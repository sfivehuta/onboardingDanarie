# Org metadata backup: danarie (2026-10-22)

- Org: `danarie` (Org Id `00Dbm000014hyXZEAY`, instance `crm-danarie-dev-ed.develop.my.salesforce.com`)
- Format: Salesforce source format, API version 68.0
- Content: 253 metadata types (all components of each type, `members: *`), plus the custom objects Account, Case, Contact, Lead, Opportunity, Product2 and OpportunityLineItem named explicitly, 971 files. Includes the German object translations deployed on 2026-10-22.
- Folder `metadata/`: the retrieved source tree
- Folder `manifest/package.xml`: the manifest used for the retrieve

## What is not included

- Record data (no `sf data export` was run). Exports can contain personal data and should not be pushed to GitHub without review.
- 27 metadata types the local Salesforce CLI registry does not support (for example newer AI, Data Cloud and Marketing Cloud types). The list is in `skipped-types.txt`.
- Connected App secrets (never retrievable), and the `Salesforce_CLI` connected app, which the CLI reports as unavailable.
- Standard value set translations for unsupported languages (for example `nl`).

## Restore

Deploy the snapshot to an org (the folder carries its own `package.xml`):

    sf project deploy start --source-dir backup/2026-10-22/metadata --target-org <alias>

Use a sandbox or scratch org first. A deploy overwrites matching components.

## Re-run

    sf project retrieve start --manifest backup/2026-10-22/manifest/package.xml --target-metadata-dir <dir> --target-org danarie
