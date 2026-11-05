# Screen patterns

Recurring building blocks across apps (derived from the Onzeit and Assetry
reviews). Each maps to K components. **Gaps:** `KListItem`,
`KSegmentedControl` and `KPageHeader` are in the catalog but not implemented
yet; until they land, compose rows with `KSettingsRow`/`KInline` and peer views
with `KTabs`, and propose the component to the library instead of building a
local copy. A pattern without a gallery reference is marked _(planned)_.

| Pattern                              | Use for                                                                                        | K components                                                           |
| ------------------------------------ | ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Page header                          | Title, one-line context, primary actions; `KBackButton` (chevron, label names the destination) | KPageHeader / KText + KButton, KBreadcrumb on desktop                  |
| Grouped list                         | Same-kind items, settings, navigation hubs                                                     | KCard + KListItem / KSettingsSection + KSettingsRow                    |
| Group header with action             | "Gebäude · + Hinzufügen"                                                                       | KText(label) + KLink/KButton(ghost) in KInline(wrap)                   |
| Empty group row                      | First item of a group                                                                          | KListItem/KButton(ghost) "+ Add …" inside the group                    |
| Detail hub                           | Object with many sub-areas                                                                     | Facts (KBadge/KInline), section rows with counts → own pages           |
| Completeness                         | Data quality before analysis                                                                   | KProgress/ring + missing items as KFilterChip that open forms          |
| Form sheet                           | Create/edit an entity                                                                          | KResponsiveDrawer/KDialog, KField groups, paired fields, sticky footer |
| Inline dependency                    | Required related record is missing                                                             | Notice row with "Create …" that opens the dependent form               |
| Withdraw with reason                 | Soft delete with audit trail                                                                   | KAlertDialog + KTextarea (required)                                    |
| Share / members                      | Invite and roles                                                                               | KInput(email) + KSegmentedControl(role) + member rows with KSelect     |
| KPI strip                            | Dashboard numbers with trend                                                                   | KCard tiles (siblings!), sparkline, period KSegmentedControl           |
| Today timeline                       | Ordered day with travel/gaps                                                                   | KTimeline / list rows with KLeading times                              |
| List-detail                          | Master list + inspector on expanded+                                                           | KSidebar/secondary nav + detail page; bottom sheet on phones           |
| Chat with object cards               | Assistant answers referencing data                                                             | KChatConversation + list rows as cards, suggestion chips               |
| Onboarding                           | 3 short steps, skippable                                                                       | KProgressDots, KButton "Weiter", optional setup action                 |
| Settings                             | Preferences                                                                                    | KSettingsPage, segmented appearance, status in subtitle                |
| Sidebar app shell _(planned review)_ | Desktop navigation                                                                             | KSidebar + KResponsiveDrawer                                           |
