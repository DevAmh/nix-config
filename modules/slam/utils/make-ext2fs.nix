# SPDX-FileCopyrightText: 2026 Emery Hemingway
#
# SPDX-License-Identifier: PPL

{
  lib,
  stdenv,
  erofs-utils,
  closureInfo,

  fileName ? "erofs",
  # The root directory of the erofs filesystem is filled with the
  # closures of the Nix store paths listed here.
  storeContents ? [ ],
}:

stdenv.mkDerivation {
  name = "${fileName}.img";
  __structuredAttrs = true;

  # the image will be self-contained so we can drop references
  # to the closure that was used to build it
  unsafeDiscardReferences.out = true;

  nativeBuildInputs = [ erofs-utils ];

  buildCommand = ''
    closureInfo=${closureInfo { rootPaths = storeContents; }}

    # Also include a manifest of the closures in a format suitable
    # for nix-store --load-db.
    cp $closureInfo/registration path-registration

    # Generate the erofs image.
    while read path; do
      basename $path
    done < $closureInfo/store-paths \
    | xargs tar -c nix-path-registration -C /nix/store \
    | mkfs.erofs -zlz4hc -L nix-store -T0 \
      -U${"out" |> placeholder |> lib.toUuid} \
      --all-root --workers $NIX_BUILD_CORES --tar=f $out
  '';
}
