import { useState } from "react";
import {
  KButton,
  KCombobox,
  KField,
  KSelect,
  KStack,
} from "@k-design-system/ui";

export default { title: "Forms/Select/Form contract" };
const options = [
  { value: "", label: "Choose" },
  { value: "de", label: "Germany" },
  { value: "fr", label: "France" },
];
export function NativeForm() {
  const [controlled, setControlled] = useState("de");
  const [changes, setChanges] = useState(0);
  const [submitted, setSubmitted] = useState("");
  return (
    <form
      id="select-contract"
      onChange={() => setChanges((count) => count + 1)}
      onSubmit={(event) => {
        event.preventDefault();
        setSubmitted(
          JSON.stringify(Object.fromEntries(new FormData(event.currentTarget))),
        );
      }}
    >
      <KStack>
        <KField label="Country" required>
          <KSelect name="country" options={options} defaultValue="" />
        </KField>
        <KField label="Controlled">
          <KSelect
            name="controlled"
            options={options}
            value={controlled}
            defaultValue="de"
            onValueChange={setControlled}
          />
        </KField>
        <KField label="Search">
          <KCombobox name="search" options={options} defaultValue="fr" />
        </KField>
        <KField label="Disabled">
          <KSelect
            name="disabled"
            options={options}
            defaultValue="fr"
            disabled
          />
        </KField>
        <KButton type="submit">Submit</KButton>
        <KButton type="reset">Reset</KButton>
        <output aria-label="Changes">{changes}</output>
        <output aria-label="Submitted">{submitted}</output>
      </KStack>
    </form>
  );
}
