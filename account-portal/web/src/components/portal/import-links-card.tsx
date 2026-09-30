import { Copy, Download, Link2 } from "lucide-react"
import { useEffect, useState } from "react"

import type { AccountSummary } from "@/types/portal"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

function copy(value: string) {
  void navigator.clipboard.writeText(value)
}

export function ImportLinksCard({ summary }: { summary: AccountSummary }) {
  if (summary.import_links.length === 0) return null

  const defaultValue =
    summary.import_links.find((item) => item.label.toLowerCase() === "websocket")?.label ?? summary.import_links[0]?.label
  const [selectedValue, setSelectedValue] = useState(defaultValue)

  useEffect(() => {
    if (!summary.import_links.some((item) => item.label === selectedValue)) {
      setSelectedValue(defaultValue)
    }
  }, [defaultValue, selectedValue, summary.import_links])

  return (
    <Card className="min-w-0 border-white/10 bg-slate-900/60 shadow-xl backdrop-blur-xl lg:col-span-2">
      <CardHeader className="border-b border-white/5 pb-4">
        <CardTitle className="inline-flex items-center gap-2.5 text-base font-semibold text-white">
          <span className="flex size-7 items-center justify-center rounded-lg bg-cyan-500/10 text-cyan-400 ring-1 ring-cyan-500/20">
            <Link2 className="size-4" />
          </span>
          Link Import & Konfigurasi
        </CardTitle>
      </CardHeader>
      <CardContent className="min-w-0 p-5 sm:p-6">
        <Tabs value={selectedValue} onValueChange={setSelectedValue}>
          <TabsList
            className="w-full justify-start overflow-x-auto overflow-y-hidden border border-white/5 bg-slate-950/60 p-1.5 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
          >
            {summary.import_links.map((item, index) => (
              <TabsTrigger
                key={item.label}
                value={item.label}
                className="flex-none rounded-xl px-4 py-2 text-xs font-semibold text-slate-300 transition-all duration-200 hover:text-white data-[state=active]:bg-gradient-to-r data-[state=active]:from-cyan-500 data-[state=active]:to-blue-600 data-[state=active]:text-white data-[state=active]:shadow-lg data-[state=active]:shadow-cyan-500/20"
                style={{
                  animation: `import-chip-in 420ms cubic-bezier(0.22, 1, 0.36, 1) both`,
                  animationDelay: `${index * 45}ms`,
                }}
              >
                {item.label}
              </TabsTrigger>
            ))}
          </TabsList>
          {summary.import_links.map((item) => (
            <TabsContent key={item.label} value={item.label} className="mt-4 min-w-0">
              <div className="min-w-0 rounded-2xl border border-white/10 bg-slate-950/40 p-4 backdrop-blur-md transition-all sm:p-5">
                <div className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center sm:justify-between">
                  <div className="min-w-0">
                    <p className="inline-flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-cyan-400">
                      <span className="size-1.5 rounded-full bg-cyan-400 animate-pulse" />
                      Mode Terpilih
                    </p>
                    <h3 className="mt-1 text-lg font-bold tracking-tight text-white sm:text-xl">{item.label}</h3>
                  </div>
                  <div className="flex w-full flex-col gap-2 sm:w-auto sm:flex-row">
                    {summary.protocol === "vless" &&
                    summary.xray_json_available &&
                    item.label === "VLESS XHTTP/3 (UDP/QUIC)" ? (
                      <Button
                        asChild
                        variant="outline"
                        className="h-9 w-full border-cyan-500/30 bg-cyan-950/30 text-xs font-medium text-cyan-300 hover:border-cyan-500/50 hover:bg-cyan-900/40 sm:h-10 sm:w-auto sm:text-sm"
                      >
                        <a href={summary.xray_json_url} download>
                          <Download className="mr-2 size-4" />
                          Unduh Xray JSON
                        </a>
                      </Button>
                    ) : null}
                    <Button 
                      className="h-9 w-full bg-cyan-500 text-xs font-semibold text-slate-950 hover:bg-cyan-400 hover:shadow-lg hover:shadow-cyan-500/25 active:scale-95 transition-all sm:h-10 sm:w-auto sm:text-sm" 
                      onClick={() => copy(item.url)}
                    >
                      <Copy className="mr-2 size-4" />
                      Copy Link
                    </Button>
                  </div>
                </div>
                <div className="mt-4 relative group">
                  <p className="max-w-full overflow-hidden rounded-xl border border-white/5 bg-slate-950/80 p-3.5 font-mono text-xs leading-relaxed text-cyan-200/90 [overflow-wrap:anywhere] sm:p-4 sm:text-sm selection:bg-cyan-500/30 selection:text-cyan-200">
                    {item.url}
                  </p>
                </div>
              </div>
            </TabsContent>
          ))}
        </Tabs>
      </CardContent>
    </Card>
  )
}
