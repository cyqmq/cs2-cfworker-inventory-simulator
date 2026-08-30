/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Ian Lucas. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import * as languages from "~/translations";
import { itemTranslationByLanguage } from "./item-translation.server";
import { serverGlobals } from "./globals";

export type SystemTranslationByLanguage = Record<
  string,
  Record<string, string>
>;
export type SystemTranslationTokens = keyof (typeof languages)["english"];

export function setupTranslation() {
  serverGlobals.systemTranslationByLanguage = languages;
  serverGlobals.itemTranslationByLanguage = itemTranslationByLanguage;
}
