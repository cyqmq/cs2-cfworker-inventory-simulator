/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Ian Lucas. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { CS2Economy, CS2_ITEMS } from "@ianlucas/cs2-lib";
import { schinese } from "@ianlucas/cs2-lib/translations/schinese";

let loaded = false;

export function ensureEconomyLoaded() {
  if (loaded) {
    return;
  }
  CS2Economy.load({ items: CS2_ITEMS, language: schinese });
  loaded = true;
}
