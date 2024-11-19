import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { userAuth } from '@kit.UserAuthenticationKit';

export function UserAuth() {
  try {
    const authParam: userAuth.AuthParam = {
      challenge: cryptoFramework.createRandom()?.generateRandomSync(16)?.data,
      authType: [userAuth.UserAuthType.PIN, userAuth.UserAuthType.FACE, userAuth.UserAuthType.FINGERPRINT],
      authTrustLevel: userAuth.AuthTrustLevel.ATL3,
    };
    const widgetParam: userAuth.WidgetParam = {
      title: String($r('app.string.UserAuth_title')),
    };
    const userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);

    userAuthInstance.on('result', {
      onResult(result) {
        console.info(`userAuthInstance callback result: ${JSON.stringify(result.result)}`);
        userAuthInstance.off('result');
      }
    });
    userAuthInstance.start();
  } catch (e) {
    console.error(`auth catch error. Code is ${e?.code}, message is ${e?.message}`);
  }
}