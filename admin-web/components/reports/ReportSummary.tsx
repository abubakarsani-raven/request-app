"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface ReportSummaryProps {
  summary: any;
}

function formatKey(key: string): string {
  return key
    .replace(/([A-Z])/g, " $1")
    .replace(/^./, (str) => str.toUpperCase())
    .trim();
}

export function ReportSummary({ summary }: ReportSummaryProps) {
  if (!summary) return null;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Summary Statistics</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {Object.entries(summary).map(([key, value]) => (
            <div key={key} className="space-y-2">
              <div className="text-sm font-medium text-muted-foreground">
                {formatKey(key)}
              </div>
              {typeof value === "object" && value !== null ? (
                <div className="flex flex-wrap gap-2">
                  {Object.entries(value as Record<string, any>).map(([subKey, subValue]) => (
                    <Badge key={subKey} variant="secondary" className="text-sm">
                      {subKey}: {subValue}
                    </Badge>
                  ))}
                </div>
              ) : (
                <div className="text-2xl font-bold">{String(value)}</div>
              )}
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
