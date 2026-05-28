// Finnhub live market data client
// Replace VITE_FINNHUB_API_KEY in .env with your key from finnhub.io (free tier: 60 req/min)

const API_KEY = import.meta.env.VITE_FINNHUB_API_KEY || '';
const BASE_URL = 'https://finnhub.io/api/v1';

export interface FinnhubQuote {
  c: number;  // current price
  d: number;  // change
  dp: number; // change percent
  h: number;  // high
  l: number;  // low
  o: number;  // open
  pc: number; // prev close
  v?: number; // volume (not in quote endpoint)
}

export interface FinnhubProfile {
  name: string;
  ticker: string;
  exchange: string;
  marketCapitalization: number;
  shareOutstanding: number;
}

export async function fetchQuote(symbol: string): Promise<FinnhubQuote | null> {
  if (!API_KEY) return null;
  try {
    const res = await fetch(`${BASE_URL}/quote?symbol=${symbol}&token=${API_KEY}`);
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  }
}

export async function fetchQuotes(symbols: string[]): Promise<Record<string, FinnhubQuote>> {
  if (!API_KEY) return {};
  // Batch with slight delay to avoid rate limit
  const results: Record<string, FinnhubQuote> = {};
  const chunks = [];
  for (let i = 0; i < symbols.length; i += 10) {
    chunks.push(symbols.slice(i, i + 10));
  }
  for (const chunk of chunks) {
    await Promise.all(chunk.map(async (sym) => {
      const q = await fetchQuote(sym);
      if (q && q.c > 0) results[sym] = q;
    }));
    if (chunks.length > 1) await new Promise(r => setTimeout(r, 200));
  }
  return results;
}

// WebSocket for real-time trades (Finnhub free tier supports this)
export class FinnhubWebSocket {
  private ws: WebSocket | null = null;
  private subscribers = new Map<string, Set<(price: number) => void>>();
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private connected = false;

  constructor(private apiKey: string) {}

  private connect() {
    if (!this.apiKey) return;
    try {
      this.ws = new WebSocket(`wss://ws.finnhub.io?token=${this.apiKey}`);

      this.ws.onopen = () => {
        this.connected = true;
        // Re-subscribe to all active symbols
        this.subscribers.forEach((_, symbol) => {
          this.ws?.send(JSON.stringify({ type: 'subscribe', symbol }));
        });
      };

      this.ws.onmessage = (e) => {
        try {
          const data = JSON.parse(e.data);
          if (data.type === 'trade' && data.data) {
            data.data.forEach((trade: { s: string; p: number }) => {
              const cbs = this.subscribers.get(trade.s);
              if (cbs) cbs.forEach(cb => cb(trade.p));
            });
          }
        } catch { /* ignore parse errors */ }
      };

      this.ws.onclose = () => {
        this.connected = false;
        this.reconnectTimer = setTimeout(() => this.connect(), 5000);
      };

      this.ws.onerror = () => {
        this.ws?.close();
      };
    } catch { /* ignore */ }
  }

  subscribe(symbol: string, callback: (price: number) => void) {
    if (!this.subscribers.has(symbol)) {
      this.subscribers.set(symbol, new Set());
      if (this.connected) {
        this.ws?.send(JSON.stringify({ type: 'subscribe', symbol }));
      }
    }
    this.subscribers.get(symbol)!.add(callback);

    if (!this.ws || this.ws.readyState === WebSocket.CLOSED) {
      this.connect();
    }
  }

  unsubscribe(symbol: string, callback: (price: number) => void) {
    const cbs = this.subscribers.get(symbol);
    if (cbs) {
      cbs.delete(callback);
      if (cbs.size === 0) {
        this.subscribers.delete(symbol);
        if (this.connected) {
          this.ws?.send(JSON.stringify({ type: 'unsubscribe', symbol }));
        }
      }
    }
  }

  destroy() {
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.ws?.close();
  }
}

export const finnhubWS = new FinnhubWebSocket(API_KEY);

export function hasApiKey(): boolean {
  return !!API_KEY && API_KEY.length > 10;
}
