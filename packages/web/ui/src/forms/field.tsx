import { createContext, useContext, useId, type ReactNode } from "react";

const FieldContext = createContext<{
  id?: string;
  description?: string;
  invalid?: boolean;
  required?: boolean;
}>({});
export function useField() {
  return useContext(FieldContext);
}
export interface KFieldProps {
  /** Plain text or a composed label (for example optional/required emphasis). */
  label: ReactNode;
  helperText?: string;
  errorText?: string;
  required?: boolean;
  children: ReactNode;
}
export function KField({
  label,
  helperText,
  errorText,
  required = false,
  children,
}: KFieldProps) {
  const id = useId();
  const description = errorText || helperText;
  return (
    <FieldContext.Provider
      value={{
        id,
        description: description ? `${id}-description` : undefined,
        invalid: !!errorText,
        required,
      }}
    >
      <div className="k-field">
        <label className="k-field__label" htmlFor={id}>
          {label}
          {required ? " *" : ""}
        </label>
        {children}
        {description && (
          <span
            className={`k-field__description${errorText ? " k-field__error" : ""}`}
            id={`${id}-description`}
          >
            {description}
          </span>
        )}
      </div>
    </FieldContext.Provider>
  );
}
