import { useEffect, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KAvatar,
  KImageCropper,
  KStack,
  KText,
  type KImageCropResult,
} from "@k-design-system/ui";

const portrait = new URL("./assets/jordan.png", import.meta.url).href;

function ImageCropperFixture() {
  const [resultUrl, setResultUrl] = useState<string>();
  const [status, setStatus] = useState("Adjust the crop and apply it.");

  useEffect(
    () => () => {
      if (resultUrl) URL.revokeObjectURL(resultUrl);
    },
    [resultUrl],
  );

  const apply = ({ blob }: KImageCropResult) => {
    const nextUrl = URL.createObjectURL(blob);
    setResultUrl((current) => {
      if (current) URL.revokeObjectURL(current);
      return nextUrl;
    });
    setStatus("Square crop exported.");
  };

  return (
    <KStack
      gap="section"
      style={{ width: "min(100%, 32rem)", marginInline: "auto" }}
    >
      <KImageCropper
        src={portrait}
        alt="Jordan Lee"
        onCancel={() => setStatus("Crop cancelled.")}
        onApply={apply}
      />
      <KText role="status">{status}</KText>
      {resultUrl ? (
        <KAvatar src={resultUrl} alt="Exported Jordan Lee crop" size="large" />
      ) : null}
    </KStack>
  );
}

const meta = {
  title: "Data display/Image cropper",
  component: ImageCropperFixture,
  parameters: { fixtureId: "image-cropper-avatar" },
} satisfies Meta<typeof ImageCropperFixture>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Avatar: Story = {};
