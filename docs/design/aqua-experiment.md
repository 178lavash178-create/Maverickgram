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
