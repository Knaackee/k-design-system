/** Only commit complete blocks while a response is still growing. */
export function streamingSource(content: string): {
  markdown: string;
  tail: string;
} {
  const source = content.replace(/\r\n|\r/g, "\n");
  let committed = 0;
  let fence: string | undefined;

  for (const line of source.matchAll(/[^\n]*\n/g)) {
    const value = line[0].slice(0, -1);
    const [, marker, suffix] = /^ {0,3}(`{3,}|~{3,})(.*)$/.exec(value) ?? [];
    const end = line.index + line[0].length;
    if (fence) {
      if (
        marker &&
        marker[0] === fence[0] &&
        marker.length >= fence.length &&
        /^[ \t]*$/.test(suffix ?? "")
      ) {
        fence = undefined;
        committed = end;
      }
    } else if (marker && (marker[0] !== "`" || !suffix?.includes("`"))) {
      fence = marker;
    } else if (/^[ \t]*$/.test(value)) {
      committed = end;
    }
  }

  // CommonMark displays an open top-level fence as code at end of input.
  if (fence) return { markdown: source, tail: "" };
  return {
    markdown: source.slice(0, committed),
    tail: source.slice(committed),
  };
}
