# Aqua interface experiment

Branch: `feature/aqua-interface`. The existing Classic interface and Workshop stay available in the same application. This is an opt-in development experiment, not a release.

## Accepted direction

Aqua evokes OS X 10.7–10.9, silver iPod Classic hardware and iOS 6: metal chrome, inset source lists and inputs, restrained glossy cobalt controls, pale blue/pearl messages and a light linen conversation surface. It must remain structurally and materially distinct from a flat recolored interface. Atelier is outside this branch's scope.

The navigation lives in a top toolbar. Folders and chats use separate vertically stacked scroll views on the left; the folder area can collapse and its divider can be dragged. Existing forum/topic navigation is shared with Classic. The bottom utility buttons align with the composer controls. Existing approved icon assets are reused; the reference render is not an approved replacement icon pack.

## Switching and persistence

Settings → Appearance → Interface offers Classic and Aqua. Confirmation explicitly announces an automatic restart. No leaves the saved choice and current app unchanged. Yes starts a bounded relaunch helper, stages the preference and requests normal application termination. Only actual exit of the old PID allows the helper to open the same app bundle. Cancellation disarms the helper and rolls back the preference. The active design is immutable within a process, and the Classic palette preference is kept separately.

## Message footer

A short single reaction can share a compact text row when measured content, reaction and metadata all fit. Multiple/wide reactions use a lower wrapping footer. Time and the original receipt assets always have a reserved final-row slot. Classic geometry remains unchanged.

## Validation

Use the regular `scripts/run_tests.sh` suite, including separate-process Classic/Aqua restart, material, footer and source-list geometry probes. Compile and smoke-test with the unified 10.8 deployment target on the available legacy Mac. Live acceptance covers cancel, restart in both directions, folders with long names/many entries, divider/collapse, narrow windows, forum navigation, composer and lower utility alignment. A static rendering is not proof of final visual equivalence; compare the running legacy app before calling this complete.

Keep this experiment isolated from main/develop until the owner accepts the new interface. Do not publish a release from this work without an explicit release request.

## Material and source-list refinement

The source-list header is an embossed text heading with a separate text action. Its 18pt metal divider caps folder height at the actual row count and preserves usable chat space. Archive remains a folder only; Settings shares the composer's baseline in the continuous metal footer. The body and footer use one continuous divider with matching coordinates and material.

The original Subtle Patterns Brushed Alum and Black Linen PNGs ship with their attribution and CC BY-SA 3.0 license in `Resources/Textures`. They are decoded once and composited over the Aqua surfaces. Button light is a continuous gradient with an inset bevel, without a rectangular highlight overlay. All icons continue to use existing approved assets.

The account avatar fits its toolbar slot with a circular metal rim and an inset status dot. The movable chat-list header owns its metal backing, so its controls remain attached to a visible bar when folders resize or collapse. Settings is an integrated footer utility with the existing settings asset and update badge; its baseline follows the composer.


## Section navigation and chrome

Every Aqua section change recomputes shell geometry before presentation, including profile/back and indirect chat navigation. Contacts, Calls, Settings, Profile and Workshop meet the shared 52pt footer without reserving the hidden Classic navigation area. Closed chats and the media center also use that fixed footer regardless of a retained multiline draft. The media panel and section reveal stay above it.

The Aqua chat list uses square edges and meets the footer directly. The File button pairs the approved attachment image with its label; Classic cells keep their original artwork and geometry. Live checks should cover a multiline draft, every top-level section, back navigation, closed-chat suggestions, media-center navigation, and narrow-window resizing.
