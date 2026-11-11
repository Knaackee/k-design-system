import { createContext, type ReactNode } from "react";

export const KIconStrokeTokenContext = createContext("--k-size-icon-stroke");

/** Internal chat composition scope; the public icon API stays unchanged. */
export function KChatIconProvider({ children }: { children: ReactNode }) {
  return (
    <KIconStrokeTokenContext.Provider value="--k-component-chat-icon-stroke">
      {children}
    </KIconStrokeTokenContext.Provider>
  );
}
