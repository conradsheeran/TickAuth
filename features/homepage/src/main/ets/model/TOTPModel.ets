export class SecretClass {
  alias: string = "";
  secret: string = "";

  constructor(alias: string, secret: string) {
    this.alias = alias;
    this.secret = secret;
  }
}