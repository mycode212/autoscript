import { Activity, CalendarDays, CheckCircle2, Copy, Database, Globe, LocateFixed, ShieldCheck, User } from "lucide-react"
import { useState } from "react"

import type { AccountSummary } from "@/types/portal"

import { ThemeMenu } from "@/components/theme/theme-menu"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { activeIpHint, daysLabel, nextAction, protocolLabel, statusVariant } from "@/lib/portal"

export function HeroCard({ summary }: { summary: AccountSummary }) {
  const [copied, setCopied] = useState(false)
  const action = nextAction(summary)
  const problemTitle =
    summary.status === "blocked" ? "Akun diblokir" : summary.status === "expired" ? "Masa aktif habis" : ""

  const handleCopy = (text: string) => {
    void navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <Card className="relative overflow-hidden border-border/70 bg-gradient-to-br from-card via-card/95 to-card/90 p-5 shadow-lg backdrop-blur-xl sm:p-6 lg:p-7">
      {/* Ambient background glow */}
      <div className="pointer-events-none absolute -right-20 -top-20 size-72 rounded-full bg-primary/10 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-20 -left-20 size-72 rounded-full bg-indigo-500/10 blur-3xl" />

      {/* Top bar header */}
      <div className="relative mb-6 flex flex-wrap items-center justify-between gap-3 border-b border-border/60 pb-4">
        <div className="flex items-center gap-2.5">
          <div className="flex size-8 items-center justify-center rounded-xl bg-primary/15 text-primary ring-1 ring-primary/30">
            <ShieldCheck className="size-4" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-extrabold uppercase tracking-widest text-primary">ArjunaCloud</span>
              <span className="text-xs text-muted-foreground/60">•</span>
              <span className="text-xs font-medium text-muted-foreground">User Portal</span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 rounded-full border border-emerald-500/30 bg-emerald-500/10 px-3 py-1 text-xs font-semibold text-emerald-500 dark:text-emerald-400">
            <span className="relative flex size-2">
              <span className="absolute inline-flex size-full animate-ping rounded-full bg-emerald-400 opacity-75" />
              <span className="relative inline-flex size-2 rounded-full bg-emerald-500" />
            </span>
            Live Telemetry
          </div>
          <ThemeMenu />
        </div>
      </div>

      {/* Main hero content */}
      <div className="relative grid min-w-0 gap-6 lg:grid-cols-[1fr_auto] lg:items-center">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:gap-5">
          {/* Avatar Icon */}
          <div className="relative flex size-16 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-primary/20 via-primary/10 to-transparent ring-1 ring-primary/30 shadow-inner sm:size-20">
            <User className="size-8 text-primary sm:size-10" />
            <span className="absolute -bottom-1 -right-1 flex size-5 items-center justify-center rounded-full bg-background ring-2 ring-border">
              <span className="size-2.5 rounded-full bg-emerald-500" />
            </span>
          </div>

          {/* User info & badges */}
          <div className="min-w-0 space-y-2">
            <div className="flex flex-wrap items-center gap-2.5">
              <h1 className="text-2xl font-black tracking-tight text-foreground sm:text-3xl lg:text-4xl">
                {summary.username}
              </h1>
              <Button
                variant="ghost"
                size="sm"
                className="size-8 rounded-lg p-0 text-muted-foreground hover:bg-primary/10 hover:text-primary"
                onClick={() => handleCopy(summary.username)}
                title="Salin Username"
              >
                {copied ? <CheckCircle2 className="size-4 text-emerald-500" /> : <Copy className="size-4" />}
              </Button>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <Badge variant="accent" className="border-primary/40 bg-primary/15 font-mono text-[11px] font-bold tracking-wider text-primary">
                {protocolLabel(summary.protocol)}
              </Badge>
              <Badge variant={statusVariant(summary.status)} className="font-mono text-[11px] font-bold tracking-wider">
                ● {summary.status.toUpperCase()}
              </Badge>
              <span className="text-xs text-muted-foreground">
                Expired: <span className="font-semibold text-foreground">{summary.valid_until}</span>
              </span>
            </div>
          </div>
        </div>

        {/* Quick KPI stats badges on right */}
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:gap-3.5">
          <div className="rounded-xl border border-border/70 bg-card/60 p-3.5 backdrop-blur-sm transition-all hover:border-primary/40 hover:bg-card">
            <div className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-muted-foreground">
              <CalendarDays className="size-3.5 text-primary" />
              Masa Aktif
            </div>
            <div className="mt-1 text-lg font-black tracking-tight text-foreground sm:text-xl">
              {daysLabel(summary.days_remaining)}
            </div>
            <div className="text-[11px] text-muted-foreground">Sisa hari aktif</div>
          </div>

          <div className="rounded-xl border border-border/70 bg-card/60 p-3.5 backdrop-blur-sm transition-all hover:border-primary/40 hover:bg-card">
            <div className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-muted-foreground">
              <LocateFixed className="size-3.5 text-cyan-400" />
              IP Terhubung
            </div>
            <div className="mt-1 font-mono text-sm font-bold tracking-tight text-foreground sm:text-base">
              {summary.active_ip || "Offline"}
            </div>
            <div className="truncate text-[11px] text-muted-foreground">{activeIpHint(summary)}</div>
          </div>

          <div className="col-span-2 rounded-xl border border-border/70 bg-card/60 p-3.5 backdrop-blur-sm transition-all hover:border-primary/40 hover:bg-card sm:col-span-1">
            <div className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-muted-foreground">
              <Database className="size-3.5 text-emerald-400" />
              Sisa Kuota
            </div>
            <div className="mt-1 font-mono text-base font-bold tracking-tight text-foreground sm:text-lg">
              {summary.quota_remaining}
            </div>
            <div className="text-[11px] text-muted-foreground">Dari {summary.quota_limit}</div>
          </div>
        </div>
      </div>

      {/* Action / Warning Notice */}
      {action.text ? (
        <div
          className={`mt-4 rounded-xl border px-3.5 py-2.5 text-xs font-semibold ${
            action.tone === "destructive"
              ? "border-rose-500/30 bg-rose-500/10 text-rose-500"
              : "border-amber-500/30 bg-amber-500/10 text-amber-500"
          }`}
        >
          {action.text}
        </div>
      ) : null}

      {problemTitle ? (
        <div className="mt-4 rounded-xl border border-amber-500/30 bg-amber-500/10 p-3.5 text-xs text-amber-500">
          <p className="font-bold">{problemTitle}</p>
          <p>{summary.status === "blocked" ? "Akses akun dibatasi sampai status dipulihkan." : "Akun tidak bisa dipakai sampai diperpanjang."}</p>
        </div>
      ) : null}
    </Card>
  )
}
