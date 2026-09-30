import { Database } from "lucide-react"

import type { AccountSummary } from "@/types/portal"

import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { quotaPercent } from "@/lib/portal"

export function QuotaCard({ summary }: { summary: AccountSummary }) {
  const percent = quotaPercent(summary)
  const tone = percent >= 90 ? "destructive" : percent >= 60 ? "warning" : "success"
  const label = percent >= 90 ? "Hampir Habis" : percent >= 60 ? "Perlu Dipantau" : "Aman"

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-3">
        <CardTitle className="inline-flex items-center gap-2">
          <Database className="size-4 text-primary" />
          Penggunaan Kuota
        </CardTitle>
        <div className="flex gap-2">
          <Badge variant="accent" className="font-mono text-[10px]">{percent}%</Badge>
          <Badge variant={tone} className="font-mono text-[10px]">{label}</Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Progress bar */}
        <div className="space-y-1.5">
          <div className="flex justify-between text-[11px] font-semibold text-muted-foreground">
            <span>Progress Penggunaan</span>
            <span className="font-mono text-foreground">{percent}% dari {summary.quota_limit}</span>
          </div>
          <div className="h-2.5 overflow-hidden rounded-full bg-secondary/80 p-0.5">
            <div
              className={`h-full rounded-full transition-all duration-500 ${
                percent >= 90
                  ? "bg-rose-500 shadow-[0_0_12px_rgba(244,63,94,0.5)]"
                  : percent >= 60
                    ? "bg-amber-500 shadow-[0_0_12px_rgba(245,158,11,0.5)]"
                    : "bg-gradient-to-r from-cyan-500 to-emerald-400 shadow-[0_0_12px_rgba(6,182,212,0.4)]"
              }`}
              style={{ width: `${Math.min(100, Math.max(2, percent))}%` }}
            />
          </div>
        </div>

        {/* Stats grid */}
        <div className="grid grid-cols-3 gap-2 sm:gap-3">
          <div className="rounded-xl border border-border/60 bg-card/60 p-3 text-center transition-all hover:bg-card">
            <dt className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Limit
            </dt>
            <dd className="mt-1 font-mono text-xs font-black tracking-tight text-foreground sm:text-sm">{summary.quota_limit}</dd>
          </div>
          <div className="rounded-xl border border-border/60 bg-card/60 p-3 text-center transition-all hover:bg-card">
            <dt className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Terpakai
            </dt>
            <dd className="mt-1 font-mono text-xs font-black tracking-tight text-amber-500 dark:text-amber-400 sm:text-sm">{summary.quota_used}</dd>
          </div>
          <div className="rounded-xl border border-border/60 bg-card/60 p-3 text-center transition-all hover:bg-card">
            <dt className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Sisa
            </dt>
            <dd className="mt-1 font-mono text-xs font-black tracking-tight text-emerald-500 dark:text-emerald-400 sm:text-sm">{summary.quota_remaining}</dd>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
