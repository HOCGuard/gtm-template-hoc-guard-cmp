# HOC Guard CMP: Google Tag Manager template

Google Tag Manager custom template for the [HOC Guard](https://guard.hoc.app.br) Consent Management Platform. It connects the HOC Guard consent banner to [Google consent mode](https://developers.google.com/tag-platform/security/guides/consent) without any code on the page.

## What it does

1. Sets the consent mode default state before any Google tag fires: everything denied, `security_storage` granted, with `wait_for_update` (500 ms by default).
2. Applies regional defaults when configured.
3. Sets `ads_data_redaction` and `url_passthrough` according to the tag settings.
4. Loads the HOC Guard banner.
5. Sends a consent update every time the visitor makes or changes a choice.

## Consent types

| HOC Guard purpose | Consent mode types |
|---|---|
| Necessary | `security_storage` |
| Analytics | `analytics_storage` |
| Marketing | `ad_storage`, `ad_user_data`, `ad_personalization` |
| Functional | `functionality_storage` |
| Preferences | `personalization_storage` |

## Setup

1. In Google Tag Manager, open **Templates**, choose **Search Gallery** and add **HOC Guard CMP**.
2. Create a new tag using the template.
3. Fill in the **Banner ID** shown in the HOC Guard console.
4. Use the trigger **Consent Initialization - All Pages**.
5. Save and publish the container.

## Fields

| Field | Required | Default | Notes |
|---|---|---|---|
| Banner ID | yes | | From the HOC Guard console |
| HOC Guard base URL | yes | `https://guard.hoc.app.br` | Keep the default |
| Wait for update (ms) | no | 500 | `wait_for_update` |
| Redact ads data | no | on | `ads_data_redaction` |
| Pass ad click information through URLs | no | off | `url_passthrough` |
| Default consent state by region | no | | ISO 3166 codes, comma separated |

## Support

Questions about consent signals on Google tags start with HOC Guard support: open an issue in this repository.

## License

Apache 2.0. See [LICENSE](./LICENSE).
