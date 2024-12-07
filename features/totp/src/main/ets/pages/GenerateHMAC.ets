import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';
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

export async function GenerateHMAC(secret: string, macAlgName: string, updateSecret?: string) {
  hilog.info(Constants.DOMAIN, TAG, "GenerateHMAC Start")

  let keyData = new Uint8Array(buffer.from("12345678abcdefgh", 'utf-8').buffer);

  let key = await generateSymKeyByData(keyData);
  hilog.debug(Constants.DOMAIN, TAG, "GenerateSymKey Succeed")

  let mac = cryptoFramework.createMac(macAlgName);
  await mac.init(key);
  hilog.debug(Constants.DOMAIN, TAG, "Mac Init Succeed")

  await mac.update({ data: new Uint8Array(buffer.from(secret, 'utf-8').buffer) });
  hilog.debug(Constants.DOMAIN, TAG, "Mac Crypto Succeed")

  if (updateSecret != undefined) {
    const HMACUpdateData = updateSecret;
    await mac.update({ data: new Uint8Array(buffer.from(HMACUpdateData, 'utf-8').buffer) });
    hilog.debug(Constants.DOMAIN, TAG, "Mac Update Succeed")
  }

  let macResult = await mac.doFinal();
  hilog.info(Constants.DOMAIN, TAG, "GenerateHMAC Succeed")

  return macResult.data;
}