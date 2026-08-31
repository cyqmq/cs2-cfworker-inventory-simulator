/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Ian Lucas. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { RouterContextProvider } from "react-router";
import { createRequestHandler } from "@react-router/cloudflare";
import type { ExportedHandler, KVNamespace, D1Database, Fetcher } from "@cloudflare/workers-types";
import { setupTranslation } from "~/translation.server";

declare global {
  var ENV: Record<string, any> | undefined;
}

export interface Env {
  ASSETS: Fetcher;
  DB: D1Database;
  CACHE: KVNamespace;
  NODE_ENV: string;
}

const handleRequest = createRequestHandler<Env>({
  build: () => import("virtual:react-router/server-build"),
  mode: import.meta.env.MODE,
  getLoadContext() {
    return new RouterContextProvider();
  }
});

export default {
  async fetch(request, env, ctx) {
    globalThis.ENV = env;
    setupTranslation();

    return handleRequest({
      request,
      env,
      waitUntil: ctx.waitUntil ? ctx.waitUntil.bind(ctx) : () => {},
      passThroughOnException: ctx.passThroughOnException
        ? ctx.passThroughOnException.bind(ctx)
        : () => {}
    });
  }
} satisfies ExportedHandler<Env>;
