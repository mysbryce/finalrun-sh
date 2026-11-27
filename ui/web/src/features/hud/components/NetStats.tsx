export function NetStats({ fps, ping }: { fps: number; ping: number }) {
  return (
    <div className="absolute left-6 top-3 text-[11px] font-semibold tracking-wider text-white/80">
      FPS {fps} · PING {ping} MS
    </div>
  )
}
