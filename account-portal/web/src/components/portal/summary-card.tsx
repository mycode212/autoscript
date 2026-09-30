import { CalendarClock, CalendarDays, FileText, Gauge, LocateFixed, Shield } from "lucide-react"
import type * as React from "react"

import type { AccountSummary } from "@/types/portal"

import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { activeIpHint, daysLabel, protocolLabel, statusVariant } from "@/lib/portal"

function Item({ label, value, note, icon }: { label: string; value: string; note?: string; icon?: React.ReactNode }) {
  return (
    <div className="flex items-start justify-between gap-3 border-b border-border/50 py-2.5 last:border-0 last:pb-0">
      <dt className="inline-flex items-center gap-2 text-xs font-semibold text-muted-foreground">
        <span className="text-primary">{icon}</span>
        {label}
      </dt>
      <div className="text-right">
        <dd className="font-mono text-sm font-bold text-foreground sm:text-base">{value}</dd>
        {note ? <p className="text-[11px] text-muted-foreground">{note}</p> : null}
      </div>
    </div>
  )
}

export function SummaryCard({ summary }: { summary: AccountSummary }) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-3">
        <CardTitle className="inline-flex items-center gap-2">
          <FileText className="size-4 text-primary" />
          Ringkasan Akun
        </CardTitle>
        <div className="flex gap-2">
          <Badge variant="accent" className="font-mono text-[10px] uppercase">{protocolLabel(summary.protocol)}</Badge>
          <Badge variant={statusVariant(summary.status)} className="font-mono text-[10px] uppercase">{summary.status}</Badge>
        </div>
      </CardHeader>
      <CardContent>
        <dl className="grid">
          <Item label="Berlaku Sampai" value={summary.valid_until} icon={<CalendarClock className="size-4" />} />
          <Item label="Masa Aktif" value={daysLabel(summary.days_remaining)} icon={<CalendarDays className="size-4" />} />
          <Item label="Limit IP" value={summary.ip_limit_text} icon={<Shield className="size-4" />} />
          <Item label="Limit Speed" value={summary.speed_limit_text} icon={<Gauge className="size-4" />} />
          <Item label="IP Aktif" value={summary.active_ip} note={activeIpHint(summary)} icon={<LocateFixed className="size-4" />} />
        </dl>
      </CardContent>
    </Card>
  )
}
