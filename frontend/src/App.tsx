import React, { useEffect, useState } from 'react';
import MetricsCard from './components/MetricsCard';
import BuildsTable from './components/BuildsTable';

type Metrics = {
  successRate: number;
  failureRate: number;
  avgBuildTimeSeconds: number;
  lastBuild: any;
};

type Build = {
  id: number;
  tool: string;
  repo?: string;
  branch?: string;
  status?: string;
  conclusion?: string;
  duration_seconds?: number;
  url?: string;
  started_at?: string;
  completed_at?: string;
};

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000';

export default function App() {
  const [metrics, setMetrics] = useState<Metrics | null>(null);
  const [builds, setBuilds] = useState<Build[]>([]);
  const [loading, setLoading] = useState(true);

  async function fetchData() {
    try {
      const [mRes, bRes] = await Promise.all([
        fetch(`${API_BASE}/api/metrics`),
        fetch(`${API_BASE}/api/builds?limit=50`),
      ]);
      const [m, b] = await Promise.all([mRes.json(), bRes.json()]);
      setMetrics(m);
      setBuilds(b);
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 15000);
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div style={{ padding: 20, textAlign: 'center' }}>
        <h2>Loading CI/CD Dashboard...</h2>
      </div>
    );
  }

  return (
    <div style={{ fontFamily: 'system-ui, sans-serif', padding: 20, maxWidth: 1200, margin: '0 auto' }}>
      <h1 style={{ color: '#333', marginBottom: 30 }}>CI/CD Health Dashboard</h1>
      
      {metrics && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 20, marginBottom: 30 }}>
          <MetricsCard title="Success Rate" value={`${Math.round(metrics.successRate * 100)}%`} color="#10b981" />
          <MetricsCard title="Failure Rate" value={`${Math.round(metrics.failureRate * 100)}%`} color="#ef4444" />
          <MetricsCard title="Avg Build Time" value={`${Math.round(metrics.avgBuildTimeSeconds)}s`} color="#3b82f6" />
          <MetricsCard 
            title="Last Build" 
            value={metrics.lastBuild ? `${metrics.lastBuild.status}/${metrics.lastBuild.conclusion}` : '—'} 
            color="#6b7280" 
          />
        </div>
      )}

      <BuildsTable builds={builds} />
    </div>
  );
}
