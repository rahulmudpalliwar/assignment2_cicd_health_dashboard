import React from 'react';

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

interface BuildsTableProps {
  builds: Build[];
}

export default function BuildsTable({ builds }: BuildsTableProps) {
  const getStatusColor = (conclusion: string) => {
    switch (conclusion) {
      case 'success': return '#10b981';
      case 'failure': return '#ef4444';
      case 'cancelled': return '#f59e0b';
      default: return '#6b7280';
    }
  };

  return (
    <div>
      <h2 style={{ color: '#333', marginBottom: 20 }}>Latest Builds</h2>
      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', backgroundColor: 'white', borderRadius: 8, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
          <thead>
            <tr style={{ backgroundColor: '#f9fafb' }}>
              <Th>Tool</Th>
              <Th>Repo</Th>
              <Th>Branch</Th>
              <Th>Status</Th>
              <Th>Conclusion</Th>
              <Th>Duration</Th>
              <Th>Started</Th>
              <Th>Completed</Th>
              <Th>Link</Th>
            </tr>
          </thead>
          <tbody>
            {builds.map((build) => (
              <tr key={build.id} style={{ borderBottom: '1px solid #f3f4f6' }}>
                <Td>{build.tool}</Td>
                <Td>{build.repo || '—'}</Td>
                <Td>{build.branch || '—'}</Td>
                <Td>{build.status || '—'}</Td>
                <Td>
                  <span style={{
                    padding: '4px 8px',
                    borderRadius: 4,
                    fontSize: 12,
                    fontWeight: 500,
                    backgroundColor: getStatusColor(build.conclusion || '') + '20',
                    color: getStatusColor(build.conclusion || '')
                  }}>
                    {build.conclusion || '—'}
                  </span>
                </Td>
                <Td>{build.duration_seconds ? `${build.duration_seconds}s` : '—'}</Td>
                <Td>{build.started_at ? new Date(build.started_at).toLocaleString() : '—'}</Td>
                <Td>{build.completed_at ? new Date(build.completed_at).toLocaleString() : '—'}</Td>
                <Td>
                  {build.url ? (
                    <a href={build.url} target="_blank" rel="noopener noreferrer" style={{ color: '#3b82f6', textDecoration: 'none' }}>
                      Open
                    </a>
                  ) : '—'}
                </Td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function Th({ children }: { children: React.ReactNode }) {
  return <th style={{ textAlign: 'left', padding: '12px 16px', fontWeight: 600, color: '#374151' }}>{children}</th>;
}

function Td({ children }: { children: React.ReactNode }) {
  return <td style={{ padding: '12px 16px', color: '#374151' }}>{children}</td>;
}
