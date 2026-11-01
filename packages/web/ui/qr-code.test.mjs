import test from "node:test";
import assert from "node:assert/strict";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { Resvg } from "@resvg/resvg-js";
import jsQR from "jsqr";
import { KQrCode, qrInk } from "./dist/data-display/qr-code.js";

for (const data of [
  "https://example.com/book/alex",
  "https://example.com/u/a-longer-booking-page-name?lang=de",
  "https://example.com/予約",
]) {
  for (const variant of ["classic", "soft", "portrait", "card"]) {
    for (const moduleShape of ["square", "rounded", "dots", "fluid"])
      for (const eyeShape of ["square", "rounded", "circle"])
        test(`${variant}/${moduleShape}/${eyeShape} decodes ${data}`, () => {
          const html = renderToStaticMarkup(
            React.createElement(KQrCode, {
              data,
              label: "Booking",
              variant,
              moduleShape,
              eyeShape,
              color: "#facc15",
            }),
          );
          let svg = html.match(/<svg[\s\S]*?<\/svg>/)[0];
          if (variant === "portrait") {
            const extent = Number(svg.match(/viewBox="0 0 (\d+)/)[1]);
            // Test the entire central image footprint as lost data, including its border.
            const radius = (extent - 8) * 0.08 + 0.6;
            svg = svg.replace(
              "</svg>",
              `<circle cx="${extent / 2}" cy="${extent / 2}" r="${radius}" fill="white"/></svg>`,
            );
          }
          const png = new Resvg(svg, {
            fitTo: { mode: "width", value: 240 },
          }).render();
          const decoded = jsQR(
            new Uint8ClampedArray(png.pixels),
            png.width,
            png.height,
          );
          assert.equal(decoded?.data, data);
        });
  }
}
test("invalid colors fall back and light colors darken", () => {
  assert.equal(qrInk("invalid"), "#18181b");
  assert.equal(qrInk("#ffffff"), "#969696");
});
