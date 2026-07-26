declare module "split-type" {
  export type SplitTypeTarget = string | Element | Element[] | NodeList | HTMLCollection;

  export type SplitTypeResult = {
    chars: HTMLElement[];
    words: HTMLElement[];
    lines: HTMLElement[];
    revert: () => void;
  };

  export default class SplitType {
    chars: HTMLElement[];
    words: HTMLElement[];
    lines: HTMLElement[];
    constructor(target: SplitTypeTarget, options?: { types?: string; tagName?: string });
    revert(): void;
    static revert(target: SplitTypeTarget): void;
  }
}
