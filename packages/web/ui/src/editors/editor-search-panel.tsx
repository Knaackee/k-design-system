import {
  SearchQuery,
  closeSearchPanel,
  findNext,
  findPrevious,
  getSearchQuery,
  replaceAll,
  replaceNext,
  setSearchQuery,
} from "@codemirror/search";
import type { EditorView, Panel, ViewUpdate } from "@codemirror/view";
import { useEffect, useState, type KeyboardEvent } from "react";
import { createRoot, type Root } from "react-dom/client";
import { KIconButton } from "../actions/icon-button.js";
import { KInput } from "../forms/input.js";
import type { KEditorLabels } from "./types.js";

export interface KEditorSearchPanelProps {
  view: EditorView;
  labels: KEditorLabels;
  externalQuery: SearchQuery;
}

export function KEditorSearchPanel({
  view,
  labels,
  externalQuery,
}: KEditorSearchPanelProps) {
  const [query, setQuery] = useState(externalQuery);
  const [showReplace, setShowReplace] = useState(false);

  useEffect(() => {
    setQuery(externalQuery);
  }, [externalQuery]);

  const updateQuery = (change: Partial<SearchQuery>) => {
    const next = new SearchQuery({
      search: change.search ?? query.search,
      replace: change.replace ?? query.replace,
      caseSensitive: change.caseSensitive ?? query.caseSensitive,
      literal: change.literal ?? query.literal,
      regexp: change.regexp ?? query.regexp,
      wholeWord: change.wholeWord ?? query.wholeWord,
      test: change.test ?? query.test,
    });
    setQuery(next);
    view.dispatch({ effects: setSearchQuery.of(next) });
  };

  const runFromField = (
    event: KeyboardEvent<HTMLInputElement>,
    action: (view: EditorView) => boolean,
  ) => {
    if (event.key !== "Enter") return;
    event.preventDefault();
    action(view);
  };

  const mainField = { "main-field": "true" } as const;

  const cursor = query.valid ? query.getCursor(view.state.doc) : null;
  let total = 0;
  let current = 0;
  if (cursor) {
    for (let match = cursor.next(); !match.done; match = cursor.next()) {
      total++;
      if (
        match.value.from === view.state.selection.main.from &&
        match.value.to === view.state.selection.main.to
      )
        current = total;
    }
  }
  return (
    <div className="k-editor-search-panel__compact">
      <div className="k-editor-search-panel__toggle">
        {!view.state.readOnly && (
          <KIconButton
            icon={showReplace ? "chevron-down" : "chevron-right"}
            label={labels.searchShowReplace}
            aria-expanded={showReplace}
            onClick={() => setShowReplace(!showReplace)}
          />
        )}
      </div>
      <div className="k-editor-search-panel__fields">
        <div className="k-editor-search-panel__line">
          <KInput
            {...mainField}
            name="search"
            value={query.search}
            placeholder={labels.searchFind}
            aria-label={labels.searchFind}
            autoComplete="off"
            onChange={(event) => updateQuery({ search: event.target.value })}
            onKeyDown={(event) =>
              runFromField(event, event.shiftKey ? findPrevious : findNext)
            }
            trailingAction={
              <div className="k-editor-search-panel__inline-options">
                <KIconButton
                  icon="case-sensitive"
                  label={labels.searchMatchCase}
                  aria-pressed={query.caseSensitive}
                  onClick={() =>
                    updateQuery({ caseSensitive: !query.caseSensitive })
                  }
                />
                <KIconButton
                  icon="whole-word"
                  label={labels.searchWholeWord}
                  aria-pressed={query.wholeWord}
                  onClick={() => updateQuery({ wholeWord: !query.wholeWord })}
                />
                <KIconButton
                  icon="regex"
                  label={labels.searchRegexp}
                  aria-pressed={query.regexp}
                  onClick={() => updateQuery({ regexp: !query.regexp })}
                />
              </div>
            }
          />
          <div className="k-editor-search-panel__controls">
            <span className="k-editor-search-panel__count" role="status">
              {total ? `${current} / ${total}` : "0 / 0"}
            </span>
            <KIconButton
              icon="arrow-up"
              label={labels.searchPrevious}
              disabled={!total}
              onClick={() => findPrevious(view)}
            />
            <KIconButton
              icon="arrow-down"
              label={labels.searchNext}
              disabled={!total}
              onClick={() => findNext(view)}
            />
            <KIconButton
              icon="x"
              label={labels.searchClose}
              onClick={() => closeSearchPanel(view)}
            />
          </div>
        </div>
        {!view.state.readOnly && showReplace && (
          <div className="k-editor-search-panel__line">
            <KInput
              name="replace"
              value={query.replace}
              placeholder={labels.searchReplace}
              aria-label={labels.searchReplace}
              autoComplete="off"
              onChange={(event) => updateQuery({ replace: event.target.value })}
              onKeyDown={(event) => runFromField(event, replaceNext)}
            />
            <div className="k-editor-search-panel__controls">
              <KIconButton
                icon="replace"
                label={labels.searchReplace}
                disabled={!total}
                onClick={() => replaceNext(view)}
              />
              <KIconButton
                icon="replace-all"
                label={labels.searchReplaceAll}
                disabled={!total}
                onClick={() => replaceAll(view)}
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export function createKEditorSearchPanel(
  labels: KEditorLabels,
  onOpenChange?: (open: boolean) => void,
) {
  return (view: EditorView): Panel => {
    const dom = document.createElement("div");
    dom.className = "k-editor-search-panel";
    let root: Root | null = createRoot(dom);

    const render = () => {
      root?.render(
        <KEditorSearchPanel
          view={view}
          labels={labels}
          externalQuery={getSearchQuery(view.state)}
        />,
      );
    };

    render();
    return {
      dom,
      top: true,
      mount() {
        onOpenChange?.(true);
        queueMicrotask(() => {
          const input = dom.querySelector<HTMLInputElement>("[main-field]");
          input?.focus();
          input?.select();
        });
      },
      update(update: ViewUpdate) {
        if (
          update.docChanged ||
          update.selectionSet ||
          update.startState.readOnly !== update.state.readOnly ||
          update.transactions.some((transaction) =>
            transaction.effects.some((effect) => effect.is(setSearchQuery)),
          )
        ) {
          render();
        }
      },
      destroy() {
        onOpenChange?.(false);
        const mountedRoot = root;
        root = null;
        queueMicrotask(() => mountedRoot?.unmount());
      },
    };
  };
}
