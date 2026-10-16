# Aqua interface

Introduced in v0.6.0 after the owner accepted the experimental Aqua branch. Classic themes and Workshop remain available in the same application; Aqua is optional.

## Accepted direction

Aqua evokes OS X 10.7–10.9, silver iPod Classic hardware and iOS 6: metal chrome, inset source lists and inputs, restrained glossy cobalt controls, pale blue/pearl messages and a white default conversation surface with optional wallpapers. It must remain structurally and materially distinct from a flat recolored interface. Atelier is outside this branch's scope.

The navigation lives in a top toolbar. Folders and chats use separate vertically stacked scroll views on the left; the folder area can collapse and its divider can be dragged. Existing forum/topic navigation is shared with Classic. Chats, Contacts, Calls and Workshop use approved icons in the top toolbar; Settings is in the account dropdown, with titles exposed through tooltips and accessibility. The left chat list reaches the bottom of the window; only the active conversation retains a composer footer. Existing approved icon assets are reused; the reference render is not an approved replacement icon pack.

## Switching and persistence

Settings → Appearance → Interface offers Classic and Aqua. Confirmation explicitly announces an automatic restart. No leaves the saved choice and current app unchanged. Yes starts a bounded relaunch helper, stages the preference and requests normal application termination. Only actual exit of the old PID allows the helper to open the same app bundle. Cancellation disarms the helper and rolls back the preference. The active design is immutable within a process, and the Classic palette preference is kept separately.

## Message footer

Every reaction sits below message text, including a single short reaction. Reactions wrap when needed; time and the original receipt assets always have a reserved final-row slot. This below-text policy also applies to Classic.

## Validation

Use the regular `scripts/run_tests.sh` suite, including separate-process Classic/Aqua restart, material, footer and source-list geometry probes. Compile and smoke-test with the unified 10.8 deployment target on the available legacy Mac. Live acceptance covers cancel, restart in both directions, folders with long names/many entries, divider/collapse, narrow windows, forum navigation, composer and toolbar navigation. A static rendering is not proof of final visual equivalence; compare the running legacy app before calling this complete.

The owner accepted Aqua and explicitly requested the 0.6.0 release. Follow the normal develop/main review and release checks for publication.

## Material and source-list refinement

The source-list header is an embossed text heading with a separate text action. Its 18pt metal divider caps folder height at the actual row count and preserves usable chat space. Archive remains a folder only. Forum back navigation starts at the left edge of its header; long forum titles truncate on one line and expose their complete text through a tooltip.

The original Subtle Patterns Brushed Alum, Black Linen and White Brushed PNGs ship with their attribution and CC BY-SA 3.0 license in `Resources/Textures`. They are decoded once and composited over the Aqua surfaces. White Brushed adds real grain to silver controls and utility panels; linen is an optional conversation texture. Button light is a continuous gradient with an inset bevel, without a rectangular highlight overlay. All icons continue to use existing approved assets.

The account avatar fits its toolbar slot with a circular metal rim and an inset status dot. The movable chat-list header owns its metal backing, so its controls remain attached to a visible bar when folders resize or collapse. Settings is reached through the account dropdown; the four main section icons remain in the top toolbar.


## Section navigation and chrome

Every Aqua section change recomputes shell geometry before presentation, including profile/back and indirect chat navigation. Contacts, Calls, Settings, Profile and Workshop reclaim the space of the hidden Classic navigation area. Only a conversation reserves the composer footer, sized for its current draft; closed chats and media navigation keep their own content geometry.

The Aqua chat list uses square edges and meets the footer directly. The File button pairs the approved attachment image with its label; Classic cells keep their original artwork and geometry. Live checks should cover a multiline draft, every top-level section, back navigation, closed-chat suggestions, media-center navigation, and narrow-window resizing.


## Narrow media center

Aqua media tabs keep readable labels by wrapping into balanced rows. Status and result areas follow the extra tab height. The existing result views and hit targets reflow to the clip width on resize, preserving scroll position and thumbnail ownership without triggering pagination or rebuilding the results. Delayed history callbacks keep message-only navigation hidden while media or closed-chat content is displayed.


## Group replies and channel comments

A message thread capability alone does not create a visible comment button. Ordinary group messages with no replies keep the action in the context menu; existing replies appear as a passive icon and count beside the timestamp, with measured space reserved next to reactions and receipt assets. Channel posts retain their separate discussion link, including zero-comment discussions. The same metadata policy applies to Classic. Channel post identity survives message copies and album grouping.
