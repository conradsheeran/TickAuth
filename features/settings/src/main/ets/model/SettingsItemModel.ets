export class SettingsItemClass {
  symbol: string = ""
  title: string = "";
  content: string = "";

  constructor(symbol: string, title: string, content: string) {
    this.symbol = symbol;
    this.title = title;
    this.content = content;
  }
}