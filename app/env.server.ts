/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Ian Lucas. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { assert } from "@ianlucas/cs2-lib";

// Env values are read dynamically from `globalThis`/`process` (injected by the
// Cloudflare runtime), which requires `any` access.
/* eslint-disable @typescript-eslint/no-explicit-any */

function getSource() {
  // Cloudflare Workers: env bindings are injected by the runtime. In dev and
  // production they are stored on the worker `vars`. We splice them onto
  // `globalThis.ENV` from `workers/app.ts`.
  const workerEnv = (globalThis as any).ENV ?? {};
  const nodeEnv = (globalThis as any).process?.env ?? {};
  return {
    get(key: string): string | undefined {
      const value =
        workerEnv[key] ??
        nodeEnv[key] ??
        (globalThis as any)[key] ??
        undefined;
      return value === undefined || value === null
        ? undefined
        : String(value);
    }
  };
}

const source = getSource();

function required(key: string): string {
  const value = source.get(key);
  assert(value, `${key} must be set`);
  return value;
}

export const DATABASE_URL = source.get("DATABASE_URL");
export const NODE_ENV = source.get("NODE_ENV") ?? "development";
export const SESSION_SECRET = required("SESSION_SECRET");

export const ASSETS_BASE_URL = source.get("ASSETS_BASE_URL");
export const CLOUDFLARE_ANALYTICS_TOKEN =
  source.get("CLOUDFLARE_ANALYTICS_TOKEN");
export const CS2_CSGO_PATH = source.get("CS2_CSGO_PATH");
export const SOURCE_COMMIT = source.get("SOURCE_COMMIT");
export const STEAM_API_KEY = source.get("STEAM_API_KEY");
export const STEAM_CALLBACK_URL = source.get("STEAM_CALLBACK_URL");
export const VIEWER_ASSETS_BASE_URL = source.get("VIEWER_ASSETS_BASE_URL");
export const VIEWER_EMBED_URL = source.get("VIEWER_EMBED_URL");
export const VIEWER_KEY = source.get("VIEWER_KEY");
