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
