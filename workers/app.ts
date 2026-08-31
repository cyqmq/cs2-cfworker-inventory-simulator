/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Ian Lucas. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { RouterContextProvider } from "react-router";
import { createRequestHandler } from "@react-router/cloudflare";
import type { ExportedHandler, D1Database, Fetcher } from "@cloudflare/workers-types";
import { setupTranslation } from "~/translation.server";

declare global {
  var ENV: Record<string, unknown> | undefined;
}

export interface Env {
  ASSETS: Fetcher;
  DB: D1Database;
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
    globalThis.ENV = env as unknown as Record<string, unknown>;
    setupTranslation();

    const response = await handleRequest({
      request,
      env,
      waitUntil: ctx.waitUntil ? ctx.waitUntil.bind(ctx) : () => {},
      passThroughOnException: ctx.passThroughOnException
        ? ctx.passThroughOnException.bind(ctx)
        : () => {}
    });

    const headers = response.headers;
    if (!headers.has("Strict-Transport-Security")) {
      headers.set("Strict-Transport-Security", "max-age=63072000; includeSubDomains; preload");
    }
    if (!headers.has("X-Content-Type-Options")) {
      headers.set("X-Content-Type-Options", "nosniff");
    }
    if (!headers.has("X-Frame-Options")) {
      headers.set("X-Frame-Options", "DENY");
    }
    if (!headers.has("Referrer-Policy")) {
      headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
    }
    if (!headers.has("Permissions-Policy")) {
      headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
    }
    return response;
  }
} satisfies ExportedHandler<Env>;
