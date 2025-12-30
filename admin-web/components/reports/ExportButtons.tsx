"use client";

import { Button } from "@/components/ui/button";
import { FileSpreadsheet, FileText } from "lucide-react";

interface ExportButtonsProps {
  onExportExcel: () => void;
  onExportPDF: () => void;
  disabled?: boolean;
}

export function ExportButtons({ onExportExcel, onExportPDF, disabled }: ExportButtonsProps) {
  return (
    <div className="flex gap-2">
      <Button onClick={onExportExcel} disabled={disabled}>
        <FileSpreadsheet className="mr-2 h-4 w-4" />
        Export Excel
      </Button>
      <Button onClick={onExportPDF} disabled={disabled} variant="outline">
        <FileText className="mr-2 h-4 w-4" />
        Export PDF
      </Button>
    </div>
  );
}
