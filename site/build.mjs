import { mkdir, readFile, writeFile } from "node:fs/promises";

const sourceUrl = new URL("./index.html", import.meta.url);
const screenshotUrl = new URL("./screenshot.png", import.meta.url);
const [sourceHtml, screenshot] = await Promise.all([
  readFile(sourceUrl, "utf8"),
  readFile(screenshotUrl)
]);
const html = sourceHtml.replace(
  'src="screenshot.png"',
  `src="data:image/png;base64,${screenshot.toString("base64")}"`
);
const worker = `const page = ${JSON.stringify(html)};

export default {
  fetch() {
    return new Response(page, {
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": "public, max-age=300"
      }
    });
  }
};
`;

await mkdir(new URL("./dist/server/", import.meta.url), { recursive: true });
await writeFile(new URL("./dist/server/index.js", import.meta.url), worker);
