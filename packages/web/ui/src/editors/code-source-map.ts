export const renderedSource = (source: string) =>
  source.replace(/\r\n|\r/g, "\n");
export function renderedToRaw(source: string, offset: number) {
  let raw = 0,
    rendered = 0;
  while (raw < source.length && rendered < offset) {
    if (source.charCodeAt(raw) === 13 && source.charCodeAt(raw + 1) === 10)
      raw++;
    raw++;
    rendered++;
  }
  return raw;
}
export function rawToRendered(source: string, offset: number) {
  let raw = 0,
    rendered = 0;
  while (raw < source.length && raw < offset) {
    if (source.charCodeAt(raw) === 13 && source.charCodeAt(raw + 1) === 10)
      raw++;
    raw++;
    rendered++;
  }
  return rendered;
}
export function sourceEdit(
  source: string,
  from: number,
  to: number,
  insert: string,
) {
  const separator = source.match(/\r\n|\r|\n/)?.[0] ?? "\n";
  return {
    from: renderedToRaw(source, from),
    to: renderedToRaw(source, to),
    insert: insert.replace(/\n/g, separator),
  };
}
export function renderedChange(before: string, after: string) {
  let from = 0,
    to = before.length,
    end = after.length;
  while (
    from < to &&
    from < end &&
    before.charCodeAt(from) === after.charCodeAt(from)
  )
    from++;
  while (
    to > from &&
    end > from &&
    before.charCodeAt(to - 1) === after.charCodeAt(end - 1)
  ) {
    to--;
    end--;
  }
  return { from, to, insert: after.slice(from, end) };
}
