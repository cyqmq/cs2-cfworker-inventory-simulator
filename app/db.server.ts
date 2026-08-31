/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Ian Lucas. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { PrismaD1 } from "@prisma/adapter-d1";
import type { D1Database } from "@cloudflare/workers-types";
import { PrismaClient } from "./generated/prisma/client";

import { singleton } from "./singleton.server";

function getD1() {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const env = (globalThis as any).ENV;
  const db = env?.DB as D1Database | undefined;
  if (!db) {
    throw new Error("D1 binding `DB` is not available");
  }
  return db;
}

const getPrisma = () =>
  singleton(
    "prisma",
    () =>
      new PrismaClient({
        adapter: new PrismaD1(getD1()),
        log: []
      })
  );

export const prisma = new Proxy({} as PrismaClient, {
  get(_target, prop: keyof PrismaClient) {
    return getPrisma()[prop];
  }
});

export { getPrisma };
