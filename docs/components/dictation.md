# Dictation controls

`KInput` and `KTextarea` accept an optional `trailingAction` (`ReactNode` on Web,
`Widget` on Flutter). Input places it at the end beside the clear control;
Textarea reserves a bottom row and places it at the bottom right. These slots
are intended for one icon action. Disabled and read-only fields hide the action;
password / concealed inputs also hide it.

`KDictationAction` is exported on both platforms. It takes a `KDictationState`,
a required accessible `label`, and an optional `onPressed` callback. Consumers
supply localized labels appropriate to the state, such as “Start dictation”,
“Stop dictation”, “Transcribing”, or “Retry dictation”.

| State         | Visual                    | Activation        |
| ------------- | ------------------------- | ----------------- |
| `ready`       | Microphone                | Consumer callback |
| `recording`   | Stop, selected appearance | Consumer callback |
| `processing`  | Progress                  | Disabled          |
| `unavailable` | Microphone off            | Disabled          |
| `error`       | Alert                     | Consumer callback |

No callback also disables the action. The action uses existing icon-button
semantics, keyboard support, focus appearance and token-defined hit targets.
Web uses the button's existing loading spinner while Flutter uses a static
progress icon. Neither platform starts a microphone, requests permission,
transcribes, edits text, or interprets errors. The host owns all those behaviors
and any status/error text associated with the field.

Matching galleries use fixture ID `dictation-controls` under Forms/Dictation.
