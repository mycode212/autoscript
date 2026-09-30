import { CalendarDays, Check, Copy, Database, Network, ShieldCheck, User } from "lucide-react"
import { useState } from "react"

import type { AccountSummary } from "@/types/portal"

import { ThemeMenu } from "@/components/theme/theme-menu"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { daysLabel, nextAction, protocolLabel, quotaPercent, statusVariant } from "@/lib/portal"

export function HeroCard({ summary }: { summary: AccountSummary }) {
  const [copied, setCopied] = useState(false)
  const action = nextAction(summary)
  const percent = quotaPercent(summary)

  const handleCopy = (text: string) => {
    void navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <Card className="relative overflow-hidden border border-slate-800 bg-slate-900/80 p-5 shadow-2xl backdrop-blur-2xl sm:p-6 lg:p-7">
      {/* Ambient glowing radial lights */}
      <div className="pointer-events-none absolute -right-20 -top-20 size-80 rounded-full bg-cyan-500/10 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-20 -left-20 size-80 rounded-full bg-indigo-500/10 blur-3xl" />

      {/* Top Brand Bar */}
      <div className="relative mb-6 flex flex-wrap items-center justify-between gap-3 border-b border-slate-800/80 pb-4">
        <div className="flex items-center gap-3">
          <div className="flex size-9 items-center justify-center rounded-xl bg-gradient-to-tr from-cyan-500 to-blue-600 shadow-lg shadow-cyan-500/25">
            <ShieldCheck className="size-5 text-slate-950 font-bold" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-sm font-black tracking-wider text-white">ARJUNACLOUD</span>
              <span className="rounded-md bg-cyan-500/10 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-cyan-400 ring-1 ring-cyan-500/20">
                USER PORTAL
              </span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 rounded-full border border-emerald-500/30 bg-emerald-950/40 px-3 py-1 text-xs font-semibold text-emerald-400">
            <span className="relative flex size-2">
              <span className="absolute inline-flex size-full animate-ping rounded-full bg-emerald-400 opacity-75" />
              <span className="relative inline-flex size-2 rounded-full bg-emerald-500" />
            </span>
            Live Telemetry
          </div>
          <ThemeMenu />
        </div>
      </div>

      {/* User Identity Info */}
      <div className="relative mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-4">
          <div className="relative flex size-14 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-b from-slate-800 to-slate-950 ring-1 ring-white/10 shadow-xl sm:size-16">
            <User className="size-7 text-cyan-400 sm:size-8" />
            <span className="absolute -bottom-0.5 -right-0.5 flex size-4 items-center justify-center rounded-full bg-slate-900 ring-2 ring-slate-950">
              <span className="size-2 rounded-full bg-emerald-400 animate-pulse" />
            </span>
          </div>

          <div className="min-w-0 space-y-1.5">
            <div className="flex items-center gap-2.5">
              <h1 className="text-2xl font-black tracking-tight text-white sm:text-3xl">
                {summary.username}
              </h1>
              <Button
                variant="outline"
                size="sm"
                className="h-7 border-slate-700 bg-slate-800/80 px-2 text-xs font-semibold text-slate-300 hover:border-cyan-500 hover:bg-cyan-950/40 hover:text-cyan-300"
                onClick={() => handleCopy(summary.username)}
              >
                {copied ? <Check className="mr-1 size-3 text-emerald-400" /> : <Copy className="mr-1 size-3" />}
                {copied ? "Tersalin" : "Salin"}
              </Button>
            </div>

            <div className="flex flex-wrap items-center gap-2 text-xs">
              <Badge variant="outline" className="border-cyan-500/30 bg-cyan-950/40 font-mono text-[11px] font-bold text-cyan-300">
                {protocolLabel(summary.protocol)}
              </Badge>
              <Badge variant={statusVariant(summary.status)} className="font-mono text-[11px] font-bold uppercase tracking-wider">
                ● {summary.status}
              </Badge>
              <span className="text-slate-400">
                Berlaku s/d <span className="font-mono font-bold text-slate-200">{summary.valid_until}</span>
              </span>
            </div>
          </div>
        </div>

        {/* Warning / Notice Banner if near expiry */}
        {action.text ? (
          <div
            className={`rounded-xl border px-3.5 py-2 text-xs font-semibold ${
              action.tone === "destructive"
                ? "border-rose-500/40 bg-rose-950/40 text-rose-300"
                : "border-amber-500/40 bg-amber-950/40 text-amber-300"
            }`}
          >
            {action.text}
          </div>
        ) : null}
      </div>

      {/* 4-KPI Metric Cards Row */}
      <div className="relative grid grid-cols-2 gap-3 sm:grid-cols-2 lg:grid-cols-4 lg:gap-4">
        {/* Metric 1: Masa Aktif */}
        <div className="rounded-2xl border border-slate-800/90 bg-slate-950/60 p-4 backdrop-blur-md transition-all hover:border-cyan-500/30">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Masa Aktif</span>
            <div className="flex size-7 items-center justify-center rounded-lg bg-cyan-500/10 text-cyan-400">
              <CalendarDays className="size-4" />
            </div>
          </div>
          <div className="mt-2 text-xl font-black text-white sm:text-2xl">
            {daysLabel(summary.days_remaining)}
          </div>
          <div className="mt-1 text-xs text-slate-400">
            {summary.valid_until}
          </div>
        </div>

        {/* Metric 2: Sisa Kuota */}
        <div className="rounded-2xl border border-slate-800/90 bg-slate-950/60 p-4 backdrop-blur-md transition-all hover:border-emerald-500/30">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Sisa Kuota</span>
            <div className="flex size-7 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-400">
              <Database className="size-4" />
            </div>
          </div>
          <div className="mt-2 text-xl font-black text-white sm:text-2xl">
            {summary.quota_remaining}
          </div>
          <div className="mt-1 flex items-center justify-between text-xs text-slate-400">
            <span>Limit: {summary.quota_limit}</span>
            <span className="font-mono text-emerald-400">{percent}%</span>
          </div>
          <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-slate-800">
            <div
              className="h-full bg-gradient-to-r from-emerald-500 to-cyan-500 transition-all duration-500"
              style={{ width: `${Math.min(100, percent)}%` }}
            />
          </div>
        </div>

        {/* Metric 3: IP Terhubung */}
        <div className="rounded-2xl border border-slate-800/90 bg-slate-950/60 p-4 backdrop-blur-md transition-all hover:border-cyan-500/30">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">IP Terhubung</span>
            <div className="flex size-7 items-center justify-center rounded-lg bg-blue-500/10 text-blue-400">
              <Network className="size-4" />
            </div>
          </div>
          <div className="mt-2 font-mono text-base font-bold text-white sm:text-lg truncate">
            {summary.active_ip || "Offline"}
          </div>
          <div className="mt-1 text-xs text-slate-400">
            {summary.active_ip ? "Sedang aktif digunakan" : "Belum terhubung"}
          </div>
        </div>

        {/* Metric 4: Limit Proteksi */}
        <div className="rounded-2xl border border-slate-800/90 bg-slate-950/60 p-4 backdrop-blur-md transition-all hover:border-indigo-500/30">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Multi-Login & Speed</span>
            <div className="flex size-7 items-center justify-center rounded-lg bg-indigo-500/10 text-indigo-400">
              <ShieldCheck className="size-4" />
            </div>
          </div>
          <div className="mt-2 flex items-center gap-2 text-sm font-bold text-white sm:text-base">
            <span className="rounded-md bg-slate-800 px-2 py-0.5 text-xs text-slate-200">
              IP: {summary.limit_ip || "OFF"}
            </span>
            <span className="rounded-md bg-slate-800 px-2 py-0.5 text-xs text-slate-200">
              Speed: {summary.limit_speed || "OFF"}
            </span>
          </div>
          <div className="mt-1 text-xs text-slate-400">
            Sistem proteksi aktif
          </div>
        </div>
      </div>
    </Card>
  )
}
