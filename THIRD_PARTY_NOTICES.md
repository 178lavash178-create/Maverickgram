# Third-Party Notices

## MiniZip from zlib 1.2.8

`Vendor/minizip` contains the `unzip` and `ioapi` portions of MiniZip from
zlib 1.2.8. MiniZip was originally written by Gilles Vollant, with Zip64
changes by Even Rouault and Mathias Svensson. The files retain their original
copyright and license notices.

zlib and MiniZip are provided "as-is", without express or implied warranty.
Permission is granted to use, modify, and redistribute the software for any
purpose, including commercial applications, provided that the origin is not
misrepresented, altered versions are marked, and the original notice is kept.

Source: https://github.com/madler/zlib/tree/v1.2.8/contrib/minizip

## libtgvoip 2.4.4

Telegraphica's optional audio-call transport build uses the archived
`telegramdesktop/libtgvoip` 2.4.4 source. The source is not vendored in this
repository; `scripts/build_libtgvoip_legacy.sh` accepts a local checkout and
applies the narrow OS X 10.8 compatibility patch kept under `Vendor/patches`.

libtgvoip is distributed under The Unlicense.

Source: https://github.com/telegramdesktop/libtgvoip/tree/2.4.4

Aqua toolbar silhouettes: Font Awesome Free 6.7.2 by Fonticons, Inc.
https://fontawesome.com/
https://fontawesome.com/license/free
Icons: Creative Commons Attribution 4.0 International.
https://creativecommons.org/licenses/by/4.0/
Paths unchanged; PNG conversion and runtime tint only.
Original SVGs, license and attribution bundled in Icons/AquaGlyphs.

## Phosphor Icons 2.1.1

Selected Aqua action glyphs use the bold weight of Phosphor Icons 2.1.1
by Phosphor Icons, licensed under the MIT License. Original SVGs, the
unmodified license, attribution and SHA-256 source/conversion manifest
are bundled in `Icons/Phosphor`. PNG conversion only; original paths unchanged.

Source: https://github.com/phosphor-icons/core/tree/2b75f3ad12b420c9504ef05df8d2564a28f8500e

The pre-existing flat PNG icon collection is separately inventoried in
`Icons/LEGACY_ASSET_INVENTORY.json`. Its upstream source and license were not
recorded in the repository; that inventory makes no third-party authorship
or license claim. It is not covered by the Phosphor or Font Awesome notices.
