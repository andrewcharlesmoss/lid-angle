import { mkdir, readFile, writeFile } from "node:fs/promises";

const sourceUrl = new URL("./index.html", import.meta.url);
const screenshotUrl = new URL("./screenshot.png", import.meta.url);
const ogImageUrl = new URL("./og-image.png", import.meta.url);
const [sourceHtml, screenshot, ogImage] = await Promise.all([
  readFile(sourceUrl, "utf8"),
  readFile(screenshotUrl),
  readFile(ogImageUrl)
]);
const iconMatch = sourceHtml.match(/<img[^>]+src="(data:image\/png;base64,[^"]+)"/);
if (!iconMatch) throw new Error("Embedded app icon not found");
const html = sourceHtml.replaceAll(
  'href="favicon.png"',
  `href="${iconMatch[1]}"`
).replace(
  'const appIcon = "favicon.png"',
  `const appIcon = "${iconMatch[1]}"`
).replace(
  'src="footer-icon.png"',
  `src="${iconMatch[1]}"`
).replace(
  'src="screenshot.png"',
  `src="data:image/png;base64,${screenshot.toString("base64")}"`
);
const screenshotBase64 = screenshot.toString("base64");
const ogImageBase64 = ogImage.toString("base64");
const worker = `const page = ${JSON.stringify(html)};
const ogImage = Uint8Array.from(atob(${JSON.stringify(ogImageBase64)}), (char) => char.charCodeAt(0));

export default {
  fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === "/og-image.png") {
      return new Response(ogImage, {
        headers: {
          "content-type": "image/png",
          "cache-control": "public, max-age=86400"
        }
      });
    }
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
