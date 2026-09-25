import {
  SearchQuery,
  closeSearchPanel,
  findNext,
  findPrevious,
  getSearchQuery,
  replaceAll,
  replaceNext,
  selectMatches,
  setSearchQuery,
} from "@codemirror/search";
import type { EditorView, Panel, ViewUpdate } from "@codemirror/view";
import { useEffect, useState, type KeyboardEvent } from "react";
import { createRoot, type Root } from "react-dom/client";
import { KIconButton } from "../actions/icon-button.js";
import { KCheckbox } from "../forms/checkbox.js";
import { KInput, KSearchField } from "../forms/input.js";
import { KButton } from "../primitives/button.js";
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
  const [showOptions, setShowOptions] = useState(false);
  const [showReplace, setShowReplace] = useState(false);

  useEffect(() => {
    if (!externalQuery.eq(query)) setQuery(externalQuery);
  }, [externalQuery, query]);

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

  return (
    <div className="k-editor-search-panel__content">
      <div className="k-editor-search-panel__search-row">
        <KSearchField
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
        />
      </div>

      <div className="k-editor-search-panel__actions-row">
        <div className="k-editor-search-panel__navigation">
          <KIconButton
            icon="chevron-up"
            label={labels.searchPrevious}
            disabled={!query.valid}
            onClick={() => findPrevious(view)}
          />
          <KIconButton
            icon="chevron-down"
            label={labels.searchNext}
            disabled={!query.valid}
            onClick={() => findNext(view)}
          />
          <KIconButton
            icon="sliders-horizontal"
            label={labels.searchOptions}
            aria-pressed={showOptions}
            onClick={() => setShowOptions((visible) => !visible)}
          />
          {!view.state.readOnly && (
            <KIconButton
              icon="pen"
              label={labels.searchShowReplace}
              aria-pressed={showReplace}
              onClick={() => setShowReplace((visible) => !visible)}
            />
          )}
          <KIconButton
            icon="x"
            label={labels.searchClose}
            onClick={() => closeSearchPanel(view)}
          />
        </div>
      </div>

      {showOptions && (
        <div className="k-editor-search-panel__options">
          <KCheckbox
            label={labels.searchMatchCase}
            value={query.caseSensitive}
            onValueChange={(caseSensitive) => updateQuery({ caseSensitive })}
          />
          <KCheckbox
            label={labels.searchRegexp}
            value={query.regexp}
            onValueChange={(regexp) => updateQuery({ regexp })}
          />
          <KCheckbox
            label={labels.searchWholeWord}
            value={query.wholeWord}
            onValueChange={(wholeWord) => updateQuery({ wholeWord })}
          />
          <KButton
            className="k-editor-search-panel__all"
            variant="ghost"
            disabled={!query.valid}
            onClick={() => selectMatches(view)}
          >
            {labels.searchAll}
          </KButton>
        </div>
      )}

      {!view.state.readOnly && showReplace && (
        <div className="k-editor-search-panel__replace">
          <KInput
            name="replace"
            value={query.replace}
            placeholder={labels.searchReplace}
            aria-label={labels.searchReplace}
            autoComplete="off"
            onChange={(event) => updateQuery({ replace: event.target.value })}
            onKeyDown={(event) => runFromField(event, replaceNext)}
          />
          <KButton
            variant="secondary"
            disabled={!query.valid}
            onClick={() => replaceNext(view)}
          >
            {labels.searchReplace}
          </KButton>
          <KButton
            variant="ghost"
            disabled={!query.valid}
            onClick={() => replaceAll(view)}
          >
            {labels.searchReplaceAll}
          </KButton>
        </div>
      )}
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
