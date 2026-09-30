import { lazy, Suspense, useEffect } from "react"
import { AlertTriangle, RefreshCw } from "lucide-react"
import { useParams } from "react-router-dom"

import { CredentialsCard } from "@/components/portal/credentials-card"
import { HeroCard } from "@/components/portal/hero-card"
import { ImportLinksCard } from "@/components/portal/import-links-card"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent } from "@/components/ui/card"
import { useMediaQuery } from "@/hooks/use-media-query"
import { useAccountSummary, useAccountTraffic } from "@/hooks/use-portal-data"

const TrafficCard = lazy(() =>
  import("@/components/portal/traffic-card").then((module) => ({
    default: module.TrafficCard,
  })),
)

export function AccountRoute() {
  const { token } = useParams<{ token: string }>()
  const mobile = useMediaQuery("(max-width: 720px)")
  const summary = useAccountSummary(token)
  const traffic = useAccountTraffic(token, mobile)

  useEffect(() => {
    if (!summary.data) {
      document.title = "Info Akun"
      return
    }
    document.title = `${summary.data.username} | Info Akun`
  }, [summary.data])

  if (!token) {
    return (
      <Card className="border-slate-800 bg-slate-900/80 p-8 text-center text-white shadow-2xl">
        <CardContent>
          <p className="text-lg font-semibold">Token portal tidak ditemukan.</p>
        </CardContent>
      </Card>
    )
  }

  if (summary.loading && !summary.data) {
    return (
      <Card className="border-slate-800 bg-slate-900/80 p-12 text-center text-slate-400 shadow-2xl">
        <CardContent className="flex items-center justify-center gap-3">
          <RefreshCw className="size-5 animate-spin text-cyan-400" />
          <span>Memuat info akun portal...</span>
        </CardContent>
      </Card>
    )
  }

  if (!summary.data) {
    return (
      <Card className="border-slate-800 bg-slate-900/80 p-8 text-center text-rose-400 shadow-2xl">
        <CardContent className="flex items-center justify-center gap-3">
          <AlertTriangle className="size-5" />
          <span>{summary.error ?? "Portal akun tidak ditemukan."}</span>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="grid min-w-0 gap-6">
      {(summary.stale || traffic.stale) && (
        <Badge variant="outline" className="w-fit border-amber-500/40 bg-amber-950/40 px-3 py-1.5 font-sans text-xs text-amber-300">
          Menampilkan data terakhir. Koneksi API sedang tertunda.
        </Badge>
      )}

      {/* Hero Brand & 4-KPI Metric Row */}
      <HeroCard summary={summary.data} />

      {/* Main 2-Column Dashboard Grid */}
      <section className="grid min-w-0 grid-cols-1 gap-6 lg:grid-cols-12 lg:items-start">
        {/* Left Column (7 cols on desktop): Traffic Chart + Import Links */}
        <div className="space-y-6 lg:col-span-7">
          <Suspense
            fallback={
              <Card className="border-slate-800 bg-slate-900/80 p-8 text-slate-400">
                <CardContent>Memuat grafik traffic realtime...</CardContent>
              </Card>
            }
          >
            <TrafficCard traffic={traffic.data} mobile={mobile} loading={traffic.loading} error={traffic.error} />
          </Suspense>

          <ImportLinksCard summary={summary.data} />
        </div>

        {/* Right Column (5 cols on desktop): Unified Credentials & Server Access */}
        <div className="space-y-6 lg:col-span-5">
          <CredentialsCard summary={summary.data} />
        </div>
      </section>
    </div>
  )
}
