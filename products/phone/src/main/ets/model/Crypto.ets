import { huks } from '@kit.UniversalKeystoreKit';

export class Crypto {
  private AESKeyAlias: string;
  private handle: number | undefined;
  private IV: Uint8Array
  private plainText: Uint8Array | undefined;
  private cipherData: Uint8Array | undefined;

  constructor(keyAlias: string, IV: Uint8Array) {
    this.AESKeyAlias = keyAlias;
    this.IV = IV;
  }

  private Uint8ArrayToString(fileData: Uint8Array): string {
    let dataString = '';
    for (let i = 0; i < fileData.length; i++) {
      dataString += String.fromCharCode(fileData[i]);
    }
    return dataString;
  }

  private GetAESGenerateProperties(): Array<huks.HuksParam> {
    return [{
      tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
      value: huks.HuksKeyAlg.HUKS_ALG_AES
    }, {
      tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
      value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_128
    }, {
      tag: huks.HuksTag.HUKS_TAG_PURPOSE,
      value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT |
      huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
    }];
  }

  private GetAESEncryptProperties(): Array<huks.HuksParam> {
    return [{
      tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
      value: huks.HuksKeyAlg.HUKS_ALG_AES
    }, {
      tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
      value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_128
    }, {
      tag: huks.HuksTag.HUKS_TAG_PURPOSE,
      value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT
    }, {
      tag: huks.HuksTag.HUKS_TAG_PADDING,
      value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
    }, {
      tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
      value: huks.HuksCipherMode.HUKS_MODE_CBC
    }, {
      tag: huks.HuksTag.HUKS_TAG_IV,
      value: this.IV
    }];
  }

  private GetAESDecryptProperties(): Array<huks.HuksParam> {
    return [{
      tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
      value: huks.HuksKeyAlg.HUKS_ALG_AES
    }, {
      tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
      value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_128
    }, {
      tag: huks.HuksTag.HUKS_TAG_PURPOSE,
      value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
    }, {
      tag: huks.HuksTag.HUKS_TAG_PADDING,
      value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
    }, {
      tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
      value: huks.HuksCipherMode.HUKS_MODE_CBC
    }, {
      tag: huks.HuksTag.HUKS_TAG_IV,
      value: this.IV
    }];
  }

  async generateKey(): Promise<void> {
    let options: huks.HuksOptions = {
      properties: this.GetAESGenerateProperties()
    };
    await huks.generateKeyItem(this.AESKeyAlias, options).catch((error: Error) => {
        console.error(`Failed to generate AES Key: ${JSON.stringify(error)}`);
      });
  }

  async encrypt(data: Uint8Array): Promise<Uint8Array | undefined> {
    let options: huks.HuksOptions = {
      properties: this.GetAESEncryptProperties(),
      inData: data
    };
    await huks.initSession(this.AESKeyAlias, options)
      .then((data) => {
        this.handle = data.handle;
      }).catch((error: Error) => {
        console.error(`Failed to initialize encryption session: ${JSON.stringify(error)}`);
      });

    if (this.handle !== undefined) {
      await huks.finishSession(this.handle, options)
        .then((data) => {
          this.cipherData = data.outData as Uint8Array;
          console.info(`Encrypted data: ${this.Uint8ArrayToString(this.cipherData)}`);
        }).catch((error: Error) => {
          console.error(`Failed to encrypt data: ${JSON.stringify(error)}`);
        });
    }

    return this.cipherData;
  }

  async decrypt(): Promise<Uint8Array | undefined> {
    if (!this.cipherData) {
      console.error('No cipher data available for decryption.');
      return;
    }

    let options: huks.HuksOptions = {
      properties: this.GetAESDecryptProperties(),
      inData: this.cipherData
    };

    await huks.initSession(this.AESKeyAlias, options)
      .then((data) => {
        this.handle = data.handle;
      }).catch((error: Error) => {
        console.error(`Failed to initialize decryption session: ${JSON.stringify(error)}`);
      });

    if (this.handle !== undefined) {
      await huks.finishSession(this.handle, options)
        .then((data) => {
          this.plainText = data.outData;
          console.info(`Decrypted data: ${this.Uint8ArrayToString(data.outData as Uint8Array)}`);
        }).catch((error: Error) => {
          console.error(`Failed to decrypt data: ${JSON.stringify(error)}`);
        });
    }

    return this.plainText;
  }

  async delete(): Promise<void> {
    let options: huks.HuksOptions = { properties: [] };
    await huks.deleteKeyItem(this.AESKeyAlias, options)
      .then(() => {
        console.info(`Deleted AES Key successfully`);
      }).catch((error: Error) => {
        console.error(`Failed to delete AES Key: ${JSON.stringify(error)}`);
      });
  }
}