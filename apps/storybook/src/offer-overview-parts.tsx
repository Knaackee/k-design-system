import {
  KButton,
  KIcon,
  KMenuButton,
  KBadge,
  KSidebar,
  KSidebarItem,
  type KIconName,
  type KMenuAction,
} from "@k-design-system/ui";
import markUrl from "./offer-overview-mark.svg";
import type { CSSProperties } from "react";
import {
  euro,
  type OfferItem,
  type OfferCategory,
} from "./offer-overview-data.js";

export function OfferThumb({
  item,
  category,
}: {
  item: OfferItem;
  category: OfferCategory;
}) {
  return (
    <span
      className="of-thumb"
      style={{
        background: item.image
          ? `linear-gradient(140deg,${item.image.join(",")})`
          : category.color,
      }}
    >
      {item.image ? null : item.name[0]}
    </span>
  );
}
export function OfferRow({
  item,
  category,
  onEdit,
  onRestore,
  actions,
}: {
  item: OfferItem;
  category: OfferCategory;
  onEdit: () => void;
  onRestore: () => void;
  actions: KMenuAction[];
}) {
  const stock = item.stock ?? 0;
  return (
    <div
      className="of-item"
      data-offer-item={item.id}
      data-offer-category-id={category.id}
      data-archived={item.archived || undefined}
    >
      <KButton
        variant="ghost"
        fullWidth
        className="of-item-button"
        onClick={onEdit}
      >
        <span className="of-item-layout">
          <OfferThumb item={item} category={category} />
          <span className="of-item-copy">
            <b title={item.name}>{item.name}</b>
            <small>
              <span className="of-meta">
                <KIcon
                  name={item.kind === "product" ? "package" : "clock"}
                  size={16}
                />
                <span
                  className={
                    item.kind === "product"
                      ? stock === 0
                        ? "of-soldout"
                        : stock <= 3
                          ? "of-low"
                          : ""
                      : ""
                  }
                >
                  {item.kind === "product"
                    ? stock === 0
                      ? "Ausverkauft"
                      : stock <= 3
                        ? `Nur noch ${stock}`
                        : `${stock} verfügbar`
                    : item.duration! % 60 === 0
                      ? `${item.duration! / 60} Std`
                      : `${item.duration} Min`}
                </span>
              </span>
              {item.hidden && (
                <KBadge variant="destructive" className="of-badge">
                  Nicht buchbar
                </KBadge>
              )}
              {item.featured && (
                <KBadge variant="secondary" className="of-badge of-badge-brand">
                  Hervorgehoben
                </KBadge>
              )}
              {item.options && (
                <KBadge variant="secondary" className="of-badge">
                  + Optionen
                </KBadge>
              )}
              {item.draft && (
                <KBadge variant="warning" className="of-badge">
                  Neu
                </KBadge>
              )}
            </small>
          </span>
          <span className="of-price">
            {item.priceKind === "request" ? (
              <small>Auf Anfrage</small>
            ) : (
              <>
                {item.priceKind === "from" && <small>ab </small>}
                {euro(item.price)}
              </>
            )}
          </span>
        </span>
      </KButton>
      {item.archived ? (
        <KButton
          className="of-restore"
          variant="secondary"
          onClick={onRestore}
          aria-label={`${item.name} wiederherstellen`}
        >
          <KIcon name="undo-2" size={16} />
          <span>Wiederherstellen</span>
        </KButton>
      ) : (
        <div className="of-row-end">
          <span className="of-row-chevron">
            <KIcon name="chevron-right" size={20} />
          </span>
          <KMenuButton
            label={`Aktionen für ${item.name}`}
            overflow
            triggerClassName="of-small-button"
            actions={actions}
          />
        </div>
      )}
    </div>
  );
}

const navigation: {
  label: string;
  icon: KIconName;
  color?: string;
  active?: boolean;
}[] = [
  { label: "Heute", icon: "house" },
  { label: "Kalender", icon: "calendar" },
  { label: "Posteingang", icon: "inbox" },
  { label: "Verwaltung", icon: "briefcase", active: true },
  { label: "Einstellungen", icon: "settings" },
  { label: "Kund:innen", icon: "users", color: "#0c679f" },
  { label: "Angebot", icon: "store", color: "#7c3aed", active: true },
  { label: "Buchungsseite & QR", icon: "qr-code", color: "#0891b2" },
  { label: "Standorte & Zeiten", icon: "clock", color: "#16a34a" },
];
export function OfferNavigation({
  notify,
}: {
  notify: (message: string) => void;
}) {
  return (
    <>
      <KSidebar mode="expanded" className="of-sidebar" label="Hauptnavigation">
        <div className="of-logo">
          <img src={markUrl} alt="" width={26} height={32} />
          <b>
            onzeit<span>.</span>
          </b>
        </div>
        <nav aria-label="Hauptnavigation">
          {navigation.map((n, i) => (
            <div key={n.label} className={i === 5 ? "of-nav-divider" : ""}>
              <KSidebarItem
                label={n.label}
                active={n.active}
                leading={
                  <span
                    className="of-nav-icon"
                    data-colored={!!n.color}
                    style={{ "--of-icon-color": n.color } as CSSProperties}
                  >
                    <KIcon name={n.icon} size={n.color ? 15 : 19} />
                  </span>
                }
                onSelect={() =>
                  notify(
                    n.label === "Angebot"
                      ? "Du bist bereits im Angebot."
                      : `${n.label}: Navigationsziel in der Anwendung`,
                  )
                }
              />
            </div>
          ))}
        </nav>
        <div className="of-profile">
          <span>DK</span>
          <div>
            <b>Denis Knaack</b>
            <small>Profil & Konto</small>
          </div>
        </div>
      </KSidebar>
      <nav className="of-mobile-nav" aria-label="Hauptnavigation">
        {navigation.slice(0, 5).map((n) => (
          <KButton
            key={n.label}
            variant="ghost"
            className="of-bottom-link"
            aria-current={n.active ? "page" : undefined}
            onClick={() =>
              notify(`${n.label}: Navigationsziel in der Anwendung`)
            }
          >
            <span>
              <KIcon name={n.icon} size={20} />
              <small>{n.label}</small>
            </span>
          </KButton>
        ))}
      </nav>
    </>
  );
}
