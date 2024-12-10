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

import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';

const TAG: string = "GenerateHMAC"

async function generateSymKeyByData(symKeyData: Uint8Array) {
  let symKeyBlob: cryptoFramework.DataBlob = { data: symKeyData };
  let aesGenerator = cryptoFramework.createSymKeyGenerator('HMAC');
  let symKey = await aesGenerator.convertKey(symKeyBlob);
  hilog.info(Constants.DOMAIN, TAG, "GenerateSymKey Succeed")

  return symKey;
}

export async function GenerateHMAC(secret: ArrayBuffer, message: ArrayBuffer, macAlgName: string) {
  hilog.info(Constants.DOMAIN, TAG, "GenerateHMAC Start")

  let keyData = new Uint8Array(secret);
  let key = await generateSymKeyByData(keyData);
  hilog.debug(Constants.DOMAIN, TAG, "GenerateSymKey Succeed")

  let mac = cryptoFramework.createMac(macAlgName);
  await mac.init(key);
  hilog.debug(Constants.DOMAIN, TAG, "Mac Init Succeed")
  await mac.update({ data: new Uint8Array(message) });
  hilog.debug(Constants.DOMAIN, TAG, "Mac Crypto Succeed")
  let macResult = await mac.doFinal();
  hilog.info(Constants.DOMAIN, TAG, "GenerateHMAC Succeed")

  return macResult.data;
}