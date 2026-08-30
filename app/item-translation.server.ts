/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Ian Lucas. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *  Item translations are split per language to keep the worker bundle small.
 *  The chosen language is injected at build time by the `inject-build-language`
 *  vite plugin based on the BUILD_LANGUAGE environment variable.
 *--------------------------------------------------------------------------------------------*/

import type { CS2ItemTranslationByLanguage } from "@ianlucas/cs2-lib";

// IMPORT_BUILD_LANGUAGE
declare const itemTranslations: Record<string, unknown>;
declare const buildLanguage: string;

export const itemTranslationByLanguage =
  itemTranslations as CS2ItemTranslationByLanguage;

export const defaultBuildLanguage = buildLanguage;
