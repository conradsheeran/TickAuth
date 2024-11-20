import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';
import { Logger } from 'utils';

const TAG: string = "UserAuth";
const logger = new Logger(getContext(this))

export function UserAuth(): Promise<number> {
  return new Promise<number>((resolve, reject) => {
    try {
      const authParam: userAuth.AuthParam = {
        challenge: cryptoFramework.createRandom()?.generateRandomSync(16)?.data,
        authType: [
          userAuth.UserAuthType.PIN,
          userAuth.UserAuthType.FACE,
          userAuth.UserAuthType.FINGERPRINT,
        ],
        authTrustLevel: userAuth.AuthTrustLevel.ATL2,
      };
      const widgetParam: userAuth.WidgetParam = {
        title: String($r('app.string.UserAuth_title')),
      };
      const userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);

      userAuthInstance.on('result', {
        onResult(result) {
          if (result.result !== 12500000) {
            hilog.debug(Constants.DOMAIN, TAG, "Authentication Successful")
          } else {
            hilog.debug(Constants.DOMAIN, TAG, "Authentication Failed: %{public}d", result.result)
          }
          userAuthInstance.off('result');
          resolve(result.result);
        },
      });

      userAuthInstance.start();
    } catch (e) {
      logger.fatal(Constants.DOMAIN, TAG, "Authentication FATAL: %{public}d", e?.code);
      reject(e);
    }
  });
}
