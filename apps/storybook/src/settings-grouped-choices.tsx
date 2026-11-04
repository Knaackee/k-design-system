import { KButton } from "@k-design-system/ui";
export function Choices({
  items,
  value,
  onChange,
}: {
  items: string[];
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="sg-choice-bar">
      {items.map((item) => (
        <KButton
          key={item}
          variant={value === item ? "secondary" : "ghost"}
          aria-pressed={value === item}
          onClick={() => onChange(item)}
        >
          {item}
        </KButton>
      ))}
    </div>
  );
}
