"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

interface StatCardProps {
  title: string;
  value: number | string;
  isLoading?: boolean;
  variant?: "default" | "success" | "warning" | "danger";
  subtitle?: string;
}

export function StatCard({
  title,
  value,
  isLoading,
  variant = "default",
  subtitle,
}: StatCardProps) {
  const variantStyles = {
    default: "text-foreground",
    success: "text-green-600",
    warning: "text-orange-600",
    danger: "text-red-600",
  };

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-8 w-16" />
        ) : (
          <>
            <div className={cn("text-3xl font-bold", variantStyles[variant])}>
              {value}
            </div>
            {subtitle && (
              <div className="text-xs text-muted-foreground mt-1">{subtitle}</div>
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
}
