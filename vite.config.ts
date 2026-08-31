/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Ian Lucas. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { reactRouter } from "@react-router/dev/vite";
import { cloudflare } from "@cloudflare/vite-plugin";
import tailwindcss from "@tailwindcss/vite";
import wasm from "vite-plugin-wasm";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { createHash } from "crypto";
import { readdirSync } from "fs";
import { resolve } from "path";
import { minify_sync } from "terser";
import ts from "typescript";
import { defineConfig } from "vite";

const wasmSource = resolve(process.cwd(), "app/generated/prisma/internal/query_compiler_fast_bg.wasm");

export default defineConfig({
  server: {
    port: 3000
  },
  resolve: {
    tsconfigPaths: true
  },
  plugins: [
    cloudflare({ viteEnvironment: { name: "ssr" } }),
    tailwindcss(),
    {
      name: "normalize-wasm-module",
      enforce: "pre",
      transform(code, id) {
        if (id.endsWith("class.ts") && code.includes("query_compiler_fast_bg.wasm?module")) {
          return code.replace("query_compiler_fast_bg.wasm?module", "query_compiler_fast_bg.wasm");
        }
        return null;
      }
    },
    wasm(),
    {
      name: "patch-steamapi",
      enforce: "pre",
      transform(code, id) {
        if (id.includes("steamapi/dist/src/SteamAPI.js")) {
          return code
            .replace(
              "const require = createRequire(import.meta.url);",
              "const require = (_p) => ({});"
            )
            .replace(
              "const Package = require('../../package.json');",
              "const Package = { version: '3.1.5' };"
            );
        }
        return null;
      }
    },
    !process.env.VITEST && reactRouter(),
    {
      name: "inject-build-language",
      enforce: "pre",
      transform(code, id) {
        if (id.includes("app/item-translation.server.ts") && code.includes("IMPORT_BUILD_LANGUAGE")) {
          const buildLanguage = process.env.BUILD_LANGUAGE ?? "schinese";
          const languages = [
            "brazilian",
            "bulgarian",
            "czech",
            "danish",
            "dutch",
            "english",
            "finnish",
            "french",
            "german",
            "greek",
            "hungarian",
            "indonesian",
            "italian",
            "japanese",
            "koreana",
            "latam",
            "norwegian",
            "polish",
            "portuguese",
            "romanian",
            "russian",
            "schinese",
            "spanish",
            "swedish",
            "tchinese",
            "thai",
            "turkish",
            "ukrainian",
            "vietnamese"
          ];
          const lang = languages.includes(buildLanguage)
            ? buildLanguage
            : "schinese";
          const importAlias = `_buildLanguage${lang}`;
          const injected = [
            `import { ${lang} as ${importAlias} } from "@ianlucas/cs2-lib/translations/${lang}";`
          ].join("\n");
          const replaced = code.replace(
            "// IMPORT_BUILD_LANGUAGE",
            `${injected}\nconst itemTranslations: Record<string, unknown> = {\n  [${JSON.stringify(lang)}]: ${importAlias}\n};\nconst buildLanguage = ${JSON.stringify(lang)};`
          );
          return replaced
            .replace(
              "declare const itemTranslations: Record<string, unknown>;",
              ""
            )
            .replace("declare const buildLanguage: string;", "");
        }
        return null;
      }
    },
    {
      name: "copy-prisma-wasm",
      buildStart() {
        if (existsSync(wasmSource)) {
          const destDir = resolve(process.cwd(), "app/generated/prisma/internal");
          if (!existsSync(destDir)) {
            mkdirSync(destDir, { recursive: true });
          }
          const destFile = resolve(destDir, "query_compiler_fast_bg.wasm");
          const wasmBuffer = readFileSync(wasmSource);
          writeFileSync(destFile, wasmBuffer);
        }
      }
    }
  ],
  define: {
    __SPLASH_SCRIPT__: JSON.stringify(
      minify_sync(
        ts.transpileModule(
          readFileSync(resolve(process.cwd(), "app/utils/splash.ts"), {
            encoding: "utf-8"
          }),
          {
            compilerOptions: {
              module: ts.ModuleKind.CommonJS,
              noImplicitUseStrict: true,
              target: ts.ScriptTarget.ES2022
            }
          }
        ).outputText
      ).code
    ),
    __TRANSLATION_CHECKSUM__: JSON.stringify(
      (() => {
        const translationsDir = resolve(process.cwd(), "app/translations");
        const translationContents = readdirSync(translationsDir)
          .filter((f) => f.endsWith(".ts") && f !== "index.ts")
          .sort()
          .map((f) => readFileSync(resolve(translationsDir, f), "utf-8"))
          .join("");
        const cs2LibVersion = JSON.parse(
          readFileSync(
            resolve(
              process.cwd(),
              "node_modules/@ianlucas/cs2-lib/package.json"
            ),
            "utf-8"
          )
        ).version;
        return createHash("sha256")
          .update(cs2LibVersion + translationContents)
          .digest("hex")
          .substring(0, 7);
      })()
    ),
    __SOURCE_COMMIT__: JSON.stringify(process.env.SOURCE_COMMIT),
    __CS2_LIB_VERSION__: JSON.stringify(
      JSON.parse(
        readFileSync(
          resolve(
            process.cwd(),
            "node_modules/@ianlucas/cs2-lib/package.json"
          ),
          "utf-8"
        )
      ).version
    )
  }
});
