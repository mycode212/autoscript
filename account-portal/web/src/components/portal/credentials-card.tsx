import { Check, Copy, Eye, EyeOff, Key, Lock, User } from "lucide-react"
import { useEffect, useState } from "react"

import type { AccountSummary } from "@/types/portal"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

export function CredentialsCard({ summary }: { summary: AccountSummary }) {
  const [visible, setVisible] = useState(false)
  const [copiedUser, setCopiedUser] = useState(false)
  const [copiedPass, setCopiedPass] = useState(false)

  useEffect(() => {
    setVisible(false)
  }, [summary.token, summary.credentials_available, summary.credentials_password])

  if (!summary.credentials_available) return null

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

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="inline-flex items-center gap-2">
          <Key className="size-4 text-primary" />
          Kredensial Akun
        </CardTitle>
      </CardHeader>
      <CardContent className="grid gap-3">
        <div className="rounded-xl border border-border/70 bg-card/60 p-3.5 backdrop-blur-sm transition-all hover:bg-card">
          <div className="mb-2 flex items-center justify-between gap-3">
            <span className="inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-muted-foreground">
              <User className="size-3.5 text-primary" />
              Username
            </span>
            <Button variant="secondary" size="sm" className="h-7 gap-1.5 rounded-lg px-2.5 text-xs" onClick={handleCopyUser}>
              {copiedUser ? <Check className="size-3 text-emerald-500" /> : <Copy className="size-3" />}
              {copiedUser ? "Tersalin" : "Copy"}
            </Button>
          </div>
          <p className="break-all font-mono text-sm font-bold text-foreground sm:text-base">{summary.credentials_username}</p>
        </div>

        <div className="rounded-xl border border-border/70 bg-card/60 p-3.5 backdrop-blur-sm transition-all hover:bg-card">
          <div className="mb-2 flex items-center justify-between gap-3">
            <span className="inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-muted-foreground">
              <Lock className="size-3.5 text-primary" />
              Password
            </span>
            <div className="flex gap-1.5">
              <Button variant="ghost" size="sm" className="size-7 rounded-lg p-0" onClick={() => setVisible((current) => !current)}>
                {visible ? <EyeOff className="size-3.5" /> : <Eye className="size-3.5" />}
              </Button>
              <Button variant="secondary" size="sm" className="h-7 gap-1.5 rounded-lg px-2.5 text-xs" onClick={handleCopyPass}>
                {copiedPass ? <Check className="size-3 text-emerald-500" /> : <Copy className="size-3" />}
                {copiedPass ? "Tersalin" : "Copy"}
              </Button>
            </div>
          </div>
          <p className="break-all font-mono text-sm font-bold text-foreground sm:text-base">
            {visible ? summary.credentials_password : "••••••••••••"}
          </p>
        </div>
      </CardContent>
    </Card>
  )
}
