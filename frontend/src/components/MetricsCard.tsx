import React from 'react';

interface MetricsCardProps {
  title: string;
  value: string;
  color: string;
}

export default function MetricsCard({ title, value, color }: MetricsCardProps) {
  return (
    <div style={{
      border: '1px solid #e5e7eb',
      borderRadius: 8,
      padding: 20,
      backgroundColor: 'white',
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
    }}>
      <div style={{ fontSize: 14, color: '#6b7280', marginBottom: 8 }}>{title}</div>
      <div style={{ fontSize: 28, fontWeight: 600, color }}>{value}</div>
    </div>
  );
}
