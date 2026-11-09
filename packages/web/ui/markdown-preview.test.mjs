import test from "node:test";
import assert from "node:assert/strict";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KMarkdownPreview } from "./dist/editors/markdown-preview.js";
import { KMarkdownEditor } from "./dist/editors/markdown-editor.js";
import { KChatConversation } from "./dist/chat/conversation.js";

const render = (markdown, props = {}) =>
  renderToStaticMarkup(
    React.createElement(KMarkdownPreview, {
      markdown,
      ariaLabel: "Preview",
      ...props,
    }),
  );

test("preview renders GFM tables, images and code without modifying source", () => {
  const text =
    "| Name | Value |\n| --- | --- |\n| first | **second** |\n\n![Diagram](https://example.com/diagram.png)\n\n```js\nconst answer = 42;\n```";
  const html = render(text);
  assert.match(html, /<table/);
  assert.match(html, /<strong>second<\/strong>/);
  assert.match(html, /alt="Diagram"/);
  assert.match(html.replace(/<[^>]*>/g, ""), /const answer = 42/);
});

test("preview omits raw HTML and executable URLs", () => {
  const html = render(
    "<script>alert(1)</script>\n\n[bad](javascript:alert%281%29)\n\n<img src=x onerror=alert(1)>",
  );
  assert.doesNotMatch(html, /<script|<img[^>]*onerror=|href="javascript:/);
});

test("host resolves relative images without replacing the Markdown document", () => {
  const images = [];
  const html = render('![Local](./picture.png "Caption")', {
    renderImage: (image) => {
      images.push(image);
      return React.createElement("span", null, image.alt);
    },
  });
  assert.equal(images.length, 1);
  assert.equal(images[0].src, "./picture.png");
  assert.equal(images[0].alt, "Local");
  assert.match(html, /<span>Local<\/span>/);
});

test("editor preview uses shared document rendering and consumer options", () => {
  const images = [];
  const html = renderToStaticMarkup(
    React.createElement(KMarkdownEditor, {
      markdown:
        "# Preview\n\n![Private](./private.png)\n\n```js\nconst x = 1;\n```",
      defaultMode: "read",
      markdownOptions: {
        onCopy: () => {},
        copyLabel: "Quelltext kopieren",
        renderImage: (image) => {
          images.push(image.src);
          return React.createElement("span", null, image.alt);
        },
      },
    }),
  );
  assert.match(html, /class="k-markdown" data-profile="document"/);
  assert.match(html, /Quelltext kopieren/);
  assert.deepEqual(images, ["./private.png"]);
});

test("chat shares rendering and streaming state without changing message metadata", () => {
  const images = [];
  const html = renderToStaticMarkup(
    React.createElement(KChatConversation, {
      messages: [
        {
          id: "answer",
          role: "assistant",
          timestamp: "09:42",
          parts: [
            {
              id: "text",
              type: "text",
              streaming: true,
              text: "![Private](./private.png)\n\n```js\nconst x = 1;\n```\n",
            },
          ],
        },
      ],
      markdownOptions: {
        selectable: false,
        onCopy: () => {},
        copyLabel: "Quelltext kopieren",
        renderImage: (image) => {
          images.push(image.src);
          return React.createElement("span", null, image.alt);
        },
      },
    }),
  );
  assert.match(
    html,
    /data-profile="chat" data-selectable="false" data-streaming="true"/,
  );
  assert.match(html, /<time>09:42<\/time>/);
  assert.match(html, /role="log"[^>]+aria-busy="true"/);
  assert.match(html, /Quelltext kopieren/);
  assert.deepEqual(images, ["./private.png"]);
});

test("user message element policy leaves assistant Markdown and text intact", () => {
  const messages = ["user", "assistant"].map((role) => ({
    id: role,
    role,
    parts: [
      {
        id: `${role}-text`,
        type: "text",
        text: `# ${role} title\n\n**${role} body**`,
      },
    ],
  }));
  const html = renderToStaticMarkup(
    React.createElement(KChatConversation, {
      messages,
      userMarkdownAllowedElements: ["p"],
    }),
  );
  assert.match(html, /user title/);
  assert.match(html, /user body/);
  assert.doesNotMatch(html, /<h1\b[^>]*>user title|<strong>user body/);
  assert.match(html, /<h1\b[^>]*>assistant title/);
  assert.match(html, /<strong>assistant body/);
});
