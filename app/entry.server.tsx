/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Ian Lucas. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { isbot } from "isbot";
import { renderToReadableStream } from "react-dom/server";
import type { EntryContext } from "react-router";
import { ServerRouter } from "react-router";
import { warmViewerCaches } from "./data/viewer.server";
import { setupLogo } from "./logo.server";
import { setupRules } from "./models/rule";
import { setupTranslation } from "./translation.server";
import { ensureEconomyLoaded } from "./utils/economy-init.server";

const ABORT_DELAY = 5_000;

let initPromise: Promise<void> | null = null;
function startOnce() {
  if (initPromise) {
    return initPromise;
  }
  ensureEconomyLoaded();
  setupTranslation();
  initPromise = (async () => {
    await setupRules();
    await Promise.allSettled([
      setupLogo(),
      warmViewerCaches()
    ]);
  })();
  return initPromise;
}

export default async function handleRequest(
  request: Request,
  responseStatusCode: number,
  responseHeaders: Headers,
  routerContext: EntryContext
) {
  await startOnce();

  responseHeaders.set("Content-Type", "text/html");

  if (isbot(request.headers.get("user-agent"))) {
    const body = await renderToReadableStream(
      <ServerRouter context={routerContext} url={request.url} />,
      {
        signal: AbortSignal.timeout(ABORT_DELAY)
      }
    );
    return new Response(body, {
      headers: responseHeaders,
      status: responseStatusCode
    });
  }

  const body = await renderToReadableStream(
    <ServerRouter context={routerContext} url={request.url} />,
    {
      signal: AbortSignal.timeout(ABORT_DELAY)
    }
  );
  return new Response(body, {
    headers: responseHeaders,
    status: responseStatusCode
  });
}
