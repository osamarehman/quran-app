import { useEffect, useState } from 'react';
import { initDatabases } from '../db/database';

export function useDatabaseInit() {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function setup() {
      try {
        console.log('[DB] starting initDatabases');
        await initDatabases();
        console.log('[DB] initDatabases done');
        if (!cancelled) setReady(true);
      } catch (e) {
        console.log('[DB] error:', String(e));
        if (!cancelled) setError(e as Error);
      }
    }

    setup();
    return () => { cancelled = true; };
  }, []);

  return { ready, error };
}
