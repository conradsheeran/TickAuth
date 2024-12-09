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

import { scanBarcode, scanCore } from "@kit.ScanKit";
import { Logger, ProcessSecret, SecretParams } from "utils";
import { Constants } from "../common/Constants"
import { hilog } from "@kit.PerformanceAnalysisKit";

const logger = new Logger(getContext(this))
const TAG: string = "CatchSecretByScan"

export async function CatchSecretByScan(context: Context): Promise<SecretParams> {
  hilog.info(Constants.DOMAIN, TAG, "CatchSecretByScan Start")

  let options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],
    enableMultiMode: true,
    enableAlbum: true
  };
  hilog.debug(Constants.DOMAIN, TAG, "ScanOption: %{public}s", String(options))

  try {
    const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(context, options);
    const params = ProcessSecret(result.originalValue);
    hilog.debug(Constants.DOMAIN, TAG,
      "ScanResult(hasProcess): issuer: %{public}s, secret: %{private}s, algorithm: %{public}s, digits: %{public}d, period: %{public}d, ",
      params.issuer, params.secret, params.algorithm, params.digits, params.period)

    logger.info(Constants.DOMAIN, TAG, "CatchSecretByScan Succeed")
    return params;
  } catch (e) {
    logger.error(Constants.DOMAIN, TAG, "CatchSecretByScan Fatal: %{public}s", String(e))
    throw new Error(`CatchSecretByScan: ${e}`);
  }
}
