declare module 'next/navigation' {
  import { ReadonlyURLSearchParams } from 'next/navigation';

  export function useRouter(): {
    push(href: string): void;
    replace(href: string): void;
    prefetch(href: string): void;
    back(): void;
    forward(): void;
    refresh(): void;
  };

  export function usePathname(): string;

  export function useSearchParams(): ReadonlyURLSearchParams;

  export function useParams(): Record<string, string | string[] | undefined>;

  export function notFound(): never;

  export function redirect(url: string): never;
}
