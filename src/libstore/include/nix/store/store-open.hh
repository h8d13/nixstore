#pragma once
/**
 * @file
 *
 * Exactly one store type exists (the local store), so the old
 * URI-parsing registry collapsed into this single constructor-shaped
 * entry point.
 */

#include "nix/store/store-api.hh"

namespace nix {

/**
 * Open the local store rooted at `root`: the store lives at
 * <root>/nix/store with state under <root>/nix/var. `root` must be
 * absolute. Extra config settings go in `params` (same keys the old
 * `local?root=...&k=v` URI accepted).
 */
ref<Store> openStore(const std::filesystem::path & root, Store::Config::Params params = {});

} // namespace nix
