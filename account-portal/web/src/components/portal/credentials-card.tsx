import { Check, ChevronDown, Copy, Eye, EyeOff, Globe, Key, Lock, Network, User } from "lucide-react"
import { useEffect, useState } from "react"

import type { AccountSummary } from "@/types/portal"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { useMediaQuery } from "@/hooks/use-media-query"

export function CredentialsCard({ summary }: { summary: AccountSummary }) {
  const [visible, setVisible] = useState(false)
  const [copiedUser, setCopiedUser] = useState(false)
  const [copiedPass, setCopiedPass] = useState(false)
  const [copiedDomain, setCopiedDomain] = useState(false)
  const [open, setOpen] = useState(false)
  const mobile = useMediaQuery("(max-width: 720px)")

  const portDetails = summary.access_details.filter((item) => !item.label.includes("Path") && !item.label.includes("Service"))

  useEffect(() => {
    setVisible(false)
  }, [summary.token, summary.credentials_available, summary.credentials_password])

  const handleCopyUser = () => {
    void navigator.clipboard.writeText(summary.credentials_username)
    setCopiedUser(true)
    setTimeout(() => setCopiedUser(false), 2000)
  }

  const handleCopyPass = () => {
    void navigator.clipboard.writeText(summary.credentials_password)
    setCopiedPass(true)
    setTimeout(() => setCopiedPass(false), 2000)
  }

  const handleCopyDomain = () => {
    void navigator.clipboard.writeText(summary.access_domain)
    setCopiedDomain(true)
    setTimeout(() => setCopiedDomain(false), 2000)
  }

  return (
    <Card className="border-slate-800 bg-slate-900/80 shadow-2xl backdrop-blur-2xl">
      <CardHeader className="border-b border-slate-800/80 pb-4">
        <CardTitle className="inline-flex items-center gap-2.5 text-base font-bold text-white">
          <div className="flex size-7 items-center justify-center rounded-lg bg-cyan-500/10 text-cyan-400 ring-1 ring-cyan-500/20">
            <Key className="size-4" />
          </div>
          Kredensial & Akses Server
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4 p-5 sm:p-6">
        {/* Username */}
        {summary.credentials_available ? (
          <>
            <div className="rounded-xl border border-slate-800 bg-slate-950/60 p-3.5 backdrop-blur-md">
              <div className="mb-1.5 flex items-center justify-between gap-3">
                <span className="inline-flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  <User className="size-3.5 text-cyan-400" />
                  Username
                </span>
                <Button variant="ghost" size="sm" className="h-6 gap-1 rounded-md px-2 text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-cyan-300" onClick={handleCopyUser}>
                  {copiedUser ? <Check className="size-3 text-emerald-400" /> : <Copy className="size-3" />}
                  {copiedUser ? "Tersalin" : "Copy"}
                </Button>
              </div>
              <p className="break-all font-mono text-sm font-bold text-white">{summary.credentials_username}</p>
            </div>

            {/* Password */}
            <div className="rounded-xl border border-slate-800 bg-slate-950/60 p-3.5 backdrop-blur-md">
              <div className="mb-1.5 flex items-center justify-between gap-3">
                <span className="inline-flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  <Lock className="size-3.5 text-cyan-400" />
                  Password
                </span>
                <div className="flex items-center gap-1">
                  <Button variant="ghost" size="sm" className="size-6 rounded-md p-0 text-slate-400 hover:text-white" onClick={() => setVisible((c) => !c)}>
                    {visible ? <EyeOff className="size-3.5" /> : <Eye className="size-3.5" />}
                  </Button>
                  <Button variant="ghost" size="sm" className="h-6 gap-1 rounded-md px-2 text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-cyan-300" onClick={handleCopyPass}>
                    {copiedPass ? <Check className="size-3 text-emerald-400" /> : <Copy className="size-3" />}
                    {copiedPass ? "Tersalin" : "Copy"}
                  </Button>
                </div>
              </div>
              <p className="break-all font-mono text-sm font-bold text-white">
                {visible ? summary.credentials_password : "••••••••••••"}
              </p>
            </div>
          </>
        ) : null}

        {/* Server Domain */}
        <div className="rounded-xl border border-slate-800 bg-slate-950/60 p-3.5 backdrop-blur-md">
          <div className="mb-1.5 flex items-center justify-between gap-3">
            <span className="inline-flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-slate-400">
              <Globe className="size-3.5 text-cyan-400" />
              Domain / Host Server
            </span>
            <Button variant="ghost" size="sm" className="h-6 gap-1 rounded-md px-2 text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-cyan-300" onClick={handleCopyDomain}>
              {copiedDomain ? <Check className="size-3 text-emerald-400" /> : <Copy className="size-3" />}
              {copiedDomain ? "Tersalin" : "Copy"}
            </Button>
          </div>
          <p className="break-all font-mono text-sm font-bold text-cyan-300">{summary.access_domain}</p>
        </div>

        {/* Port Details Dialog Modal */}
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button
              variant="outline"
              className="h-10 w-full justify-between rounded-xl border-slate-800 bg-slate-950/80 px-4 text-xs font-semibold text-slate-200 hover:border-cyan-500/40 hover:bg-slate-800"
            >
              <span className="inline-flex items-center gap-2">
                <Network className="size-3.5 text-cyan-400" />
                Lihat Detail Port & Path Akses
              </span>
              <ChevronDown className={`size-4 transition-transform duration-200 ${open ? "rotate-180" : ""}`} />
            </Button>
          </DialogTrigger>
          <DialogContent mobileSheet={mobile} className="border-slate-800 bg-slate-950 text-white max-w-lg">
            <DialogHeader>
              <DialogTitle className="inline-flex items-center gap-2 text-sm font-bold uppercase tracking-wider text-cyan-400">
                <Network className="size-4" />
                Port Service & Path Akses
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-3 pt-2">
              <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-3.5">
                <span className="text-[11px] font-bold uppercase text-slate-400">Domain Host</span>
                <p className="mt-1 font-mono text-sm font-bold text-cyan-300">{summary.access_domain}</p>
              </div>

              <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-3.5">
                <span className="text-[11px] font-bold uppercase text-slate-400">Daftar Port Terbuka</span>
                <div className="mt-2 space-y-2">
                  {portDetails.length > 0 ? (
                    portDetails.map((item) => (
                      <div key={`${item.label}-${item.value}`} className="flex items-center justify-between border-b border-slate-800/60 pb-1.5 last:border-b-0 last:pb-0">
                        <span className="text-xs text-slate-300">{item.label}</span>
                        <span className="font-mono text-xs font-bold text-cyan-400">{item.value}</span>
                      </div>
                    ))
                  ) : (
                    <p className="font-mono text-xs text-slate-300">{summary.access_ports || "-"}</p>
                  )}
                </div>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      </CardContent>
    </Card>
  )
}
