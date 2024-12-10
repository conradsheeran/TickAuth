/*
 * Copyright (c) 2024 Yang He
 *
 * TickAuth is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import { JSON, util } from "@kit.ArkTS"

// Consider using @ohos.url
export interface SecretParams {
  secret: string;
  algorithm: string;
  digits: number;
  period: number;
  issuer: string;
}

export function ProcessSecret(input: string, issuer: string = ""): SecretParams {
  const params: SecretParams = {
    secret: "",
    algorithm: "SHA1",
    digits: 6,
    period: 30,
    issuer: issuer
  };

  if (input.indexOf('secret=') !== -1) {
    const queryParams = input.match(/[?&]([^=]+)=([^&]*)/g);

    if (queryParams) {
      queryParams.forEach(param => {
        const keyValue = param.slice(1).split('=');
        const key = keyValue[0];
        const value = decodeURIComponent(keyValue[1]);

        if (key === 'secret') {
          params.secret = value;
        } else if (key === 'issuer') {
          params.issuer = value;
        } else if (key === 'algorithm') {
          params.algorithm = value;
        } else if (key === 'digits') {
          params.digits = parseInt(value);
        } else if (key === 'period') {
          params.period = parseInt(value);
        }
      });
    }
  } else {
    params.secret = input.replace(/\s+/g, '');
  }

  return params;
}


export function SecretParamsToUint8Array(params: SecretParams): Uint8Array {
  const jsonString = JSON.stringify(params);
  const encoder = new util.TextEncoder();
  return encoder.encodeInto(jsonString);
}

export function Uint8ArrayToSecretParams(data: Uint8Array): SecretParams {
  const decoder = new util.TextDecoder();
  const jsonString = decoder.decodeToString(data);
  return JSON.parse(jsonString) as SecretParams;
}
