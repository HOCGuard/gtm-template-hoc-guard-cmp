___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (the "Gallery Developer
Terms of Service") and to the Apache License, Version 2.0, included with this
template in the LICENSE file.


___INFO___

{
  "type": "TAG",
  "id": "cvt_hoc_guard_consent",
  "version": 1,
  "securityGroups": [],
  "displayName": "HOC Guard CMP",
  "brand": {
    "id": "brand_hoc_guard",
    "displayName": "HOC Guard"
  },
  "description": "Sets the Google consent mode default state, loads the HOC Guard consent banner and updates ad_storage, ad_user_data, ad_personalization and analytics_storage based on the visitor's choice.",
  "containerContexts": [
    "WEB"
  ],
  "categories": [
    "UTILITY",
    "ANALYTICS",
    "ADVERTISING"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "bannerId",
    "displayName": "Banner ID (ULID)",
    "simpleValueType": true,
    "help": "ID of the banner configured in the HOC Guard console (the data-banner-id value).",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "apiBase",
    "displayName": "HOC Guard base URL",
    "simpleValueType": true,
    "defaultValue": "https://guard.hoc.app.br",
    "help": "Origin that serves the SDK (/sdk/banner.js) and the public API. No trailing slash. Keep the default unless HOC Guard support tells you otherwise.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "waitForUpdate",
    "displayName": "Wait for update (ms)",
    "simpleValueType": true,
    "defaultValue": 500,
    "help": "How long Google tags wait for a consent update before sending data (wait_for_update). Recommended: 500.",
    "valueValidators": [
      {
        "type": "POSITIVE_NUMBER"
      }
    ]
  },
  {
    "type": "CHECKBOX",
    "name": "adsDataRedaction",
    "checkboxText": "Redact ads data when ad_storage is denied (ads_data_redaction)",
    "simpleValueType": true,
    "defaultValue": true
  },
  {
    "type": "CHECKBOX",
    "name": "urlPassthrough",
    "checkboxText": "Pass ad click information through URLs (url_passthrough)",
    "simpleValueType": true,
    "defaultValue": false
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "regionDefaults",
    "displayName": "Default consent state by region (optional)",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Regions (ISO 3166-1/2 codes, comma separated)",
        "name": "regions",
        "type": "TEXT"
      },
      {
        "defaultValue": "denied",
        "displayName": "Default state",
        "name": "defaultState",
        "type": "SELECT",
        "selectItems": [
          {
            "value": "denied",
            "displayValue": "denied"
          },
          {
            "value": "granted",
            "displayValue": "granted"
          }
        ]
      }
    ],
    "help": "Overrides the global default only in the listed regions. Leave empty to apply the denied default everywhere."
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// HOC Guard CMP: Google Tag Manager custom template.
//
// Flow (fire on "Consent Initialization - All Pages"):
//   1. setDefaultConsentState: everything denied, security_storage granted.
//   2. (optional) regional defaults overriding the global one.
//   3. gtagSet: developer_id, ads_data_redaction, url_passthrough.
//   4. injects the HOC Guard SDK (banner.js) in GTM mode.
//   5. registers a listener; when the visitor decides, the SDK hands over
//      the computed signals and the template calls updateConsentState.

const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const gtagSet = require('gtagSet');
const injectScript = require('injectScript');
const setInWindow = require('setInWindow');
const callInWindow = require('callInWindow');
const makeNumber = require('makeNumber');
const logToConsole = require('logToConsole');

const waitForUpdate = makeNumber(data.waitForUpdate) || 500;

// 1. Default global conservador (alinhado a GDPR/LGPD).
setDefaultConsentState({
  ad_storage: 'denied',
  ad_user_data: 'denied',
  ad_personalization: 'denied',
  analytics_storage: 'denied',
  functionality_storage: 'denied',
  personalization_storage: 'denied',
  security_storage: 'granted',
  wait_for_update: waitForUpdate
});

// 2. Defaults por regiao (sobrepoem o global apenas nas regioes listadas).
const regionDefaults = data.regionDefaults || [];
for (let i = 0; i < regionDefaults.length; i++) {
  const row = regionDefaults[i];
  if (!row || !row.regions) continue;
  const regions = row.regions.split(',').map((r) => r.trim()).filter((r) => r.length > 0);
  if (regions.length === 0) continue;
  const granted = row.defaultState === 'granted';
  const state = granted ? 'granted' : 'denied';
  setDefaultConsentState({
    ad_storage: state,
    ad_user_data: state,
    ad_personalization: state,
    analytics_storage: state,
    functionality_storage: state,
    personalization_storage: state,
    security_storage: 'granted',
    region: regions,
    wait_for_update: waitForUpdate
  });
}

// 3. Identificacao da CMP (developer ID do CMP Partner Program) e
//    parametros auxiliares do Consent Mode. gtagSet recebe um objeto.
gtagSet({
  'developer_id.dZmY0Mz': true,
  'ads_data_redaction': data.adsDataRedaction ? true : false,
  'url_passthrough': data.urlPassthrough ? true : false
});

// 4. Passa a config pro SDK e liga o modo GTM (o SDK nao emite gtag direto).
setInWindow('HOCGuardSettings', {
  bannerId: data.bannerId,
  apiBase: data.apiBase,
  mode: 'gtm'
}, true);

// 5. Listener: recebe os sinais ja calculados e atualiza o consentimento.
const onConsent = (payload) => {
  if (!payload || !payload.signals) {
    return;
  }
  updateConsentState(payload.signals);
};

// 6. Injeta o SDK; apos carregar, registra o listener. O bridge faz replay
//    da ultima decisao, entao a ordem (carga assincrona x registro) nao gera
//    race condition.
const sdkUrl = data.apiBase + '/sdk/banner.js';

const onSuccess = () => {
  callInWindow('HOCGuardGtm.onConsent', onConsent);
  data.gtmOnSuccess();
};

const onFailure = () => {
  logToConsole('HOC Guard CMP: failed to load the SDK from ' + sdkUrl);
  data.gtmOnFailure();
};

injectScript(sdkUrl, onSuccess, onFailure, sdkUrl);


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_user_data" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_personalization" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "analytics_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "functionality_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "personalization_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "security_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "write_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "developer_id.dZmY0Mz"
              },
              {
                "type": 1,
                "string": "ads_data_redaction"
              },
              {
                "type": 1,
                "string": "url_passthrough"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "inject_script",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://guard.hoc.app.br/sdk/banner.js"
              },
              {
                "type": 1,
                "string": "https://*.hoc.app.br/sdk/banner.js"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "HOCGuardSettings" },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "HOCGuardGtm.onConsent" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___NOTES___

HOC Guard CMP template.

Mapping from HOC Guard purposes to Google consent mode types:
  - necessary   -> security_storage
  - analytics   -> analytics_storage
  - marketing   -> ad_storage, ad_user_data, ad_personalization
  - functional  -> functionality_storage
  - preferences -> personalization_storage
