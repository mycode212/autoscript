import { Check, ChevronDown, Copy, Globe2, Link2, Network } from "lucide-react"
import { useState } from "react"

import type { AccountSummary } from "@/types/portal"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { useMediaQuery } from "@/hooks/use-media-query"

export function AccessCard({ summary }: { summary: AccountSummary }) {
  const [open, setOpen] = useState(false)
  const [copied, setCopied] = useState(false)
  const mobile = useMediaQuery("(max-width: 720px)")
  const portDetails = summary.access_details.filter((item) => !item.label.includes("Path") && !item.label.includes("Service"))
  const pathDetails = summary.access_details.filter((item) => item.label.includes("Path") || item.label.includes("Service"))

  const handleCopyDomain = () => {
    void navigator.clipboard.writeText(summary.access_domain)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <Card className="lg:col-span-2">
      <CardHeader className="pb-3">
        <CardTitle className="inline-flex items-center gap-2">
          <Globe2 className="size-4 text-primary" />
          Info Akses Server
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="rounded-xl border border-border/70 bg-card/60 p-3.5 backdrop-blur-sm">
          <div className="mb-2 flex items-center justify-between gap-3">
            <span className="inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-muted-foreground">
              <Globe2 className="size-3.5 text-primary" />
              Domain / Host
            </span>
            <Button variant="secondary" size="sm" className="h-7 gap-1.5 rounded-lg px-2.5 text-xs" onClick={handleCopyDomain}>
              {copied ? <Check className="size-3 text-emerald-500" /> : <Copy className="size-3" />}
              {copied ? "Tersalin" : "Copy"}
            </Button>
          </div>
          <p className="break-all font-mono text-sm font-bold text-foreground sm:text-base">{summary.access_domain}</p>
        </div>

        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button variant="secondary" className="h-9 w-full justify-between rounded-xl px-4 text-xs font-semibold sm:h-10 sm:text-sm">
              <span>Lihat Detail Port & Path Akses</span>
              <ChevronDown className={`size-4 transition-transform duration-200 ${open ? "rotate-180" : ""}`} />
            </Button>
          </DialogTrigger>
          <DialogContent mobileSheet={mobile} className={mobile ? "gap-4" : "max-w-[44rem] gap-5"}>
            {mobile ? <div className="mx-auto h-1.5 w-12 rounded-full bg-border/80" /> : null}
            <DialogHeader>
              <DialogTitle className="inline-flex items-center gap-2 text-sm font-bold uppercase tracking-wider text-muted-foreground">
                <Globe2 className="size-4 text-primary" />
                Detail Port & Path Akses
              </DialogTitle>
            </DialogHeader>
            <div className="grid max-h-[calc(80svh-6rem)] gap-4 overflow-y-auto pr-1">
              <section className="rounded-xl border border-border/70 bg-card/60 p-4">
                <p className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
                  <Globe2 className="size-3.5 text-primary" />
                  Domain Server
                </p>
                <p className="mt-2 break-all font-mono text-sm font-bold text-foreground">{summary.access_domain}</p>
              </section>
              <section className="rounded-xl border border-border/70 bg-card/60 p-4">
                <p className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
                  <Network className="size-3.5 text-primary" />
                  Port Service
                </p>
                <div className="mt-3 grid gap-2.5">
                  {portDetails.length > 0 ? (
                    portDetails.map((item) => (
                      <div key={`${item.label}-${item.value}`} className="flex items-center justify-between border-b border-border/50 pb-2 last:border-b-0 last:pb-0">
                        <span className="text-xs text-muted-foreground">{item.label}</span>
                        <span className="font-mono text-xs font-bold text-foreground">{item.value}</span>
                      </div>
                    ))
                  ) : (
                    <p className="font-mono text-sm font-semibold text-foreground">{summary.access_ports || "-"}</p>
                  )}
                </div>
              </section>
              {pathDetails.length > 0 && (
                <section className="rounded-xl border border-border/70 bg-card/60 p-4">
                  <p className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
                    <Link2 className="size-3.5 text-primary" />
                    Path & Service
                  </p>
                  <div className="mt-3 grid gap-2.5">
                    {pathDetails.map((item) => (
                      <div key={`${item.label}-${item.value}`} className="flex items-center justify-between border-b border-border/50 pb-2 last:border-b-0 last:pb-0">
                        <span className="text-xs text-muted-foreground">{item.label}</span>
                        <span className="font-mono text-xs font-bold text-foreground">{item.value}</span>
                      </div>
                    ))}
                  </div>
                </section>
              )}
            </div>
          </DialogContent>
        </Dialog>
      </CardContent>
    </Card>
  )
}
